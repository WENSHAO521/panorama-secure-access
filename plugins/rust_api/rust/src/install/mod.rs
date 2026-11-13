//! Install and migration decisions; copying and elevation stay in Dart.

pub const LEGACY_BUNDLE_ID: &str = "com.follow.clash";
const LEGACY_PUBLISHER: &str = "Panorama";
const LEGACY_HELPER_UNIT: &str = "flclash-helper.service";
const LEGACY_HELPER_RULES: &str = "/etc/polkit-1/rules.d/49-flclash-helper.rules";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LegacyPackageKind {
    Deb,
    Rpm,
    Ostree,
}

fn join(separator: char, parts: &[&str]) -> String {
    let mut out = String::new();
    for part in parts.iter().filter(|part| !part.is_empty()) {
        if !out.is_empty() && !out.ends_with(separator) {
            out.push(separator);
        }
        out.push_str(part);
    }
    out
}

/// Windows releases already used their own folder; only FlClash's is a
/// candidate there.
pub fn legacy_data_directories(
    operating_system: &str,
    environment: &[(String, String)],
) -> Vec<String> {
    let env = |key: &str| {
        environment
            .iter()
            .find(|(name, _)| name == key)
            .map(|(_, value)| value.as_str())
    };
    let home = env("HOME").or_else(|| env("USERPROFILE")).unwrap_or("");
    match operating_system {
        "linux" => {
            let base = match env("XDG_DATA_HOME") {
                Some(data_home) if !data_home.is_empty() => data_home.to_owned(),
                _ => join('/', &[home, ".local", "share"]),
            };
            vec![
                join('/', &[&base, LEGACY_BUNDLE_ID]),
                join('/', &[&base, "FlClash"]),
            ]
        }
        "macos" => vec![join(
            '/',
            &[home, "Library", "Application Support", LEGACY_BUNDLE_ID],
        )],
        "windows" => match env("APPDATA") {
            Some(app_data) if !app_data.is_empty() => {
                vec![join('\\', &[app_data, "com.follow", "clash"])]
            }
            _ => Vec::new(),
        },
        _ => Vec::new(),
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DataCandidate {
    pub same_as_target: bool,
    pub has_user_data: bool,
}

/// The candidate an import copies from, or None to leave the target alone:
/// a target that holds anything at all is never overwritten.
pub fn pick_import_source(
    target_has_data: bool,
    target_empty: bool,
    candidates: &[DataCandidate],
) -> Option<u32> {
    if target_has_data || !target_empty {
        return None;
    }
    candidates
        .iter()
        .position(|candidate| !candidate.same_as_target && candidate.has_user_data)
        .map(|index| index as u32)
}

/// Lock files and the restore staging area belong to the running instance.
pub fn is_transient_entry(name: &str, executable_name: &str) -> bool {
    name == "FlClash.lock"
        || name == "restore"
        || name.strip_suffix(".lock") == Some(executable_name)
}

/// FlClash itself carries another maintainer, so it never counts.
pub fn is_legacy_deb_status(output: &str) -> bool {
    output.contains("install ok installed") && output.contains(LEGACY_PUBLISHER)
}

pub fn is_legacy_rpm_packager(output: &str) -> bool {
    output.contains(LEGACY_PUBLISHER)
}

pub fn is_legacy_mac_bundle(bundle_name: &str, bundle_identifier: &str) -> bool {
    bundle_name == "Panorama Secure Access" && bundle_identifier == LEGACY_BUNDLE_ID
}

/// The legacy Helper goes first so a running one stops holding the TUN. The
/// script runs as root, so only the package names earlier releases used are
/// accepted.
pub fn linux_removal_script(kind: LegacyPackageKind, package: &str) -> Option<String> {
    if !matches!(package, "flclash" | "FlClash") {
        return None;
    }
    let remove = match kind {
        LegacyPackageKind::Deb => format!("dpkg -r {package}"),
        LegacyPackageKind::Rpm => format!("rpm -e {package}"),
        LegacyPackageKind::Ostree => format!("rpm-ostree uninstall {package}"),
    };
    Some(
        [
            format!("systemctl disable --now {LEGACY_HELPER_UNIT} >/dev/null 2>&1"),
            format!("rm -f /etc/systemd/system/{LEGACY_HELPER_UNIT} {LEGACY_HELPER_RULES}"),
            "systemctl daemon-reload >/dev/null 2>&1".to_owned(),
            remove,
        ]
        .join("; "),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn env(pairs: &[(&str, &str)]) -> Vec<(String, String)> {
        pairs
            .iter()
            .map(|(k, v)| ((*k).into(), (*v).into()))
            .collect()
    }

    #[test]
    fn legacy_directories_follow_each_platform() {
        assert_eq!(
            legacy_data_directories("linux", &env(&[("HOME", "/home/a")])),
            vec![
                "/home/a/.local/share/com.follow.clash",
                "/home/a/.local/share/FlClash"
            ],
        );
        assert_eq!(
            legacy_data_directories(
                "linux",
                &env(&[("HOME", "/home/a"), ("XDG_DATA_HOME", "/data/")])
            ),
            vec!["/data/com.follow.clash", "/data/FlClash"],
        );
        assert_eq!(
            legacy_data_directories("macos", &env(&[("HOME", "/Users/a")])),
            vec!["/Users/a/Library/Application Support/com.follow.clash"],
        );
        assert_eq!(
            legacy_data_directories(
                "windows",
                &env(&[("APPDATA", r"C:\Users\a\AppData\Roaming")])
            ),
            vec![r"C:\Users\a\AppData\Roaming\com.follow\clash"],
        );
        assert!(legacy_data_directories("windows", &[]).is_empty());
        assert!(legacy_data_directories("android", &env(&[("HOME", "/x")])).is_empty());
    }

    #[test]
    fn an_import_only_fills_an_empty_target_from_another_directory() {
        let candidates = [
            DataCandidate {
                same_as_target: true,
                has_user_data: true,
            },
            DataCandidate {
                same_as_target: false,
                has_user_data: false,
            },
            DataCandidate {
                same_as_target: false,
                has_user_data: true,
            },
        ];
        assert_eq!(pick_import_source(false, true, &candidates), Some(2));
        assert_eq!(pick_import_source(false, false, &candidates), None);
        assert_eq!(pick_import_source(true, true, &candidates), None);
    }

    #[test]
    fn transient_entries_are_the_running_instances_own() {
        assert!(is_transient_entry("FlClash.lock", "panorama-secure-access"));
        assert!(is_transient_entry(
            "panorama-secure-access.lock",
            "panorama-secure-access"
        ));
        assert!(is_transient_entry("restore", "panorama-secure-access"));
        assert!(!is_transient_entry(
            "database.sqlite",
            "panorama-secure-access"
        ));
    }

    #[test]
    fn only_packages_our_releases_built_are_recognised_and_removed() {
        assert!(is_legacy_deb_status("install ok installed|Panorama <a@b>"));
        assert!(!is_legacy_deb_status("install ok installed|chen08209"));
        assert!(is_legacy_mac_bundle(
            "Panorama Secure Access",
            "com.follow.clash"
        ));
        assert!(!is_legacy_mac_bundle("FlClash", "com.follow.clash"));
        assert_eq!(
            linux_removal_script(LegacyPackageKind::Ostree, "FlClash").unwrap(),
            "systemctl disable --now flclash-helper.service >/dev/null 2>&1; \
             rm -f /etc/systemd/system/flclash-helper.service /etc/polkit-1/rules.d/49-flclash-helper.rules; \
             systemctl daemon-reload >/dev/null 2>&1; rpm-ostree uninstall FlClash",
        );
        assert_eq!(
            linux_removal_script(LegacyPackageKind::Deb, "x; rm -rf /"),
            None
        );
    }
}
