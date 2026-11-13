use flutter_rust_bridge::frb;

use crate::lifecycle;
pub use crate::lifecycle::{
    DisconnectReaction, LifecycleAchievement, LifecycleOutcome, LifecycleTarget, ReconcilePlan,
    TransportEventKind, TransportPhase,
};

#[frb(mirror(LifecycleTarget))]
pub enum _LifecycleTarget {
    Running,
    Restarted,
    Stopped,
    Closed,
}

#[frb(mirror(LifecycleAchievement))]
pub enum _LifecycleAchievement {
    RunningExisting,
    RunningFresh,
    Idle,
    Closed,
}

#[frb(mirror(LifecycleOutcome))]
pub enum _LifecycleOutcome {
    Applied,
    Coalesced,
    Superseded,
}

#[frb(mirror(TransportPhase))]
pub enum _TransportPhase {
    Idle,
    Starting,
    Ready,
    Connected,
    Failed,
    Closed,
}

#[frb(mirror(TransportEventKind))]
pub enum _TransportEventKind {
    Ready,
    Connected,
    Disconnected,
    Failed,
}

#[frb(mirror(DisconnectReaction))]
pub enum _DisconnectReaction {
    Ignore,
    UnexpectedDisconnect,
    TransportFailed,
}

#[frb(mirror(ReconcilePlan))]
pub struct _ReconcilePlan {
    pub keep_existing: bool,
    pub stop_session: bool,
    pub allow_unconfirmed_exit: bool,
    pub start: bool,
    pub close: bool,
}

#[frb(sync)]
pub fn lifecycle_satisfies(achievement: LifecycleAchievement, target: LifecycleTarget) -> bool {
    lifecycle::satisfies(achievement, target)
}

#[frb(sync)]
pub fn lifecycle_command_outcome(
    revision: i64,
    target: LifecycleTarget,
    settled_revision: i64,
    settled_target: LifecycleTarget,
) -> Option<LifecycleOutcome> {
    lifecycle::command_outcome(revision, target, settled_revision, settled_target)
}

#[frb(sync)]
pub fn lifecycle_plan_reconcile(
    target: LifecycleTarget,
    has_session: bool,
    session_running: bool,
    terminal_requested: bool,
) -> ReconcilePlan {
    lifecycle::plan_reconcile(target, has_session, session_running, terminal_requested)
}

#[frb(sync)]
pub fn lifecycle_unconfirmed_lease_may_fail(target: LifecycleTarget) -> bool {
    lifecycle::unconfirmed_lease_may_fail(target)
}

#[frb(sync)]
pub fn lifecycle_transport_needs_replacement(phase: TransportPhase, has_session: bool) -> bool {
    lifecycle::transport_needs_replacement(phase, has_session)
}

#[frb(sync)]
pub fn lifecycle_transport_usable(phase: TransportPhase) -> bool {
    lifecycle::transport_usable(phase)
}

#[frb(sync)]
pub fn lifecycle_disconnect_reaction(
    event: TransportEventKind,
    session_running: bool,
    same_generation: bool,
) -> DisconnectReaction {
    lifecycle::disconnect_reaction(event, session_running, same_generation)
}
