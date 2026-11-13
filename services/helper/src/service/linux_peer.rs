use std::fs;
use std::path::{Path, PathBuf};

/// The Flutter executable the package installs beside the Helper.
pub(super) const APP_EXECUTABLE_NAME: &str = "panorama-secure-access";

/// Variables that make the dynamic loader run code of the caller's choosing
/// inside the real app before `main`.
const LOADER_INJECTION_VARIABLES: [&str; 3] = ["LD_PRELOAD", "LD_AUDIT", "LD_LIBRARY_PATH"];

const DELETED_SUFFIX: &str = " (deleted)";

/// A same-account script could otherwise ask for a root Core against a socket
/// it listens on. Requiring the peer to be the packaged app, started without
/// loader injection and not traced, leaves only attacks that already control
/// the app process itself.
pub(super) fn verify_peer_process(
    proc_root: &Path,
    pid: i32,
    app_executable: &Path,
) -> Result<(), String> {
    if pid <= 0 {
        return Err("peer has no process ID".into());
    }
    let process = proc_root.join(pid.to_string());
    let executable = fs::read_link(process.join("exe"))
        .map_err(|error| format!("read executable of {pid}: {error}"))?;
    let executable = strip_deleted_suffix(executable);
    if executable != app_executable {
        return Err(format!(
            "peer {pid} runs {}, not {}",
            executable.display(),
            app_executable.display()
        ));
    }
    let status = fs::read_to_string(process.join("status"))
        .map_err(|error| format!("read status of {pid}: {error}"))?;
    match tracer_pid(&status) {
        Some(0) => {}
        Some(tracer) => return Err(format!("peer {pid} is traced by {tracer}")),
        None => return Err(format!("peer {pid} reports no TracerPid")),
    }
    let environment = fs::read(process.join("environ"))
        .map_err(|error| format!("read environment of {pid}: {error}"))?;
    if let Some(name) = loader_injection(&environment) {
        return Err(format!("peer {pid} was started with {name}"));
    }
    Ok(())
}

/// A package upgrade replaces the app on disk while the old one still runs; the
/// path it was started from is still the packaged one.
fn strip_deleted_suffix(path: PathBuf) -> PathBuf {
    match path
        .to_str()
        .and_then(|value| value.strip_suffix(DELETED_SUFFIX))
    {
        Some(stripped) => PathBuf::from(stripped),
        None => path,
    }
}

fn tracer_pid(status: &str) -> Option<i32> {
    status
        .lines()
        .find_map(|line| line.strip_prefix("TracerPid:"))
        .and_then(|value| value.trim().parse().ok())
}

fn loader_injection(environment: &[u8]) -> Option<&'static str> {
    environment
        .split(|byte| *byte == 0)
        .filter_map(|entry| {
            let separator = entry.iter().position(|byte| *byte == b'=')?;
            let (name, value) = entry.split_at(separator);
            (value.len() > 1).then_some(name)
        })
        .find_map(|name| {
            LOADER_INJECTION_VARIABLES
                .into_iter()
                .find(|candidate| candidate.as_bytes() == name)
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::symlink;

    struct FakeProc {
        root: PathBuf,
    }

    impl FakeProc {
        fn new(name: &str) -> Self {
            let root = std::env::temp_dir().join(format!("psa-peer-{name}-{}", std::process::id()));
            let _ = fs::remove_dir_all(&root);
            fs::create_dir_all(&root).unwrap();
            Self { root }
        }

        fn process(&self, pid: i32, executable: &str, tracer: i32, environment: &[&str]) {
            let directory = self.root.join(pid.to_string());
            fs::create_dir_all(&directory).unwrap();
            symlink(executable, directory.join("exe")).unwrap();
            fs::write(
                directory.join("status"),
                format!("Name:\tpanorama-secure\nTracerPid:\t{tracer}\nUid:\t1000\n"),
            )
            .unwrap();
            let mut environ = environment.join("\0");
            environ.push('\0');
            fs::write(directory.join("environ"), environ).unwrap();
        }
    }

    impl Drop for FakeProc {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }

    const APP: &str = "/usr/share/panorama-secure-access/panorama-secure-access";

    #[test]
    fn accepts_the_packaged_app() {
        let proc = FakeProc::new("app");
        proc.process(41, APP, 0, &["HOME=/home/u", "LD_LIBRARY_PATH="]);

        assert!(verify_peer_process(&proc.root, 41, Path::new(APP)).is_ok());
    }

    #[test]
    fn accepts_the_app_after_its_package_was_upgraded() {
        let proc = FakeProc::new("upgraded");
        proc.process(42, &format!("{APP}{DELETED_SUFFIX}"), 0, &["HOME=/home/u"]);

        assert!(verify_peer_process(&proc.root, 42, Path::new(APP)).is_ok());
    }

    #[test]
    fn rejects_another_program_of_the_same_account() {
        let proc = FakeProc::new("other");
        proc.process(43, "/usr/bin/python3", 0, &[]);

        let error = verify_peer_process(&proc.root, 43, Path::new(APP)).unwrap_err();
        assert!(error.contains("/usr/bin/python3"), "{error}");
    }

    #[test]
    fn rejects_a_traced_app() {
        let proc = FakeProc::new("traced");
        proc.process(44, APP, 900, &[]);

        let error = verify_peer_process(&proc.root, 44, Path::new(APP)).unwrap_err();
        assert!(error.contains("traced by 900"), "{error}");
    }

    #[test]
    fn rejects_an_app_started_with_loader_injection() {
        for variable in LOADER_INJECTION_VARIABLES {
            let proc = FakeProc::new(&variable.to_lowercase());
            proc.process(
                45,
                APP,
                0,
                &["HOME=/home/u", &format!("{variable}=/tmp/x.so")],
            );

            let error = verify_peer_process(&proc.root, 45, Path::new(APP)).unwrap_err();
            assert!(error.contains(variable), "{error}");
        }
    }

    #[test]
    fn rejects_a_peer_that_has_exited_or_has_no_pid() {
        let proc = FakeProc::new("gone");

        assert!(verify_peer_process(&proc.root, 46, Path::new(APP)).is_err());
        assert!(verify_peer_process(&proc.root, 0, Path::new(APP)).is_err());
    }
}
