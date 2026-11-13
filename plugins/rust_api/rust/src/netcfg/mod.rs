//! Network settings the core would refuse, checked before they reach it, and
//! the route arithmetic TUN needs.

mod address;
mod cidr;

pub use address::{is_host, is_ip_matcher, is_listen_address, is_port_range};
pub use cidr::{is_cidr, subtract_cidrs};
