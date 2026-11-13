use flutter_rust_bridge::frb;

use crate::netcfg;

#[frb(sync)]
pub fn is_cidr(value: String) -> bool {
    netcfg::is_cidr(&value)
}

#[frb(sync)]
pub fn is_ip_matcher(value: String) -> bool {
    netcfg::is_ip_matcher(&value)
}

#[frb(sync)]
pub fn is_host(value: String) -> bool {
    netcfg::is_host(&value)
}

#[frb(sync)]
pub fn is_listen_address(value: String) -> bool {
    netcfg::is_listen_address(&value)
}

#[frb(sync)]
pub fn is_port_range(value: String) -> bool {
    netcfg::is_port_range(&value)
}

pub fn subtract_cidrs(
    include: Vec<String>,
    exclude: Vec<String>,
    whole_when_empty: bool,
) -> Vec<String> {
    netcfg::subtract_cidrs(&include, &exclude, whole_when_empty)
}
