import 'dart:async';
import 'dart:collection';

import 'checkers.dart';
import 'http.dart';
import 'models.dart';

/// Same cap as the reference implementation: never fire every service at
/// once from the user's exit IP.
const maxConcurrentServiceChecks = 4;

typedef ServiceHttpFactory = ServiceHttp Function();

/// Cancels an in-progress [ServiceCheckRunner.checkAll]. Checks still
/// queued never start, running ones have their connections aborted, and
/// the result stream closes without emitting them.
class ServiceCheckCancellation {
  bool _cancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void _onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }
}

class ServiceCheckRunner {
  final ServiceHttpFactory httpFactory;
  final int maxConcurrent;
  final DateTime Function() _now;

  ServiceCheckRunner({
    required this.httpFactory,
    this.maxConcurrent = maxConcurrentServiceChecks,
    DateTime Function()? now,
  }) : assert(maxConcurrent > 0),
       _now = now ?? DateTime.now;

  /// Runs one service with its own HTTP session (cookies are per service)
  /// and turns every failure mode into a result instead of an exception.
  Future<ServiceCheckResult> check(
    ServiceDefinition definition, {
    ServiceCheckCancellation? cancellation,
  }) async {
    final http = httpFactory();
    cancellation?._onCancel(http.close);
    final stopwatch = Stopwatch()..start();
    ServiceCheckOutcome outcome;
    try {
      outcome = await definition
          .run(http)
          .timeout(
            definition.timeout,
            onTimeout: () {
              http.close();
              return const ServiceCheckOutcome(
                ServiceCheckStatus.timeout,
                errorType: ServiceCheckErrorType.timeout,
              );
            },
          );
    } on ServiceHttpException catch (e) {
      outcome = ServiceCheckOutcome(
        ServiceCheckStatus.networkError,
        message: e.type == ServiceCheckErrorType.tls
            ? 'TLS: ${e.message}'
            : e.message,
        errorType: e.type,
      );
    } on FormatException catch (e) {
      outcome = ServiceCheckOutcome.parseError(e.message);
    } catch (e) {
      outcome = ServiceCheckOutcome(
        ServiceCheckStatus.unknown,
        message: e.toString(),
      );
    } finally {
      stopwatch.stop();
      http.close();
    }
    if (cancellation?.isCancelled == true) {
      outcome = const ServiceCheckOutcome(
        ServiceCheckStatus.unknown,
        errorType: ServiceCheckErrorType.cancelled,
      );
    }
    return ServiceCheckResult(
      serviceId: definition.id,
      serviceName: definition.name,
      category: definition.category,
      status: outcome.status,
      regionCode: outcome.regionCode,
      message: outcome.message,
      errorType: outcome.errorType,
      checkedAt: _now(),
      latency: stopwatch.elapsed,
    );
  }

  /// Emits each service's result as soon as it finishes, running at most
  /// [maxConcurrent] at a time, in [definitions] order of starting.
  Stream<ServiceCheckResult> checkAll(
    Iterable<ServiceDefinition> definitions, {
    ServiceCheckCancellation? cancellation,
  }) {
    final queue = Queue.of(definitions);
    final controller = StreamController<ServiceCheckResult>();
    var running = 0;

    void closeIfDone() {
      if (running == 0 &&
          (queue.isEmpty || cancellation?.isCancelled == true)) {
        if (!controller.isClosed) {
          controller.close();
        }
      }
    }

    void startNext() {
      while (running < maxConcurrent &&
          queue.isNotEmpty &&
          cancellation?.isCancelled != true) {
        final definition = queue.removeFirst();
        running++;
        check(definition, cancellation: cancellation).then((result) {
          running--;
          if (cancellation?.isCancelled != true && !controller.isClosed) {
            controller.add(result);
          }
          startNext();
          closeIfDone();
        });
      }
      closeIfDone();
    }

    cancellation?._onCancel(() {
      queue.clear();
      if (!controller.isClosed) {
        controller.close();
      }
    });
    controller.onListen = startNext;
    return controller.stream;
  }
}

/// A cached result is only reused for the same route (profile + node),
/// within [ttl], and never across a change of exit IP.
class ServiceCheckCache {
  final Duration ttl;
  final DateTime Function() _now;
  final _entries = <String, _CacheEntry>{};

  ServiceCheckCache({
    this.ttl = const Duration(minutes: 20),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  void put(ServiceCheckResult result, {required String routeKey}) {
    if (!result.status.isDone ||
        result.errorType == ServiceCheckErrorType.cancelled) {
      return;
    }
    _entries['$routeKey|${result.serviceId}'] = _CacheEntry(result, _now());
  }

  ServiceCheckResult? get(String serviceId, {required String routeKey}) {
    final key = '$routeKey|$serviceId';
    final entry = _entries[key];
    if (entry == null) {
      return null;
    }
    if (_now().difference(entry.storedAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    return entry.result;
  }

  /// Drops everything cached for [routeKey], e.g. when its exit IP changes.
  void invalidateRoute(String routeKey) {
    _entries.removeWhere((key, _) => key.startsWith('$routeKey|'));
  }

  void clear() => _entries.clear();
}

class _CacheEntry {
  final ServiceCheckResult result;
  final DateTime storedAt;

  const _CacheEntry(this.result, this.storedAt);
}
