import 'dart:async';

import 'package:fl_clash/features/network_insight/identity.dart';
import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/network_insight/fake_service_http.dart';

class _Harness {
  final gates = <String, Completer<ServiceCheckOutcome>>{};
  var routeKey = 'profile-1|rule|Proxy=JP-01';
  var exitIPv4 = '203.0.113.7';
  var lookups = 0;

  ServiceDefinition gated(String id) => ServiceDefinition(
    id: id,
    name: id.toUpperCase(),
    category: ServiceCategory.ai,
    run: (_) => (gates[id] = Completer()).future,
  );

  late final services = [gated('a'), gated('b')];

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        networkInsightSourcesProvider.overrideWithValue(
          NetworkInsightSources(
            lookupPublicIp: () async {
              lookups++;
              return IpInfo(ip: exitIPv4, countryCode: 'JP', asn: 2516);
            },
            httpFactory: () => FakeServiceHttp({
              'https://1.1.1.1/': (_) => respond('ip=$exitIPv4\nloc=JP\n'),
              'https://[2606:4700:4700::1111]/': failWith(),
            }),
            listInterfaces: (_) async => const [
              LocalInterface(name: 'en0', addresses: ['192.168.1.10']),
            ],
            connectionKinds: () async => {ConnectionKind.wifi},
            services: services,
          ),
        ),
        serviceRouteKeyProvider.overrideWith(
          (ref) => ref.watch(_routeKeyProvider),
        ),
        _routeKeyProvider.overrideWith((ref) => routeKey),
      ],
    );
    return container;
  }
}

final _routeKeyProvider = Provider<String>((ref) => '');

void main() {
  group('NetworkInsightIdentity', () {
    test(
      'refresh assembles lookup, both probes, interfaces and link',
      () async {
        final harness = _Harness();
        final container = harness.container();
        addTearDown(container.dispose);

        await container.read(networkInsightIdentityProvider.notifier).refresh();
        final state = container.read(networkInsightIdentityProvider);
        final identity = state.identity!;

        expect(state.isLoading, isFalse);
        expect(identity.publicIp?.asn, 2516);
        expect(identity.publicIPv4, '203.0.113.7');
        expect(identity.ipv6?.status, IpFamilyStatus.unavailable);
        expect(identity.localIPv4, ['192.168.1.10']);
        expect(identity.connectionKinds, {ConnectionKind.wifi});
      },
    );

    test('nothing is fetched until refresh is called', () async {
      final harness = _Harness();
      final container = harness.container();
      addTearDown(container.dispose);

      container.read(networkInsightIdentityProvider);
      await pumpEventQueue();
      expect(harness.lookups, 0);
    });
  });

  group('ServiceAvailability', () {
    test('starts pending and streams each result into state', () async {
      final harness = _Harness();
      final container = harness.container();
      addTearDown(container.dispose);
      final notifier = container.read(serviceAvailabilityProvider.notifier);

      expect(
        container
            .read(serviceAvailabilityProvider)
            .results
            .map((r) => r.status),
        [ServiceCheckStatus.pending, ServiceCheckStatus.pending],
      );

      final done = notifier.checkAll();
      await pumpEventQueue();
      var state = container.read(serviceAvailabilityProvider);
      expect(state.isChecking, isTrue);
      expect(state.results.map((r) => r.status), [
        ServiceCheckStatus.checking,
        ServiceCheckStatus.checking,
      ]);

      harness.gates['b']!.complete(
        const ServiceCheckOutcome(ServiceCheckStatus.available),
      );
      await pumpEventQueue();
      state = container.read(serviceAvailabilityProvider);
      expect(state.byId('b')!.status, ServiceCheckStatus.available);
      expect(state.byId('a')!.status, ServiceCheckStatus.checking);

      harness.gates['a']!.complete(
        const ServiceCheckOutcome(ServiceCheckStatus.blocked),
      );
      await done;
      state = container.read(serviceAvailabilityProvider);
      expect(state.isChecking, isFalse);
      expect(state.availableCount, 1);
      expect(state.checkedCount, 2);
    });

    test('results are remembered per route', () async {
      final harness = _Harness();
      final container = harness.container();
      addTearDown(container.dispose);
      final notifier = container.read(serviceAvailabilityProvider.notifier);

      final done = notifier.checkAll();
      await pumpEventQueue();
      for (final gate in harness.gates.values) {
        gate.complete(const ServiceCheckOutcome(ServiceCheckStatus.available));
      }
      await done;

      // Switching node: nothing known for the new route yet.
      harness.routeKey = 'profile-1|rule|Proxy=US-01';
      container.invalidate(_routeKeyProvider);
      await pumpEventQueue();
      expect(
        container
            .read(serviceAvailabilityProvider)
            .results
            .every((r) => r.status == ServiceCheckStatus.pending),
        isTrue,
      );

      // Switching back shows the cached results without re-checking.
      harness.gates.clear();
      harness.routeKey = 'profile-1|rule|Proxy=JP-01';
      container.invalidate(_routeKeyProvider);
      await pumpEventQueue();
      expect(
        container
            .read(serviceAvailabilityProvider)
            .results
            .every((r) => r.status == ServiceCheckStatus.available),
        isTrue,
      );
      expect(harness.gates, isEmpty);
    });

    test('a new exit IP on the same route drops cached verdicts', () async {
      final harness = _Harness();
      final container = harness.container();
      addTearDown(container.dispose);
      final identity = container.read(networkInsightIdentityProvider.notifier);
      final notifier = container.read(serviceAvailabilityProvider.notifier);

      await identity.refresh();
      final done = notifier.checkAll();
      await pumpEventQueue();
      for (final gate in harness.gates.values) {
        gate.complete(const ServiceCheckOutcome(ServiceCheckStatus.available));
      }
      await done;

      harness.exitIPv4 = '198.51.100.9';
      await identity.refresh();
      await pumpEventQueue();

      expect(
        container
            .read(serviceAvailabilityProvider)
            .results
            .every((r) => r.status == ServiceCheckStatus.pending),
        isTrue,
      );
    });

    test('cancel returns unfinished rows to their previous state', () async {
      final harness = _Harness();
      final container = harness.container();
      addTearDown(container.dispose);
      final notifier = container.read(serviceAvailabilityProvider.notifier);

      final done = notifier.checkAll();
      await pumpEventQueue();
      harness.gates['a']!.complete(
        const ServiceCheckOutcome(ServiceCheckStatus.available),
      );
      await pumpEventQueue();
      notifier.cancel();
      await done;

      final state = container.read(serviceAvailabilityProvider);
      expect(state.isChecking, isFalse);
      expect(state.byId('a')!.status, ServiceCheckStatus.available);
      expect(state.byId('b')!.status, ServiceCheckStatus.pending);
    });

    test('checking one service leaves the others alone', () async {
      final harness = _Harness();
      final container = harness.container();
      addTearDown(container.dispose);
      final notifier = container.read(serviceAvailabilityProvider.notifier);

      final done = notifier.check('b');
      await pumpEventQueue();
      final state = container.read(serviceAvailabilityProvider);
      expect(state.byId('a')!.status, ServiceCheckStatus.pending);
      expect(state.byId('b')!.status, ServiceCheckStatus.checking);
      expect(harness.gates.keys, ['b']);

      harness.gates['b']!.complete(
        const ServiceCheckOutcome(
          ServiceCheckStatus.limited,
          message: 'Originals only',
        ),
      );
      await done;
      expect(
        container.read(serviceAvailabilityProvider).byId('b')!.message,
        'Originals only',
      );
    });
  });
}
