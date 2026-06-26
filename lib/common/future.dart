import 'dart:async';
import 'dart:ui';

import 'package:fl_clash/common/common.dart';

extension FutureExt<T> on Future<T> {
  Future<T> withTimeout({
    Duration? timeout,
    String? tag,
    VoidCallback? onLast,
    FutureOr<T> Function()? onTimeout,
  }) {
    final realTimeout = timeout ?? const Duration(minutes: 3);
    bool timedOut = false;
    Timer? cleanupTimer;
    if (onLast != null) {
      cleanupTimer = Timer(realTimeout + commonDuration, onLast);
    }
    return this.timeout(
      realTimeout,
      onTimeout: () async {
        timedOut = true;
        if (onTimeout != null) {
          return onTimeout();
        } else {
          throw TimeoutException('${tag ?? runtimeType} timeout');
        }
      },
    ).whenComplete(() {
      // Only cancel the cleanup timer on normal completion.
      // On timeout (timedOut == true), let it fire so onLast runs cleanup.
      if (!timedOut) {
        cleanupTimer?.cancel();
      }
    });
  }
}

extension CompleterExt<T> on Completer<T> {
  void safeCompleter(T value) {
    if (isCompleted) {
      return;
    }
    complete(value);
  }
}
