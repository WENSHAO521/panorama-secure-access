import 'dart:async';

import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/http.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/features/network_insight/service_check/runner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_service_http.dart';

/// A service whose check finishes only when the test completes it, so the
/// test controls completion order and can observe concurrency.
class _Gate {
  final completer = Completer<ServiceCheckOutcome>();
  bool started = false;
}

void main() {
  late Map<String, _Gate> gates;
  late int running;
  late int peakRunning;
  late List<FakeServiceHttp> sessions;

  ServiceDefinition gated(String id, {Duration? timeout}) {
    return ServiceDefinition(
      id: id,
      name: id,
      category: ServiceCategory.ai,
      timeout: timeout ?? defaultServiceCheckTimeout,
      run: (_) async {
        final gate = gates.putIfAbsent(id, _Gate.new)..started = true;
        running++;
        if (running > peakRunning) {
          peakRunning = running;
        }
        try {
          return await gate.completer.future;
        } finally {
          running--;
        }
      },
    );
  }

  ServiceCheckRunner runner({int maxConcurrent = maxConcurrentServiceChecks}) {
    return ServiceCheckRunner(
      maxConcurrent: maxConcurrent,
      now: () => DateTime(2026, 9, 22, 12),
      httpFactory: () {
        final http = FakeServiceHttp({});
        sessions.add(http);
        return http;
      },
    );
  }

  setUp(() {
    gates = {};
    running = 0;
    peakRunning = 0;
    sessions = [];
  });

  test('never runs more than four checks at once', () async {
    final definitions = [for (var i = 0; i < 12; i++) gated('s$i')];
    for (final d in definitions) {
      gates[d.id] = _Gate();
    }
    final results = <ServiceCheckResult>[];
    final done = runner().checkAll(definitions).forEach(results.add);

    for (final d in definitions) {
      await pumpEventQueue();
      gates[d.id]!.completer.complete(
        const ServiceCheckOutcome(ServiceCheckStatus.available),
      );
    }
    await done;

    expect(peakRunning, maxConcurrentServiceChecks);
    expect(results, hasLength(12));
  });

  test('streams each result as soon as it completes', () async {
    final definitions = [gated('a'), gated('b'), gated('c')];
    for (final d in definitions) {
      gates[d.id] = _Gate();
    }
    final received = <String>[];
    final subscription = runner()
        .checkAll(definitions)
        .listen((result) => received.add(result.serviceId));

    await pumpEventQueue();
    gates['c']!.completer.complete(
      const ServiceCheckOutcome(ServiceCheckStatus.available),
    );
    await pumpEventQueue();
    expect(received, ['c']);

    gates['a']!.completer.complete(
      const ServiceCheckOutcome(ServiceCheckStatus.blocked),
    );
    await pumpEventQueue();
    expect(received, ['c', 'a']);

    gates['b']!.completer.complete(
      const ServiceCheckOutcome(ServiceCheckStatus.available),
    );
    await pumpEventQueue();
    expect(received, ['c', 'a', 'b']);
    await subscription.cancel();
  });

  test(
    'a check that overruns its timeout reports timeout and aborts',
    () async {
      final definition = gated(
        'slow',
        timeout: const Duration(milliseconds: 20),
      );
      final result = await runner().check(definition);

      expect(result.status, ServiceCheckStatus.timeout);
      expect(result.errorType, ServiceCheckErrorType.timeout);
      expect(sessions.single.closed, isTrue);
    },
  );

  test('transport failures become results, not exceptions', () async {
    final definition = ServiceDefinition(
      id: 'tls',
      name: 'tls',
      category: ServiceCategory.ai,
      run: (_) => throw const ServiceHttpException(
        ServiceCheckErrorType.tls,
        'CERTIFICATE_VERIFY_FAILED',
      ),
    );
    final result = await runner().check(definition);

    expect(result.status, ServiceCheckStatus.networkError);
    expect(result.errorType, ServiceCheckErrorType.tls);
    expect(result.message, contains('CERTIFICATE_VERIFY_FAILED'));
  });

  test('unexpected response shapes become parse errors', () async {
    final definition = ServiceDefinition(
      id: 'bad',
      name: 'bad',
      category: ServiceCategory.ai,
      run: (_) => throw const FormatException('Unexpected character'),
    );
    final result = await runner().check(definition);
    expect(result.status, ServiceCheckStatus.parseError);
  });

  test('results carry id, category, time and latency', () async {
    final definition = ServiceDefinition(
      id: 'x',
      name: 'X',
      category: ServiceCategory.streaming,
      run: (_) async => const ServiceCheckOutcome(
        ServiceCheckStatus.available,
        regionCode: 'JP',
      ),
    );
    final result = await runner().check(definition);

    expect(result.serviceId, 'x');
    expect(result.serviceName, 'X');
    expect(result.category, ServiceCategory.streaming);
    expect(result.regionCode, 'JP');
    expect(result.checkedAt, DateTime(2026, 9, 22, 12));
    expect(result.latency, isNotNull);
  });

  test('each service gets its own HTTP session, closed afterwards', () async {
    final definitions = [
      for (final id in ['a', 'b'])
        ServiceDefinition(
          id: id,
          name: id,
          category: ServiceCategory.ai,
          run: (_) async =>
              const ServiceCheckOutcome(ServiceCheckStatus.available),
        ),
    ];
    await runner().checkAll(definitions).drain<void>();

    expect(sessions, hasLength(2));
    expect(sessions.every((s) => s.closed), isTrue);
  });

  test('cancelling stops queued checks and aborts running ones', () async {
    final definitions = [for (var i = 0; i < 8; i++) gated('s$i')];
    for (final d in definitions) {
      gates[d.id] = _Gate();
    }
    final cancellation = ServiceCheckCancellation();
    final results = <ServiceCheckResult>[];
    final done = runner()
        .checkAll(definitions, cancellation: cancellation)
        .forEach(results.add);

    await pumpEventQueue();
    gates['s0']!.completer.complete(
      const ServiceCheckOutcome(ServiceCheckStatus.available),
    );
    await pumpEventQueue();
    cancellation.cancel();
    await done;

    // s0 finished before the cancel; nothing after it is reported.
    expect(results.map((r) => r.serviceId), ['s0']);
    // Only the first four plus the one that replaced s0 ever started.
    expect(gates.values.where((g) => g.started), hasLength(5));
    expect(sessions.skip(1).every((s) => s.closed), isTrue);
  });

  group('ServiceCheckCache', () {
    late DateTime now;
    late ServiceCheckCache cache;

    ServiceCheckResult result(
      String id, {
      ServiceCheckStatus status = ServiceCheckStatus.available,
      ServiceCheckErrorType? errorType,
    }) => ServiceCheckResult(
      serviceId: id,
      serviceName: id,
      category: ServiceCategory.ai,
      status: status,
      errorType: errorType,
    );

    setUp(() {
      now = DateTime(2026, 9, 22, 12);
      cache = ServiceCheckCache(
        ttl: const Duration(minutes: 20),
        now: () => now,
      );
    });

    test('returns a result for the same route within the TTL', () {
      cache.put(result('netflix'), routeKey: 'p1/JP-01');
      now = now.add(const Duration(minutes: 19));
      expect(cache.get('netflix', routeKey: 'p1/JP-01'), isNotNull);
    });

    test('expires after the TTL', () {
      cache.put(result('netflix'), routeKey: 'p1/JP-01');
      now = now.add(const Duration(minutes: 21));
      expect(cache.get('netflix', routeKey: 'p1/JP-01'), isNull);
    });

    test('never answers for a different node or profile', () {
      cache.put(result('netflix'), routeKey: 'p1/JP-01');
      expect(cache.get('netflix', routeKey: 'p1/US-01'), isNull);
      expect(cache.get('netflix', routeKey: 'p2/JP-01'), isNull);
    });

    test('invalidating a route drops only that route', () {
      cache
        ..put(result('netflix'), routeKey: 'p1/JP-01')
        ..put(result('netflix'), routeKey: 'p1/US-01')
        ..invalidateRoute('p1/JP-01');
      expect(cache.get('netflix', routeKey: 'p1/JP-01'), isNull);
      expect(cache.get('netflix', routeKey: 'p1/US-01'), isNotNull);
    });

    test('in-progress and cancelled results are not cached', () {
      cache
        ..put(result('a', status: ServiceCheckStatus.checking), routeKey: 'r')
        ..put(
          result(
            'b',
            status: ServiceCheckStatus.unknown,
            errorType: ServiceCheckErrorType.cancelled,
          ),
          routeKey: 'r',
        );
      expect(cache.get('a', routeKey: 'r'), isNull);
      expect(cache.get('b', routeKey: 'r'), isNull);
    });
  });
}
