import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'action.dart';
import 'app.dart';
import 'config.dart';
import 'state.dart';

part 'generated/connection.g.dart';

extension ConnectionPhaseExt on ConnectionPhase {
  bool get isPending =>
      this == ConnectionPhase.connecting ||
      this == ConnectionPhase.disconnecting;
}

/// How long a requested connect/disconnect shows as pending before the UI
/// falls back to what the core reports.
const connectionPendingTimeout = Duration(seconds: 20);

ConnectionPhase connectionPhaseOf({
  required bool isStart,
  required bool suspend,
  required bool? requested,
  required bool coreDown,
}) {
  if (coreDown) return ConnectionPhase.error;
  if (requested != null && requested != isStart) {
    return requested
        ? ConnectionPhase.connecting
        : ConnectionPhase.disconnecting;
  }
  if (isStart && suspend) return ConnectionPhase.suspended;
  return isStart ? ConnectionPhase.connected : ConnectionPhase.notConnected;
}

/// The state the user asked for and the core hasn't reached yet; null when
/// nothing is pending. Every entry point (Home, tray, tile, hotkey) goes
/// through [request], so all of them show the same pending state.
@Riverpod(keepAlive: true)
class ConnectionRequest extends _$ConnectionRequest {
  Timer? _timeout;

  @override
  bool? build() {
    ref.listen(isStartProvider, (_, isStart) {
      if (state == isStart) _clear();
    });
    ref.onDispose(() => _timeout?.cancel());
    return null;
  }

  void request(bool connect) {
    state = connect;
    _timeout?.cancel();
    _timeout = Timer(connectionPendingTimeout, _clear);
    debouncer.call(FunctionTag.updateStatus, () {
      ref
          .read(setupActionProvider.notifier)
          .updateStatus(connect, isInit: !ref.read(initProvider));
    }, duration: commonDuration);
  }

  void toggle() => request(!ref.read(isStartProvider));

  void _clear() {
    _timeout?.cancel();
    _timeout = null;
    if (state != null) state = null;
  }
}

@riverpod
ConnectionPhase connectionPhase(Ref ref) {
  final coreDown =
      ref.watch(initProvider) &&
      ref.watch(coreStatusProvider) == CoreStatus.disconnected;
  return connectionPhaseOf(
    isStart: ref.watch(isStartProvider),
    suspend: ref.watch(suspendProvider),
    requested: ref.watch(connectionRequestProvider),
    coreDown: coreDown,
  );
}

/// The node traffic actually leaves through for the main group: GLOBAL in
/// global mode, the first visible group in rule mode, following nested
/// groups down to a leaf. Null in direct mode or before groups load. Shared
/// by Home and the tray (§84).
@riverpod
({String group, String node, String? testUrl})? currentRoute(Ref ref) {
  final mode = ref.watch(
    patchClashConfigProvider.select((state) => state.mode),
  );
  final groups = ref.watch(groupsProvider);
  final selectedMap = ref.watch(selectedMapProvider);
  final Group? main = switch (mode) {
    Mode.direct => null,
    Mode.global => groups.getGroup(GroupName.GLOBAL.name),
    Mode.rule =>
      groups
          .where((group) => group.hidden == false)
          .where((group) => group.name != GroupName.GLOBAL.name)
          .firstOrNull,
  };
  if (main == null) {
    return null;
  }
  final resolved = computeRealSelectedProxyState(
    main.name,
    groups: groups,
    selectedMap: selectedMap,
  );
  if (resolved.proxyName.isEmpty || resolved.proxyName == main.name) {
    return null;
  }
  return (
    group: main.name,
    node: resolved.proxyName,
    testUrl: resolved.testUrl,
  );
}
