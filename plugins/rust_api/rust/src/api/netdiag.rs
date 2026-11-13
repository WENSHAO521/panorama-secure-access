use flutter_rust_bridge::frb;

use crate::netdiag;
pub use crate::netdiag::{
    DnsApplyRoute, FailureKind, HttpStatusClass, LocalAddress, LocalInterface,
    NetworkChangeReaction,
};

#[frb(mirror(DnsApplyRoute))]
pub enum _DnsApplyRoute {
    Fresh,
    Reapply,
    ReleaseFirst,
}

#[frb(mirror(FailureKind))]
pub enum _FailureKind {
    Timeout,
    HostLookup,
    Connection,
    Tls,
    Unknown,
}

#[frb(mirror(HttpStatusClass))]
pub enum _HttpStatusClass {
    AccessDenied,
    NotFound,
    RateLimited,
    Server,
    BadResponse,
}

#[frb(mirror(LocalInterface))]
pub struct _LocalInterface {
    pub name: String,
    pub addresses: Vec<LocalAddress>,
}

#[frb(mirror(LocalAddress))]
pub struct _LocalAddress {
    pub address: String,
    pub ipv4: bool,
}

#[frb(mirror(NetworkChangeReaction))]
pub struct _NetworkChangeReaction {
    pub resync_system_dns: bool,
    pub refresh_local_ip: bool,
    pub report_to_core: bool,
    pub bump_host_epoch: bool,
}

#[frb(sync)]
pub fn dns_apply_route(applied_service: Option<String>, service: String) -> DnsApplyRoute {
    netdiag::dns_apply_route(applied_service.as_deref(), &service)
}

#[frb(sync)]
pub fn dns_patched_servers(current: Vec<String>, fallback: String) -> Option<Vec<String>> {
    netdiag::dns_patched_servers(&current, &fallback)
}

#[frb(sync)]
pub fn core_failure_kind(reason: Option<String>) -> FailureKind {
    netdiag::core_failure_kind(reason.as_deref())
}

#[frb(sync)]
pub fn http_status_class(status: i32) -> HttpStatusClass {
    netdiag::http_status_class(status)
}

#[frb(sync)]
pub fn pick_local_address(interfaces: Vec<LocalInterface>) -> String {
    netdiag::pick_local_address(&interfaces)
}

#[frb(sync)]
pub fn network_change_reaction(
    had_vpn: bool,
    has_vpn: bool,
    desktop: bool,
) -> NetworkChangeReaction {
    netdiag::network_change_reaction(had_vpn, has_vpn, desktop)
}
