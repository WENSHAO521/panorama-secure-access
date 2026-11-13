use std::collections::HashMap;

use flutter_rust_bridge::frb;

use crate::install;
pub use crate::install::{DataCandidate, LegacyPackageKind};

#[frb(mirror(LegacyPackageKind))]
pub enum _LegacyPackageKind {
    Deb,
    Rpm,
    Ostree,
}

#[frb(mirror(DataCandidate))]
pub struct _DataCandidate {
    pub same_as_target: bool,
    pub has_user_data: bool,
}

#[frb(sync)]
pub fn legacy_data_directories(
    operating_system: String,
    environment: HashMap<String, String>,
) -> Vec<String> {
    let environment: Vec<(String, String)> = environment.into_iter().collect();
    install::legacy_data_directories(&operating_system, &environment)
}

#[frb(sync)]
pub fn pick_import_source(
    target_has_data: bool,
    target_empty: bool,
    candidates: Vec<DataCandidate>,
) -> Option<u32> {
    install::pick_import_source(target_has_data, target_empty, &candidates)
}

#[frb(sync)]
pub fn is_transient_entry(name: String, executable_name: String) -> bool {
    install::is_transient_entry(&name, &executable_name)
}

#[frb(sync)]
pub fn is_legacy_deb_status(output: String) -> bool {
    install::is_legacy_deb_status(&output)
}

#[frb(sync)]
pub fn is_legacy_rpm_packager(output: String) -> bool {
    install::is_legacy_rpm_packager(&output)
}

#[frb(sync)]
pub fn is_legacy_mac_bundle(bundle_name: String, bundle_identifier: String) -> bool {
    install::is_legacy_mac_bundle(&bundle_name, &bundle_identifier)
}

#[frb(sync)]
pub fn linux_removal_script(kind: LegacyPackageKind, package: String) -> Option<String> {
    install::linux_removal_script(kind, &package)
}
