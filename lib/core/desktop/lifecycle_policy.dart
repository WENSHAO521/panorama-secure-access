import 'package:rust_api/lifecycle.dart' as native;
import 'package:rust_api/lifecycle.dart'
    show
        DisconnectReaction,
        LifecycleAchievement,
        LifecycleOutcome,
        LifecycleTarget,
        ReconcilePlan,
        TransportEventKind,
        TransportPhase;
import 'package:rust_api/rust_api.dart' show isRustLibInitialized;

export 'package:rust_api/lifecycle.dart'
    show
        DisconnectReaction,
        LifecycleAchievement,
        LifecycleOutcome,
        LifecycleTarget,
        ReconcilePlan,
        TransportEventKind,
        TransportPhase;

/// The decisions [DesktopCoreLifecycle] takes, apart from the waiting, the
/// process and the socket it does them with. Rust (`lifecycle` in rust_api)
/// decides once the library is loaded; [DartLifecyclePolicy] is the reference
/// and the fallback.
abstract interface class LifecyclePolicy {
  bool satisfies(LifecycleAchievement achievement, LifecycleTarget target);

  /// Null for a command newer than the settled intent, which stays pending.
  LifecycleOutcome? commandOutcome(
    int revision,
    LifecycleTarget target,
    int settledRevision,
    LifecycleTarget settledTarget,
  );

  ReconcilePlan planReconcile(
    LifecycleTarget target, {
    required bool hasSession,
    required bool sessionRunning,
    required bool terminalRequested,
  });

  bool unconfirmedLeaseMayFail(LifecycleTarget target);

  bool transportNeedsReplacement(
    TransportPhase phase, {
    required bool hasSession,
  });

  bool transportUsable(TransportPhase phase);

  DisconnectReaction disconnectReaction(
    TransportEventKind event, {
    required bool sessionRunning,
    required bool sameGeneration,
  });
}

LifecyclePolicy get lifecyclePolicy => isRustLibInitialized
    ? const RustLifecyclePolicy()
    : const DartLifecyclePolicy();

bool wantsRunning(LifecycleTarget target) =>
    target == LifecycleTarget.running || target == LifecycleTarget.restarted;

final class DartLifecyclePolicy implements LifecyclePolicy {
  const DartLifecyclePolicy();

  @override
  bool satisfies(LifecycleAchievement achievement, LifecycleTarget target) {
    return switch (target) {
      LifecycleTarget.running =>
        achievement == LifecycleAchievement.runningExisting ||
            achievement == LifecycleAchievement.runningFresh,
      LifecycleTarget.restarted =>
        achievement == LifecycleAchievement.runningFresh,
      LifecycleTarget.stopped => achievement == LifecycleAchievement.idle,
      LifecycleTarget.closed => achievement == LifecycleAchievement.closed,
    };
  }

  @override
  LifecycleOutcome? commandOutcome(
    int revision,
    LifecycleTarget target,
    int settledRevision,
    LifecycleTarget settledTarget,
  ) {
    if (revision > settledRevision) {
      return null;
    }
    if (revision == settledRevision) {
      return LifecycleOutcome.applied;
    }
    return target == settledTarget ||
            (wantsRunning(target) && wantsRunning(settledTarget))
        ? LifecycleOutcome.coalesced
        : LifecycleOutcome.superseded;
  }

  @override
  ReconcilePlan planReconcile(
    LifecycleTarget target, {
    required bool hasSession,
    required bool sessionRunning,
    required bool terminalRequested,
  }) {
    final keepExisting =
        target == LifecycleTarget.running && hasSession && sessionRunning;
    final (allowUnconfirmedExit, start, close) = switch (target) {
      LifecycleTarget.running ||
      LifecycleTarget.restarted => (terminalRequested, true, false),
      LifecycleTarget.stopped => (false, false, false),
      LifecycleTarget.closed => (true, false, true),
    };
    return ReconcilePlan(
      keepExisting: keepExisting,
      stopSession: hasSession && !keepExisting,
      allowUnconfirmedExit: allowUnconfirmedExit,
      start: start && !keepExisting,
      close: close,
    );
  }

  @override
  bool unconfirmedLeaseMayFail(LifecycleTarget target) =>
      target == LifecycleTarget.closed;

  @override
  bool transportNeedsReplacement(
    TransportPhase phase, {
    required bool hasSession,
  }) {
    return phase == TransportPhase.failed ||
        phase == TransportPhase.closed ||
        (phase == TransportPhase.connected && !hasSession);
  }

  @override
  bool transportUsable(TransportPhase phase) =>
      phase == TransportPhase.ready || phase == TransportPhase.connected;

  @override
  DisconnectReaction disconnectReaction(
    TransportEventKind event, {
    required bool sessionRunning,
    required bool sameGeneration,
  }) {
    if (!sessionRunning) {
      return DisconnectReaction.ignore;
    }
    return switch (event) {
      TransportEventKind.disconnected when sameGeneration =>
        DisconnectReaction.unexpectedDisconnect,
      TransportEventKind.failed => DisconnectReaction.transportFailed,
      _ => DisconnectReaction.ignore,
    };
  }
}

final class RustLifecyclePolicy implements LifecyclePolicy {
  const RustLifecyclePolicy();

  @override
  bool satisfies(LifecycleAchievement achievement, LifecycleTarget target) =>
      native.lifecycleSatisfies(achievement: achievement, target: target);

  @override
  LifecycleOutcome? commandOutcome(
    int revision,
    LifecycleTarget target,
    int settledRevision,
    LifecycleTarget settledTarget,
  ) => native.lifecycleCommandOutcome(
    revision: revision,
    target: target,
    settledRevision: settledRevision,
    settledTarget: settledTarget,
  );

  @override
  ReconcilePlan planReconcile(
    LifecycleTarget target, {
    required bool hasSession,
    required bool sessionRunning,
    required bool terminalRequested,
  }) => native.lifecyclePlanReconcile(
    target: target,
    hasSession: hasSession,
    sessionRunning: sessionRunning,
    terminalRequested: terminalRequested,
  );

  @override
  bool unconfirmedLeaseMayFail(LifecycleTarget target) =>
      native.lifecycleUnconfirmedLeaseMayFail(target: target);

  @override
  bool transportNeedsReplacement(
    TransportPhase phase, {
    required bool hasSession,
  }) => native.lifecycleTransportNeedsReplacement(
    phase: phase,
    hasSession: hasSession,
  );

  @override
  bool transportUsable(TransportPhase phase) =>
      native.lifecycleTransportUsable(phase: phase);

  @override
  DisconnectReaction disconnectReaction(
    TransportEventKind event, {
    required bool sessionRunning,
    required bool sameGeneration,
  }) => native.lifecycleDisconnectReaction(
    event: event,
    sessionRunning: sessionRunning,
    sameGeneration: sameGeneration,
  );
}
