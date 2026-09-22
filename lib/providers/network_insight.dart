import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/network_insight/dns.dart';
import 'package:fl_clash/features/network_insight/identity.dart';
import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/http.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/features/network_insight/service_check/runner.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'action.dart';
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

  /// Node tests: a loopback proxy pinned to one node (core/probe.go), an
  /// HTTP session through it, and the core's own delay test for the node.
  final Future<int> Function(String proxyName) startProbe;
  final Future<void> Function() stopProbe;
  final ServiceHttp Function(int port) probeHttp;
  final Future<int?> Function(String proxyName) nodeDelay;

  /// The DNS configuration the core runs with; null without a profile.
  final Future<DnsInsight?> Function() readDns;

  const NetworkInsightSources({
    required this.lookupPublicIp,
    required this.httpFactory,
    required this.listInterfaces,
    required this.connectionKinds,
    required this.services,
    required this.startProbe,
    required this.stopProbe,
    required this.probeHttp,
    required this.nodeDelay,
    required this.readDns,
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
    // Closures, not tear-offs: reading this provider must not construct
    // the core controller (and start its IPC server) as a side effect.
    startProbe: (proxyName) => coreController.startProbeListener(proxyName),
    stopProbe: () => coreController.stopProbeListener(),
    probeHttp: (port) =>
        ProxiedServiceHttp(findProxy: (_) => 'PROXY $localhost:$port'),
    nodeDelay: (proxyName) async {
      final delay = await coreController.getDelay(
        ref.read(realTestUrlProvider()),
        proxyName,
      );
      final value = delay.value;
      return value != null && value > 0 ? value : null;
    },
    readDns: () async {
      final section = await ref
          .read(setupActionProvider.notifier)
          .currentDnsSection();
      if (section == null) return null;
      return DnsInsight.fromSection(section.dns, section.source);
    },
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

    final (publicIp, ipv4, ipv6, interfaces, kinds, dns) = await (
      guarded(sources.lookupPublicIp),
      probe(IpFamily.ipv4),
      probe(IpFamily.ipv6),
      guarded(() => sources.listInterfaces(tunDeviceName)),
      guarded(sources.connectionKinds),
      guarded(sources.readDns),
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
        dns: dns,
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

/// What one node can do: its exit, latency and service results, measured
/// through a probe pinned to that node — the user's active route and
/// group selections are never changed (brief §48-51).
@immutable
class NodeReport {
  final String proxyName;
  final bool isRunning;

  /// Why the test couldn't run (e.g. the core isn't connected).
  final String? error;
  final int? delayMs;
  final IpFamilyProbe? ipv4;
  final IpFamilyProbe? ipv6;
  final List<ServiceCheckResult> services;
  final DateTime? checkedAt;

  const NodeReport({
    required this.proxyName,
    this.isRunning = false,
    this.error,
    this.delayMs,
    this.ipv4,
    this.ipv6,
    this.services = const [],
    this.checkedAt,
  });

  NodeReport copyWith({
    bool? isRunning,
    int? delayMs,
    IpFamilyProbe? ipv4,
    IpFamilyProbe? ipv6,
    List<ServiceCheckResult>? services,
    DateTime? checkedAt,
  }) {
    return NodeReport(
      proxyName: proxyName,
      isRunning: isRunning ?? this.isRunning,
      error: error,
      delayMs: delayMs ?? this.delayMs,
      ipv4: ipv4 ?? this.ipv4,
      ipv6: ipv6 ?? this.ipv6,
      services: services ?? this.services,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  int get availableCount => services.where((r) => r.status.isAvailable).length;
}

/// A finished report older than this is shown as stale rather than reused.
const nodeReportTtl = Duration(minutes: 20);

class NodeTestNotConnected implements Exception {
  const NodeTestNotConnected();
}

@Riverpod(keepAlive: true)
class NodeDiagnostics extends _$NodeDiagnostics {
  ServiceCheckCancellation? _cancellation;
  int _generation = 0;

  @override
  Map<String, NodeReport> build() {
    ref.onDispose(() => _cancellation?.cancel());
    return const {};
  }

  void _put(NodeReport report) {
    state = {...state, report.proxyName: report};
  }

  /// Tests [proxyName] end to end. Only one node test runs at a time (the
  /// core keeps a single probe listener); starting another cancels it.
  Future<void> test(String proxyName) async {
    cancel();
    final generation = ++_generation;
    final cancellation = ServiceCheckCancellation();
    _cancellation = cancellation;
    final sources = ref.read(networkInsightSourcesProvider);

    if (!ref.read(isStartProvider)) {
      _put(NodeReport(proxyName: proxyName, error: 'notConnected'));
      return;
    }
    var report = NodeReport(
      proxyName: proxyName,
      isRunning: true,
      services: [
        for (final definition in sources.services)
          ServiceCheckResult(
            serviceId: definition.id,
            serviceName: definition.name,
            category: definition.category,
            status: ServiceCheckStatus.checking,
          ),
      ],
    );
    _put(report);

    bool isCurrent() =>
        ref.mounted && generation == _generation && !cancellation.isCancelled;

    final int port;
    try {
      port = await sources.startProbe(proxyName);
    } catch (e) {
      if (isCurrent()) {
        _put(NodeReport(proxyName: proxyName, error: '$e'));
      }
      return;
    }

    try {
      Future<IpFamilyProbe> probe(IpFamily family) async {
        final http = sources.probeHttp(port);
        cancellation.onCancel(http.close);
        try {
          return await probeIpFamily(http, family);
        } finally {
          http.close();
        }
      }

      final (delay, ipv4, ipv6) = await (
        sources.nodeDelay(proxyName).catchError((_) => null),
        probe(IpFamily.ipv4),
        probe(IpFamily.ipv6),
      ).wait;
      if (!isCurrent()) {
        return;
      }
      report = report.copyWith(delayMs: delay, ipv4: ipv4, ipv6: ipv6);
      _put(report);

      final runner = ServiceCheckRunner(
        httpFactory: () => sources.probeHttp(port),
      );
      await for (final result in runner.checkAll(
        sources.services,
        cancellation: cancellation,
      )) {
        if (!isCurrent()) {
          return;
        }
        report = report.copyWith(
          services: [
            for (final existing in report.services)
              existing.serviceId == result.serviceId ? result : existing,
          ],
        );
        _put(report);
      }
      if (isCurrent()) {
        _put(report.copyWith(isRunning: false, checkedAt: DateTime.now()));
      }
    } finally {
      await sources.stopProbe();
    }
  }

  /// Stops a running node test; a partial report is dropped.
  void cancel() {
    _cancellation?.cancel();
    _cancellation = null;
    final running = state.values.where((report) => report.isRunning);
    if (running.isNotEmpty) {
      state = {
        for (final entry in state.entries)
          if (!entry.value.isRunning) entry.key: entry.value,
      };
    }
  }
}
