//! The decisions of the desktop Core lifecycle: which commands a settled
//! intent answers and how, what reconciling an intent has to do, and how a
//! transport event bears on a running session. The waiting, the process and
//! the socket stay with the Dart controller in `lib/core/desktop/`.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LifecycleTarget {
    Running,
    Restarted,
    Stopped,
    Closed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LifecycleAchievement {
    RunningExisting,
    RunningFresh,
    Idle,
    Closed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LifecycleOutcome {
    Applied,
    Coalesced,
    Superseded,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TransportPhase {
    Idle,
    Starting,
    Ready,
    Connected,
    Failed,
    Closed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TransportEventKind {
    Ready,
    Connected,
    Disconnected,
    Failed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DisconnectReaction {
    Ignore,
    UnexpectedDisconnect,
    TransportFailed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct ReconcilePlan {
    pub keep_existing: bool,
    pub stop_session: bool,
    pub allow_unconfirmed_exit: bool,
    pub start: bool,
    pub close: bool,
}

pub fn wants_running(target: LifecycleTarget) -> bool {
    matches!(
        target,
        LifecycleTarget::Running | LifecycleTarget::Restarted
    )
}

pub fn satisfies(achievement: LifecycleAchievement, target: LifecycleTarget) -> bool {
    use LifecycleAchievement as A;
    match target {
        LifecycleTarget::Running => matches!(achievement, A::RunningExisting | A::RunningFresh),
        LifecycleTarget::Restarted => achievement == A::RunningFresh,
        LifecycleTarget::Stopped => achievement == A::Idle,
        LifecycleTarget::Closed => achievement == A::Closed,
    }
}

/// None for a command newer than the settled intent, which stays pending.
pub fn command_outcome(
    revision: i64,
    target: LifecycleTarget,
    settled_revision: i64,
    settled_target: LifecycleTarget,
) -> Option<LifecycleOutcome> {
    if revision > settled_revision {
        None
    } else if revision == settled_revision {
        Some(LifecycleOutcome::Applied)
    } else if target == settled_target || (wants_running(target) && wants_running(settled_target)) {
        Some(LifecycleOutcome::Coalesced)
    } else {
        Some(LifecycleOutcome::Superseded)
    }
}

/// A start only proceeds while the latest intent still wants the Core running,
/// which the controller checks again after every wait.
pub fn plan_reconcile(
    target: LifecycleTarget,
    has_session: bool,
    session_running: bool,
    terminal_requested: bool,
) -> ReconcilePlan {
    let keep_existing = target == LifecycleTarget::Running && has_session && session_running;
    let (allow_unconfirmed_exit, start, close) = match target {
        LifecycleTarget::Running | LifecycleTarget::Restarted => (terminal_requested, true, false),
        LifecycleTarget::Stopped => (false, false, false),
        LifecycleTarget::Closed => (true, false, true),
    };
    ReconcilePlan {
        keep_existing,
        stop_session: has_session && !keep_existing,
        allow_unconfirmed_exit,
        start: start && !keep_existing,
        close,
    }
}

/// A lease whose exit was never confirmed blocks every intent but closing.
pub fn unconfirmed_lease_may_fail(target: LifecycleTarget) -> bool {
    target == LifecycleTarget::Closed
}

/// A connected transport without a session belongs to a Core nobody owns.
pub fn transport_needs_replacement(phase: TransportPhase, has_session: bool) -> bool {
    matches!(phase, TransportPhase::Failed | TransportPhase::Closed)
        || (phase == TransportPhase::Connected && !has_session)
}

pub fn transport_usable(phase: TransportPhase) -> bool {
    matches!(phase, TransportPhase::Ready | TransportPhase::Connected)
}

pub fn disconnect_reaction(
    event: TransportEventKind,
    session_running: bool,
    same_generation: bool,
) -> DisconnectReaction {
    match event {
        _ if !session_running => DisconnectReaction::Ignore,
        TransportEventKind::Disconnected if same_generation => {
            DisconnectReaction::UnexpectedDisconnect
        }
        TransportEventKind::Failed => DisconnectReaction::TransportFailed,
        _ => DisconnectReaction::Ignore,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use LifecycleTarget::*;

    #[test]
    fn a_running_intent_accepts_any_session_but_a_restart_only_a_fresh_one() {
        assert!(satisfies(LifecycleAchievement::RunningExisting, Running));
        assert!(!satisfies(LifecycleAchievement::RunningExisting, Restarted));
        assert!(satisfies(LifecycleAchievement::RunningFresh, Restarted));
        assert!(!satisfies(LifecycleAchievement::Idle, Closed));
    }

    #[test]
    fn older_commands_coalesce_into_a_settled_intent_of_the_same_kind() {
        assert_eq!(
            command_outcome(3, Stopped, 3, Stopped),
            Some(LifecycleOutcome::Applied)
        );
        assert_eq!(
            command_outcome(1, Running, 3, Restarted),
            Some(LifecycleOutcome::Coalesced)
        );
        assert_eq!(
            command_outcome(2, Stopped, 3, Stopped),
            Some(LifecycleOutcome::Coalesced)
        );
        assert_eq!(
            command_outcome(2, Running, 3, Stopped),
            Some(LifecycleOutcome::Superseded)
        );
        assert_eq!(command_outcome(4, Running, 3, Running), None);
    }

    #[test]
    fn a_running_session_is_kept_only_for_a_plain_start() {
        let keep = plan_reconcile(Running, true, true, false);
        assert!(keep.keep_existing && !keep.stop_session && !keep.start);
        let restart = plan_reconcile(Restarted, true, true, true);
        assert!(restart.stop_session && restart.start && restart.allow_unconfirmed_exit);
        let recover = plan_reconcile(Running, true, false, false);
        assert!(recover.stop_session && recover.start && !recover.allow_unconfirmed_exit);
        let stop = plan_reconcile(Stopped, true, true, true);
        assert!(stop.stop_session && !stop.allow_unconfirmed_exit && !stop.start);
        let close = plan_reconcile(Closed, false, false, true);
        assert!(!close.stop_session && close.allow_unconfirmed_exit && close.close);
    }

    #[test]
    fn transports_are_replaced_when_dead_or_owned_by_nobody() {
        assert!(transport_needs_replacement(TransportPhase::Failed, true));
        assert!(transport_needs_replacement(
            TransportPhase::Connected,
            false
        ));
        assert!(!transport_needs_replacement(
            TransportPhase::Connected,
            true
        ));
        assert!(!transport_needs_replacement(TransportPhase::Ready, false));
        assert!(transport_usable(TransportPhase::Connected));
        assert!(!transport_usable(TransportPhase::Starting));
    }

    #[test]
    fn only_the_running_session_reacts_to_a_lost_transport() {
        use TransportEventKind as E;
        assert_eq!(
            disconnect_reaction(E::Disconnected, true, true),
            DisconnectReaction::UnexpectedDisconnect
        );
        assert_eq!(
            disconnect_reaction(E::Disconnected, true, false),
            DisconnectReaction::Ignore
        );
        assert_eq!(
            disconnect_reaction(E::Failed, true, false),
            DisconnectReaction::TransportFailed
        );
        assert_eq!(
            disconnect_reaction(E::Failed, false, true),
            DisconnectReaction::Ignore
        );
        assert_eq!(
            disconnect_reaction(E::Connected, true, true),
            DisconnectReaction::Ignore
        );
    }
}
