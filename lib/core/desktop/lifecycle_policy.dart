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

export 'package:rust_api/lifecycle.dart'
    show
        DisconnectReaction,
        LifecycleAchievement,
        LifecycleOutcome,
        LifecycleTarget,
        ReconcilePlan,
        TransportEventKind,
        TransportPhase;

bool wantsRunning(LifecycleTarget target) =>
    target == LifecycleTarget.running || target == LifecycleTarget.restarted;

/// The decisions [DesktopCoreLifecycle] takes, apart from the waiting, the
/// process and the socket it does them with; `lifecycle` in rust_api decides.
final class LifecyclePolicy {
  const LifecyclePolicy();

  bool satisfies(LifecycleAchievement achievement, LifecycleTarget target) =>
      native.lifecycleSatisfies(achievement: achievement, target: target);

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

  bool unconfirmedLeaseMayFail(LifecycleTarget target) =>
      native.lifecycleUnconfirmedLeaseMayFail(target: target);

  bool transportNeedsReplacement(
    TransportPhase phase, {
    required bool hasSession,
  }) => native.lifecycleTransportNeedsReplacement(
    phase: phase,
    hasSession: hasSession,
  );

  bool transportUsable(TransportPhase phase) =>
      native.lifecycleTransportUsable(phase: phase);

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

const lifecyclePolicy = LifecyclePolicy();
