import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/network_insight/identity.dart';
import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/http.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/features/network_insight/service_check/runner.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'config.dart';
import 'state.dart';

part 'generated/network_insight.g.dart';

/// Everything Network Insight reads from the outside world, behind one
/// provider so tests can substitute all of it.
class NetworkInsightSources {
  final Future<IpInfo?> Function() lookupPublicIp;
  final ServiceHttpFactory httpFactory;
  final Future<List<LocalInterface>> Function(String tunDeviceName)
  listInterfaces;
  final Future<Set<ConnectionKind>> Function() connectionKinds;
  final List<ServiceDefinition> services;

  const NetworkInsightSources({
    required this.lookupPublicIp,
    required this.httpFactory,
    required this.listInterfaces,
    required this.connectionKinds,
    required this.services,
  });
}

Future<Set<ConnectionKind>> _systemConnectionKinds() async {
  final results = await Connectivity().checkConnectivity();
  return {
    for (final result in results)
      switch (result) {
        ConnectivityResult.wifi => ConnectionKind.wifi,
        ConnectivityResult.ethernet => ConnectionKind.ethernet,
        ConnectivityResult.mobile => ConnectionKind.mobile,
        ConnectivityResult.vpn => ConnectionKind.vpn,
        ConnectivityResult.none => ConnectionKind.none,
        _ => ConnectionKind.other,
      },
  };
}

@riverpod
NetworkInsightSources networkInsightSources(Ref ref) {
  return NetworkInsightSources(
    lookupPublicIp: () async => (await request.checkIp(detailed: true)).data,
    httpFactory: () =>
        ProxiedServiceHttp(findProxy: FlClashHttpOverrides.handleFindProxy),
    listInterfaces: (tunDeviceName) =>
        listLocalInterfaces(tunDeviceName: tunDeviceName),
    connectionKinds: _systemConnectionKinds,
    services: serviceDefinitions,
  );
}

/// The route service results belong to: profile, outbound mode and every
/// group selection. Any change means cached results no longer apply.
@riverpod
String serviceRouteKey(Ref ref) {
  final profileId = ref.watch(currentProfileIdProvider);
  final mode = ref.watch(
    patchClashConfigProvider.select((state) => state.mode),
  );
  final selected = ref.watch(selectedMapProvider);
  final entries = selected.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return [
    '${profileId ?? '-'}',
    mode.name,
    for (final entry in entries) '${entry.key}=${entry.value}',
  ].join('\u0000');
}

@immutable
class NetworkIdentityState {
  final NetworkIdentity? identity;
  final bool isLoading;

  const NetworkIdentityState({this.identity, this.isLoading = false});
}

@Riverpod(keepAlive: true)
class NetworkInsightIdentity extends _$NetworkInsightIdentity {
  int _version = 0;

  @override
  NetworkIdentityState build() => const NetworkIdentityState();

  /// Runs the IP lookup, both family probes, and the local interface and
  /// connectivity reads concurrently. Only triggered by the user or by a
  /// network event while the page is visible — never on a timer.
  Future<void> refresh() async {
    final version = ++_version;
    state = NetworkIdentityState(identity: state.identity, isLoading: true);
    final sources = ref.read(networkInsightSourcesProvider);
    final tunDeviceName = ref.read(
      patchClashConfigProvider.select((state) => state.tun.device),
    );

    Future<IpFamilyProbe> probe(IpFamily family) async {
      final http = sources.httpFactory();
      try {
        return await probeIpFamily(http, family);
      } finally {
        http.close();
      }
    }

    Future<T?> guarded<T>(Future<T> Function() task) async {
      try {
        return await task();
      } catch (e) {
        commonPrint.log('networkInsight: $e', logLevel: LogLevel.warning);
        return null;
      }
    }

    final (publicIp, ipv4, ipv6, interfaces, kinds) = await (
      guarded(sources.lookupPublicIp),
      probe(IpFamily.ipv4),
      probe(IpFamily.ipv6),
      guarded(() => sources.listInterfaces(tunDeviceName)),
      guarded(sources.connectionKinds),
    ).wait;

    if (!ref.mounted || version != _version) {
      return;
    }
    state = NetworkIdentityState(
      identity: NetworkIdentity(
        checkedAt: DateTime.now(),
        publicIp: publicIp,
        ipv4: ipv4,
        ipv6: ipv6,
        interfaces: interfaces ?? const [],
        connectionKinds: kinds ?? const {},
      ),
    );
  }
}

@immutable
class ServiceAvailabilityState {
  /// One entry per service, in definition order.
  final List<ServiceCheckResult> results;
  final bool isChecking;

  const ServiceAvailabilityState({
    required this.results,
    this.isChecking = false,
  });

  ServiceCheckResult? byId(String id) {
    for (final result in results) {
      if (result.serviceId == id) {
        return result;
      }
    }
    return null;
  }

  int get availableCount => results.where((r) => r.status.isAvailable).length;

  int get checkedCount => results.where((r) => r.status.isDone).length;
}

@Riverpod(keepAlive: true)
class ServiceAvailability extends _$ServiceAvailability {
  final _cache = ServiceCheckCache();
  ServiceCheckCancellation? _cancellation;
  String? _lastExitIp;

  List<ServiceDefinition> get _services =>
      ref.read(networkInsightSourcesProvider).services;

  @override
  ServiceAvailabilityState build() {
    ref.onDispose(() => _cancellation?.cancel());
    ref.listen(serviceRouteKeyProvider, (previous, next) {
      if (previous != next) {
        _cancellation?.cancel();
        state = _cachedState(next);
      }
    });
    // A new exit IP on the same route means the cached verdicts describe
    // a different network position (brief §51).
    ref.listen(
      networkInsightIdentityProvider.select(
        (state) => state.identity?.publicIPv4,
      ),
      (_, exitIp) {
        if (exitIp == null) {
          return;
        }
        if (_lastExitIp != null && _lastExitIp != exitIp) {
          final route = ref.read(serviceRouteKeyProvider);
          _cache.invalidateRoute(route);
          if (!state.isChecking) {
            state = _cachedState(route);
          }
        }
        _lastExitIp = exitIp;
      },
    );
    return _cachedState(ref.read(serviceRouteKeyProvider));
  }

  ServiceCheckResult _pending(ServiceDefinition definition) {
    return ServiceCheckResult(
      serviceId: definition.id,
      serviceName: definition.name,
      category: definition.category,
      status: ServiceCheckStatus.pending,
    );
  }

  ServiceAvailabilityState _cachedState(String route) {
    return ServiceAvailabilityState(
      results: [
        for (final definition in _services)
          _cache.get(definition.id, routeKey: route) ?? _pending(definition),
      ],
    );
  }

  void _put(ServiceCheckResult result, {bool? isChecking}) {
    state = ServiceAvailabilityState(
      results: [
        for (final existing in state.results)
          existing.serviceId == result.serviceId ? result : existing,
      ],
      isChecking: isChecking ?? state.isChecking,
    );
  }

  ServiceCheckRunner _runner() => ServiceCheckRunner(
    httpFactory: ref.read(networkInsightSourcesProvider).httpFactory,
  );

  /// Checks every service, streaming each result into state as it lands.
  Future<void> checkAll() => _run(_services);

  /// Re-checks a single service.
  Future<void> check(String serviceId) {
    final definition = _services.where((d) => d.id == serviceId);
    return _run(definition.toList(), keepOthersChecking: true);
  }

  Future<void> _run(
    List<ServiceDefinition> definitions, {
    bool keepOthersChecking = false,
  }) async {
    if (definitions.isEmpty) {
      return;
    }
    if (!keepOthersChecking) {
      _cancellation?.cancel();
    }
    final cancellation = ServiceCheckCancellation();
    if (!keepOthersChecking) {
      _cancellation = cancellation;
    }
    final route = ref.read(serviceRouteKeyProvider);
    final ids = {for (final d in definitions) d.id};
    state = ServiceAvailabilityState(
      results: [
        for (final result in state.results)
          ids.contains(result.serviceId)
              ? result.copyWith(status: ServiceCheckStatus.checking)
              : result,
      ],
      isChecking: true,
    );
    await for (final result in _runner().checkAll(
      definitions,
      cancellation: cancellation,
    )) {
      if (!ref.mounted || ref.read(serviceRouteKeyProvider) != route) {
        return;
      }
      _cache.put(result, routeKey: route);
      _put(result);
    }
    if (!ref.mounted || cancellation.isCancelled) {
      return;
    }
    final stillChecking = state.results.any(
      (r) => r.status == ServiceCheckStatus.checking,
    );
    state = ServiceAvailabilityState(
      results: state.results,
      isChecking: stillChecking,
    );
  }

  /// Stops a running Check All; unfinished rows go back to their cached
  /// result for this route, or pending.
  void cancel() {
    _cancellation?.cancel();
    _cancellation = null;
    final route = ref.read(serviceRouteKeyProvider);
    final cached = _cachedState(route);
    state = ServiceAvailabilityState(
      results: [
        for (final result in state.results)
          result.status == ServiceCheckStatus.checking
              ? cached.byId(result.serviceId)!
              : result,
      ],
    );
  }
}
