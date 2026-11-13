//! Network diagnosis and recovery decisions; the probes stay in Dart.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DnsApplyRoute {
    Fresh,
    Reapply,
    ReleaseFirst,
}

/// Where applying the fallback DNS starts, given the service the last patch
/// was made on.
pub fn dns_apply_route(applied_service: Option<&str>, service: &str) -> DnsApplyRoute {
    match applied_service {
        None => DnsApplyRoute::Fresh,
        Some(applied) if applied == service => DnsApplyRoute::Reapply,
        Some(_) => DnsApplyRoute::ReleaseFirst,
    }
}

/// None when `current` already carries the fallback and nothing is written.
pub fn dns_patched_servers(current: &[String], fallback: &str) -> Option<Vec<String>> {
    if current.iter().any(|server| server == fallback) {
        return None;
    }
    let mut patched = current.to_vec();
    patched.push(fallback.to_owned());
    Some(patched)
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FailureKind {
    Timeout,
    HostLookup,
    Connection,
    Tls,
    Unknown,
}

/// The `reason` the Core attaches to a failed request.
pub fn core_failure_kind(reason: Option<&str>) -> FailureKind {
    match reason {
        Some("timeout") => FailureKind::Timeout,
        Some("dns") => FailureKind::HostLookup,
        Some("tls") => FailureKind::Tls,
        Some("connection") => FailureKind::Connection,
        _ => FailureKind::Unknown,
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HttpStatusClass {
    AccessDenied,
    NotFound,
    RateLimited,
    Server,
    BadResponse,
}

pub fn http_status_class(status: i32) -> HttpStatusClass {
    match status {
        401 | 403 | 407 => HttpStatusClass::AccessDenied,
        404 | 410 => HttpStatusClass::NotFound,
        429 => HttpStatusClass::RateLimited,
        500..=599 => HttpStatusClass::Server,
        _ => HttpStatusClass::BadResponse,
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LocalInterface {
    pub name: String,
    pub addresses: Vec<LocalAddress>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LocalAddress {
    pub address: String,
    pub ipv4: bool,
}

fn is_wifi(name: &str) -> bool {
    let lower = name.to_lowercase();
    lower.contains("wlan") || lower.contains("wi-fi") || lower == "en0" || lower == "eth0"
}

/// Wi-Fi first, then interfaces holding IPv4, and IPv4 first within one; an
/// empty string when no interface has an address.
pub fn pick_local_address(interfaces: &[LocalInterface]) -> String {
    let mut ordered: Vec<&LocalInterface> = interfaces.iter().collect();
    ordered.sort_by_key(|interface| {
        (
            !is_wifi(&interface.name),
            !interface.addresses.iter().any(|address| address.ipv4),
        )
    });
    ordered
        .into_iter()
        .find_map(|interface| {
            let mut addresses: Vec<&LocalAddress> = interface.addresses.iter().collect();
            addresses.sort_by_key(|address| !address.ipv4);
            addresses.first().map(|address| address.address.clone())
        })
        .unwrap_or_default()
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct NetworkChangeReaction {
    pub resync_system_dns: bool,
    pub refresh_local_ip: bool,
    pub report_to_core: bool,
    pub bump_host_epoch: bool,
}

/// The app's own VPN coming or going is not a new network. Android's
/// NetworkObserver tells the Core itself, so a phone only moves its epoch.
pub fn network_change_reaction(
    had_vpn: bool,
    has_vpn: bool,
    desktop: bool,
) -> NetworkChangeReaction {
    let new_network = had_vpn == has_vpn;
    NetworkChangeReaction {
        resync_system_dns: true,
        refresh_local_ip: true,
        report_to_core: new_network && desktop,
        bump_host_epoch: new_network && !desktop,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn interface(name: &str, addresses: &[(&str, bool)]) -> LocalInterface {
        LocalInterface {
            name: name.into(),
            addresses: addresses
                .iter()
                .map(|(address, ipv4)| LocalAddress {
                    address: (*address).into(),
                    ipv4: *ipv4,
                })
                .collect(),
        }
    }

    #[test]
    fn the_dns_patch_moves_with_the_default_service() {
        assert_eq!(dns_apply_route(None, "Wi-Fi"), DnsApplyRoute::Fresh);
        assert_eq!(
            dns_apply_route(Some("Wi-Fi"), "Wi-Fi"),
            DnsApplyRoute::Reapply
        );
        assert_eq!(
            dns_apply_route(Some("Ethernet"), "Wi-Fi"),
            DnsApplyRoute::ReleaseFirst
        );
        let current = vec!["1.1.1.1".to_string()];
        assert_eq!(
            dns_patched_servers(&current, "223.5.5.5"),
            Some(vec!["1.1.1.1".to_string(), "223.5.5.5".to_string()]),
        );
        assert_eq!(
            dns_patched_servers(&["223.5.5.5".to_string()], "223.5.5.5"),
            None
        );
    }

    #[test]
    fn failures_are_classified_like_the_messages_expect() {
        assert_eq!(core_failure_kind(Some("dns")), FailureKind::HostLookup);
        assert_eq!(core_failure_kind(None), FailureKind::Unknown);
        assert_eq!(http_status_class(407), HttpStatusClass::AccessDenied);
        assert_eq!(http_status_class(503), HttpStatusClass::Server);
        assert_eq!(http_status_class(302), HttpStatusClass::BadResponse);
    }

    #[test]
    fn the_local_address_prefers_wifi_and_ipv4() {
        let interfaces = vec![
            interface("utun3", &[("10.9.0.1", true)]),
            interface("en0", &[("fe80::1", false), ("192.168.1.20", true)]),
        ];
        assert_eq!(pick_local_address(&interfaces), "192.168.1.20");
        let no_wifi = vec![
            interface("tun0", &[("fd00::2", false)]),
            interface("eth1", &[("10.0.0.2", true)]),
        ];
        assert_eq!(pick_local_address(&no_wifi), "10.0.0.2");
        assert_eq!(pick_local_address(&[interface("lo", &[])]), "");
    }

    #[test]
    fn only_a_new_network_reaches_the_core() {
        let desktop = network_change_reaction(false, false, true);
        assert!(desktop.report_to_core && !desktop.bump_host_epoch && desktop.resync_system_dns);
        let phone = network_change_reaction(true, true, false);
        assert!(!phone.report_to_core && phone.bump_host_epoch);
        let vpn_up = network_change_reaction(false, true, true);
        assert!(!vpn_up.report_to_core && !vpn_up.bump_host_epoch && vpn_up.refresh_local_ip);
    }
}
