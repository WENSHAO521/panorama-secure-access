use std::net::Ipv6Addr;

use super::cidr::is_cidr;

/// Takes a zone as Go's net.ParseIP does not but its dialers and listeners do,
/// without asking whether that interface exists on this machine.
fn is_ipv6(value: &str) -> bool {
    let (address, zone) = match value.split_once('%') {
        Some((address, zone)) => (address, Some(zone)),
        None => (value, None),
    };
    let valid_zone = zone.is_none_or(|zone| {
        !zone.is_empty()
            && zone
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || matches!(b, b'.' | b'_' | b'-'))
    });
    valid_zone && address.parse::<Ipv6Addr>().is_ok()
}

fn is_domain_label(label: &str) -> bool {
    let bytes = label.as_bytes();
    let word = |b: &u8| b.is_ascii_alphanumeric() || *b == b'_';
    match bytes {
        [] => false,
        [only] => word(only),
        [first, middle @ .., last] => {
            bytes.len() <= 63
                && word(first)
                && word(last)
                && middle.iter().all(|b| word(b) || *b == b'-')
        }
    }
}

pub fn is_host(value: &str) -> bool {
    if value.contains(':') {
        return is_ipv6(value);
    }
    value.len() <= 253 && value.split('.').all(is_domain_label)
}

/// mihomo starts no DNS server, and only logs why, for an address this refuses.
pub fn is_listen_address(value: &str) -> bool {
    let Some((host, port)) = value.rsplit_once(':') else {
        return false;
    };
    let valid_host = if host.is_empty() {
        true
    } else if let Some(inner) = host.strip_prefix('[').and_then(|h| h.strip_suffix(']')) {
        is_ipv6(inner)
    } else {
        !host.contains(':') && is_host(host)
    };
    valid_host && parse_port(port).is_some_and(|port| port > 0)
}

fn parse_port(value: &str) -> Option<u32> {
    if value.is_empty() || value.len() > 5 || !value.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    value.parse::<u32>().ok().filter(|port| *port <= 65535)
}

pub fn is_port_range(value: &str) -> bool {
    match value.split_once('-') {
        Some((start, end)) => parse_port(start).is_some() && parse_port(end).is_some(),
        None => parse_port(value).is_some(),
    }
}

/// The sniffer's address lists also take mihomo's geoip: and rule-set: items.
pub fn is_ip_matcher(value: &str) -> bool {
    let lower = value.to_ascii_lowercase();
    lower.starts_with("geoip:") || lower.starts_with("rule-set:") || is_cidr(value)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hosts_are_domains_or_bare_ipv6() {
        for value in [
            "example.com",
            "a",
            "_dns.local",
            "1.2.3.4",
            "::1",
            "x-y.z",
            "fe80::1%eth0",
            "fe80::1%12",
        ] {
            assert!(is_host(value), "{value}");
        }
        let long_label = "a".repeat(64);
        let long_name = ["a"; 128].join(".");
        for value in [
            "",
            "a.",
            "-a.com",
            "a-.com",
            "a b",
            "[::1]",
            "1:2",
            "fe80::1%",
            "fe80::1%a b",
            "fe80::1%a%b",
            "%eth0",
            long_label.as_str(),
            long_name.as_str(),
        ] {
            assert!(!is_host(value), "{value}");
        }
    }

    #[test]
    fn listen_addresses_need_a_port_and_bracketed_ipv6() {
        for value in [
            ":53",
            "0.0.0.0:1053",
            "[::]:53",
            "[fe80::1%en0]:53",
            "localhost:65535",
        ] {
            assert!(is_listen_address(value), "{value}");
        }
        for value in [
            "53",
            "0.0.0.0:0",
            ":65536",
            "::1:53",
            "[::1]",
            "a:b",
            ":053x",
        ] {
            assert!(!is_listen_address(value), "{value}");
        }
    }

    #[test]
    fn port_ranges_are_one_or_two_ports() {
        for value in ["0", "443", "1000-2000", "65535", "00080"] {
            assert!(is_port_range(value), "{value}");
        }
        for value in ["", "65536", "1-", "-1", "1-2-3", "123456", "a", " 1"] {
            assert!(!is_port_range(value), "{value}");
        }
    }

    #[test]
    fn ip_matchers_take_geoip_and_rule_sets() {
        for value in ["GEOIP:cn", "rule-set:private", "10.0.0.0/8"] {
            assert!(is_ip_matcher(value), "{value}");
        }
        assert!(!is_ip_matcher("10.0.0.1"));
    }
}
