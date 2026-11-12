use crate::service::hub::{
    ensure_core_sha256_configured, log_message, release_managed_core_on_shutdown, routes,
};
use crate::service::linux_peer::{verify_peer_process, APP_EXECUTABLE_NAME};

use anyhow::{bail, Context, Result};
use std::ffi::{CStr, OsStr, OsString};
use std::fs;
use std::future::Future;
use std::io::{Error, ErrorKind};
use std::os::unix::fs::{FileTypeExt, MetadataExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::pin::Pin;
use std::process::{Command, Stdio};
use std::task::{Context as TaskContext, Poll};
use std::time::Duration;
use tokio::net::{UnixListener, UnixStream};
use tokio::runtime::Runtime;
use tokio::signal::unix::{signal, SignalKind};
use tokio::time::Sleep;
use tokio_stream::Stream;

const SERVICE_NAME: &str = "panorama-secure-access-helper";
const UNIT_NAME: &str = "panorama-secure-access-helper.service";
const UNIT_PATH: &str = "/etc/systemd/system/panorama-secure-access-helper.service";
/// Read by the app (`helperUnitVersion`) to spot a unit without the sandbox.
const UNIT_VERSION: u32 = 2;
const UNIT_VERSION_PREFIX: &str = "# panorama-secure-access-helper-unit-version=";
const POLKIT_RULES_PATH: &str = "/etc/polkit-1/rules.d/49-panorama-secure-access-helper.rules";
const SYSTEMD_RUNNING_PATH: &str = "/run/systemd/system";
const RUNTIME_DIR_NAME: &str = "panorama-secure-access";
const SOCKET_PATH: &str = "/run/panorama-secure-access/helper.sock";
const OWNER_UID_ENV: &str = "PSA_HELPER_OWNER_UID";
const OWNER_GID_ENV: &str = "PSA_HELPER_OWNER_GID";
const SOCKET_MODE: u32 = 0o660;
const ACCEPT_RETRY_DELAY: Duration = Duration::from_secs(1);

#[derive(Debug, PartialEq, Eq)]
enum ServiceCommand {
    Run,
    Install,
    Uninstall,
    Upgrade,
    Refresh,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Owner {
    uid: u32,
    gid: u32,
}

pub fn main() -> Result<()> {
    match service_command(std::env::args_os().skip(1))? {
        ServiceCommand::Run => run_service(),
        ServiceCommand::Install => install_service(),
        ServiceCommand::Uninstall => uninstall_service(),
        ServiceCommand::Upgrade => upgrade_service(),
        ServiceCommand::Refresh => {
            if let Err(error) = refresh_installed_files() {
                eprintln!("Helper could not refresh its unit: {error:#}");
            }
            Ok(())
        }
    }
}

fn service_command(args: impl IntoIterator<Item = OsString>) -> Result<ServiceCommand> {
    let mut args = args.into_iter();
    let command = match args.next().as_deref() {
        None => ServiceCommand::Run,
        Some(value) if value == OsStr::new("install") => ServiceCommand::Install,
        Some(value) if value == OsStr::new("uninstall") => ServiceCommand::Uninstall,
        Some(value) if value == OsStr::new("upgrade") => ServiceCommand::Upgrade,
        Some(value) if value == OsStr::new("refresh") => ServiceCommand::Refresh,
        Some(value) => bail!("unknown helper command: {}", value.to_string_lossy()),
    };
    if args.next().is_some() {
        bail!("helper accepts at most one command");
    }
    Ok(command)
}

pub(super) fn core_owner() -> Result<(u32, u32), Error> {
    let owner = owner_from_env().map_err(Error::other)?;
    Ok((owner.uid, owner.gid))
}

pub(super) fn ensure_owner_socket(address: &str) -> Result<(), Error> {
    let owner = owner_from_env().map_err(Error::other)?;
    let metadata = fs::symlink_metadata(address)?;
    if !metadata.file_type().is_socket() || metadata.uid() != owner.uid {
        return Err(Error::other(
            "Core address is not a socket owned by the Helper owner",
        ));
    }
    Ok(())
}

fn owner_from_env() -> Result<Owner> {
    Ok(Owner {
        uid: read_id_env(OWNER_UID_ENV)?,
        gid: read_id_env(OWNER_GID_ENV)?,
    })
}

fn read_id_env(name: &str) -> Result<u32> {
    let value = std::env::var(name).with_context(|| format!("{name} is not set"))?;
    parse_owner_id(&value).with_context(|| format!("{name} is not a usable ID"))
}

/// Root owns the Core already; an owner of 0 would mean the service is running
/// for nobody and would hand the Core the credentials it is trying to avoid.
fn parse_owner_id(value: &str) -> Result<u32> {
    let id: u32 = value.trim().parse().context("expected an unsigned ID")?;
    if id == 0 {
        bail!("expected a non-root ID");
    }
    Ok(id)
}

/// pkexec and sudo both name the user who asked for the elevation; without one
/// there is nobody to grant the socket to, so installation has no owner.
fn invoking_owner() -> Result<Owner> {
    let uid = ["PKEXEC_UID", "SUDO_UID"]
        .into_iter()
        .find_map(|name| std::env::var(name).ok())
        .context("neither PKEXEC_UID nor SUDO_UID is set; run the installer through pkexec")?;
    let uid = parse_owner_id(&uid).context("the invoking user ID is not usable")?;
    let gid = parse_owner_id(&invoking_gid(uid)?).context("the invoking group is not usable")?;
    Ok(Owner { uid, gid })
}

fn invoking_gid(uid: u32) -> Result<String> {
    let output = Command::new("id")
        .args(["-g", &uid.to_string()])
        .output()
        .context("query the invoking user")?;
    if !output.status.success() {
        bail!("id -g {uid} failed with {}", output.status);
    }
    let value = String::from_utf8(output.stdout)
        .context("id returned invalid UTF-8")?
        .trim()
        .to_string();
    if value.is_empty() {
        bail!("id -g {uid} returned nothing");
    }
    Ok(value)
}

/// systemd splits `ExecStart=` on whitespace and expands `%` specifiers, so the
/// path travels double-quoted with its quotes, backslashes and `%` escaped.
fn quoted_unit_argument(path: &Path) -> String {
    let mut quoted = String::from("\"");
    for character in path.to_string_lossy().chars() {
        match character {
            '"' | '\\' => {
                quoted.push('\\');
                quoted.push(character);
            }
            '%' => quoted.push_str("%%"),
            _ => quoted.push(character),
        }
    }
    quoted.push('"');
    quoted
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct OwnerAccount {
    name: String,
    home: PathBuf,
}

fn owner_account(uid: u32) -> Result<OwnerAccount> {
    let mut buffer = vec![0 as libc::c_char; 16 * 1024];
    let mut entry: libc::passwd = unsafe { std::mem::zeroed() };
    let mut result: *mut libc::passwd = std::ptr::null_mut();
    // SAFETY: the buffers outlive the call; strings are copied before they drop.
    let status = unsafe {
        libc::getpwuid_r(
            uid,
            &mut entry,
            buffer.as_mut_ptr(),
            buffer.len(),
            &mut result,
        )
    };
    if status != 0 || result.is_null() {
        bail!("UID {uid} has no passwd entry");
    }
    let (name, home) = unsafe {
        (
            CStr::from_ptr(entry.pw_name).to_string_lossy().into_owned(),
            PathBuf::from(CStr::from_ptr(entry.pw_dir).to_string_lossy().into_owned()),
        )
    };
    // Silverblue's /home links to /var/home; sandbox paths need the real one.
    let home = fs::canonicalize(&home).unwrap_or(home);
    Ok(OwnerAccount { name, home })
}

/// The sandbox bounds what a hijacked root Core could change: the owner's home,
/// the network stack and the clock (mihomo's NTP `write-to-system`), not the OS.
fn unit_contents(executable: &Path, owner: Owner, account: &OwnerAccount) -> String {
    format!(
        "{UNIT_VERSION_PREFIX}{UNIT_VERSION}\n\
         [Unit]\n\
         Description=Panorama Secure Access Helper starts the Core with the privileges TUN mode needs.\n\
         After=nftables.service iptables.service\n\
         StartLimitIntervalSec=60\n\
         StartLimitBurst=5\n\
         \n\
         [Service]\n\
         Type=simple\n\
         ExecStartPre=-+{executable} refresh\n\
         ExecStart={executable}\n\
         Group={gid}\n\
         Environment={OWNER_UID_ENV}={uid}\n\
         Environment={OWNER_GID_ENV}={gid}\n\
         RuntimeDirectory={RUNTIME_DIR_NAME}\n\
         RuntimeDirectoryMode=0755\n\
         Restart=on-failure\n\
         RestartSec=5\n\
         NoNewPrivileges=yes\n\
         ProtectSystem=full\n\
         ProtectHome=read-only\n\
         ReadOnlyPaths=-/var/home -/var/opt -/opt -/var/spool -/var/lib\n\
         ReadWritePaths={home}\n\
         ProtectKernelModules=yes\n\
         ProtectControlGroups=yes\n\
         RestrictSUIDSGID=yes\n\
         LockPersonality=yes\n\
         CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SETUID CAP_SETGID \
         CAP_CHOWN CAP_FOWNER CAP_DAC_OVERRIDE CAP_DAC_READ_SEARCH CAP_SYS_PTRACE CAP_KILL CAP_SYS_TIME\n\
         \n\
         [Install]\n\
         WantedBy=multi-user.target\n",
        executable = quoted_unit_argument(executable),
        home = quoted_unit_argument(&account.home),
        uid = owner.uid,
        gid = owner.gid,
    )
}

/// polkit matches names as JavaScript strings, so odd ones get no rule.
fn is_portable_user_name(name: &str) -> bool {
    !name.is_empty()
        && name.len() <= 64
        && name
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'_' | b'-' | b'$'))
}

/// Lets the owner's session start, restart or reset this one unit without a
/// password; each verb only runs the fixed root-owned binary.
fn polkit_rules(account: &OwnerAccount) -> Option<String> {
    if !is_portable_user_name(&account.name) {
        return None;
    }
    Some(format!(
        "// Written by panorama-secure-access-helper install, removed by its uninstall.\n\
         polkit.addRule(function (action, subject) {{\n\
         \x20   if (action.id === \"org.freedesktop.systemd1.manage-units\" &&\n\
         \x20       action.lookup(\"unit\") === \"{UNIT_NAME}\" &&\n\
         \x20       [\"start\", \"restart\", \"reset-failed\"].indexOf(action.lookup(\"verb\")) >= 0 &&\n\
         \x20       subject.user === \"{name}\" && subject.local && subject.active) {{\n\
         \x20       return polkit.Result.YES;\n\
         \x20   }}\n\
         }});\n",
        name = account.name,
    ))
}

/// The unit runs this binary as root at every boot, so one the invoking user
/// could overwrite would turn a single polkit approval into standing root.
fn ensure_root_owned(executable: &Path) -> Result<()> {
    let directory = executable
        .parent()
        .context("helper executable has no parent directory")?;
    for path in [executable, directory] {
        let metadata = fs::metadata(path).with_context(|| format!("inspect {}", path.display()))?;
        if metadata.uid() != 0 || metadata.mode() & 0o022 != 0 {
            bail!(
                "{} must be owned by root and not writable by group or others to run as a service; \
                 install the package instead of running an unpacked bundle",
                path.display()
            );
        }
    }
    Ok(())
}

fn installed_id(unit: &str, name: &str) -> Option<u32> {
    let prefix = format!("Environment={name}=");
    unit.lines()
        .find_map(|line| line.strip_prefix(prefix.as_str()))
        .and_then(|value| parse_owner_id(value).ok())
}

fn installed_owner_uid(unit: &str) -> Option<u32> {
    installed_id(unit, OWNER_UID_ENV)
}

fn installed_owner(unit: &str) -> Option<Owner> {
    Some(Owner {
        uid: installed_id(unit, OWNER_UID_ENV)?,
        gid: installed_id(unit, OWNER_GID_ENV)?,
    })
}

fn read_installed_unit() -> Result<Option<String>> {
    match fs::read_to_string(UNIT_PATH) {
        Ok(contents) => Ok(Some(contents)),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(None),
        Err(error) => Err(error).with_context(|| format!("read {UNIT_PATH}")),
    }
}

fn ensure_unit_is_free_for(owner: Owner) -> Result<()> {
    let Some(existing) = read_installed_unit()? else {
        return Ok(());
    };
    match installed_owner_uid(&existing) {
        Some(uid) if uid != owner.uid => bail!(
            "the Helper is already installed for UID {uid}; \
             run `panorama-secure-access-helper uninstall` as that user first"
        ),
        _ => Ok(()),
    }
}

fn install_service() -> Result<()> {
    let executable = std::env::current_exe().context("resolve helper executable path")?;
    ensure_root_owned(&executable)?;
    let owner = invoking_owner()?;
    ensure_unit_is_free_for(owner)?;

    write_installed_files(&executable, owner)?;
    silence_systemctl(&["reset-failed", SERVICE_NAME]);
    run_systemctl(&["daemon-reload"])?;
    run_systemctl(&["enable", SERVICE_NAME])?;
    run_systemctl(&["restart", SERVICE_NAME])
}

fn write_installed_files(executable: &Path, owner: Owner) -> Result<bool> {
    let account = owner_account(owner.uid)?;
    let unit = unit_contents(executable, owner, &account);
    let changed = read_installed_unit()?.as_deref() != Some(unit.as_str());
    if changed {
        write_root_file(Path::new(UNIT_PATH), &unit)?;
    }
    match polkit_rules(&account) {
        Some(rules) => {
            if fs::read_to_string(POLKIT_RULES_PATH).ok().as_deref() != Some(rules.as_str()) {
                if let Err(error) = write_root_file(Path::new(POLKIT_RULES_PATH), &rules) {
                    // The service works without it; only recovery prompts.
                    eprintln!("Helper could not write its polkit rule: {error:#}");
                }
            }
        }
        None => remove_if_present(Path::new(POLKIT_RULES_PATH))?,
    }
    Ok(changed)
}

/// Written through a temporary file so a reader never sees half a unit.
fn write_root_file(path: &Path, contents: &str) -> Result<()> {
    let directory = path.parent().context("file has no parent directory")?;
    fs::create_dir_all(directory).with_context(|| format!("create {}", directory.display()))?;
    let temporary = path.with_extension("psa-new");
    fs::write(&temporary, contents).with_context(|| format!("write {}", temporary.display()))?;
    fs::set_permissions(&temporary, fs::Permissions::from_mode(0o644))
        .with_context(|| format!("secure {}", temporary.display()))?;
    fs::rename(&temporary, path).with_context(|| format!("replace {}", path.display()))
}

fn remove_if_present(path: &Path) -> Result<()> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error).with_context(|| format!("remove {}", path.display())),
    }
}

/// Package post-install: rewrites the unit for its owner and restarts it onto
/// the new binaries, so an upgrade asks for nothing.
fn upgrade_service() -> Result<()> {
    if !Path::new(SYSTEMD_RUNNING_PATH).exists() || !systemd_is_reachable() {
        return Ok(());
    }
    if !refresh_installed_files()? {
        return Ok(());
    }
    run_systemctl(&["daemon-reload"])?;
    run_systemctl(&["try-restart", SERVICE_NAME])
}

/// The unit's privileged `ExecStartPre=`: an older unit gets the current
/// sandbox at the next start, as reloading systemd mid-start is unsafe.
fn refresh_installed_files() -> Result<bool> {
    let Some(unit) = read_installed_unit()? else {
        return Ok(false);
    };
    let owner = installed_owner(&unit).context("the installed unit names no owner")?;
    let executable = std::env::current_exe().context("resolve helper executable path")?;
    ensure_root_owned(&executable)?;
    write_installed_files(&executable, owner)?;
    Ok(true)
}

fn uninstall_service() -> Result<()> {
    silence_systemctl(&["disable", "--now", SERVICE_NAME]);
    remove_if_present(Path::new(POLKIT_RULES_PATH))?;
    match fs::remove_file(UNIT_PATH) {
        Ok(()) => {}
        Err(error) if error.kind() == ErrorKind::NotFound => return Ok(()),
        Err(error) => return Err(error).with_context(|| format!("remove {UNIT_PATH}")),
    }
    run_systemctl(&["daemon-reload"])
}

/// False inside an rpm-ostree scriptlet, whose /etc is not the booted one.
fn systemd_is_reachable() -> bool {
    Command::new("systemctl")
        .args(["show", "--property=Version", "--value"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|status| status.success())
}

/// A package removal runs this twice, so the second `disable` reporting a unit
/// that is already gone is expected rather than something to print.
fn silence_systemctl(arguments: &[&str]) {
    let _ = Command::new("systemctl")
        .args(arguments)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

fn run_systemctl(arguments: &[&str]) -> Result<()> {
    let status = Command::new("systemctl")
        .args(arguments)
        .status()
        .with_context(|| format!("run systemctl {}", arguments.join(" ")))?;
    if !status.success() {
        bail!("systemctl {} failed with {status}", arguments.join(" "));
    }
    Ok(())
}

fn run_service() -> Result<()> {
    ensure_core_sha256_configured()?;
    let owner = owner_from_env()?;
    let executable = std::env::current_exe().context("resolve helper executable path")?;
    ensure_root_owned(&executable)?;
    let app_executable = executable
        .parent()
        .context("helper executable has no parent directory")?
        .join(APP_EXECUTABLE_NAME);
    let runtime = Runtime::new().context("create helper runtime")?;
    runtime.block_on(async move {
        let mut terminate = signal(SignalKind::terminate()).context("listen for SIGTERM")?;
        let mut interrupt = signal(SignalKind::interrupt()).context("listen for SIGINT")?;
        let shutdown = async move {
            tokio::select! {
                _ = terminate.recv() => {}
                _ = interrupt.recv() => {}
            }
        };
        let incoming = AuthorizedIncoming::bind(owner, app_executable)?;
        warp::serve(routes())
            .serve_incoming_with_graceful_shutdown(incoming, shutdown)
            .await;
        release_managed_core_on_shutdown();
        Ok(())
    })
}

/// Connections are filtered by peer credential rather than by the socket mode
/// alone: a supplementary group membership is enough to reach a `0660` socket,
/// and only the installing user's copy of the packaged app may drive a Core
/// that runs as root.
struct AuthorizedIncoming {
    listener: UnixListener,
    owner: Owner,
    app_executable: PathBuf,
    retry: Option<Pin<Box<Sleep>>>,
}

impl AuthorizedIncoming {
    fn bind(owner: Owner, app_executable: PathBuf) -> Result<Self> {
        if Path::new(SOCKET_PATH).exists() {
            fs::remove_file(SOCKET_PATH).with_context(|| format!("remove stale {SOCKET_PATH}"))?;
        }
        let listener =
            UnixListener::bind(SOCKET_PATH).with_context(|| format!("bind {SOCKET_PATH}"))?;
        fs::set_permissions(SOCKET_PATH, fs::Permissions::from_mode(SOCKET_MODE))
            .with_context(|| format!("secure {SOCKET_PATH}"))?;
        Ok(Self {
            listener,
            owner,
            app_executable,
            retry: None,
        })
    }
}

fn is_authorized_peer(stream: &UnixStream, owner: Owner, app_executable: &Path) -> bool {
    let Ok(credentials) = stream.peer_cred() else {
        return false;
    };
    if credentials.uid() != owner.uid {
        return false;
    }
    let pid = credentials.pid().unwrap_or(0);
    match verify_peer_process(Path::new("/proc"), pid, app_executable) {
        Ok(()) => true,
        Err(reason) => {
            log_message(format!("Helper refused a connection: {reason}"));
            false
        }
    }
}

impl Stream for AuthorizedIncoming {
    type Item = Result<UnixStream, Error>;

    /// hyper ends the whole server on the first accept error it is handed, so
    /// resource exhaustion is logged and retried after a pause instead.
    fn poll_next(
        mut self: Pin<&mut Self>,
        context: &mut TaskContext<'_>,
    ) -> Poll<Option<Self::Item>> {
        loop {
            if let Some(retry) = self.retry.as_mut() {
                match retry.as_mut().poll(context) {
                    Poll::Ready(()) => self.retry = None,
                    Poll::Pending => return Poll::Pending,
                }
            }
            match self.listener.poll_accept(context) {
                Poll::Ready(Ok((stream, _))) => {
                    if is_authorized_peer(&stream, self.owner, &self.app_executable) {
                        return Poll::Ready(Some(Ok(stream)));
                    }
                }
                Poll::Ready(Err(error)) => {
                    log_message(format!("Helper could not accept a connection: {error}"));
                    self.retry = Some(Box::pin(tokio::time::sleep(ACCEPT_RETRY_DELAY)));
                }
                Poll::Pending => return Poll::Pending,
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const OWNER: Owner = Owner {
        uid: 1000,
        gid: 1001,
    };

    fn account() -> OwnerAccount {
        OwnerAccount {
            name: "huayang".into(),
            home: PathBuf::from("/var/home/huayang"),
        }
    }

    fn installed_unit() -> String {
        unit_contents(
            Path::new("/usr/share/panorama-secure-access/panorama-secure-access-helper"),
            OWNER,
            &account(),
        )
    }

    #[test]
    fn parses_service_commands() {
        assert_eq!(service_command([]).unwrap(), ServiceCommand::Run);
        for (argument, command) in [
            ("install", ServiceCommand::Install),
            ("uninstall", ServiceCommand::Uninstall),
            ("upgrade", ServiceCommand::Upgrade),
            ("refresh", ServiceCommand::Refresh),
        ] {
            assert_eq!(
                service_command([OsString::from(argument)]).unwrap(),
                command
            );
        }
    }

    #[test]
    fn rejects_unknown_or_extra_service_commands() {
        assert!(service_command([OsString::from("unknown")]).is_err());
        assert!(service_command([OsString::from("install"), OsString::from("extra")]).is_err());
    }

    #[test]
    fn rejects_owner_ids_that_cannot_own_a_core() {
        assert_eq!(parse_owner_id(" 1000\n").unwrap(), 1000);
        assert!(parse_owner_id("0").is_err());
        assert!(parse_owner_id("-1").is_err());
        assert!(parse_owner_id("nobody").is_err());
    }

    #[test]
    fn unit_names_the_owner_and_the_helper_it_starts() {
        let unit = installed_unit();

        assert!(unit.contains("ExecStart=\"/usr/share/panorama-secure-access/panorama-secure-access-helper\"\n"));
        assert!(
            unit.contains("ExecStartPre=-+\"/usr/share/panorama-secure-access/panorama-secure-access-helper\" refresh\n")
        );
        assert!(unit.contains("Group=1001\n"));
        assert!(unit.contains("Environment=PSA_HELPER_OWNER_UID=1000\n"));
        assert!(unit.contains("Environment=PSA_HELPER_OWNER_GID=1001\n"));
        assert!(unit.contains("RuntimeDirectory=panorama-secure-access\n"));
        assert!(!unit.contains("network-online.target"));
    }

    #[test]
    fn unit_survives_reboots_and_recovers_from_crashes() {
        let unit = installed_unit();

        assert!(unit.contains("[Install]\nWantedBy=multi-user.target\n"));
        assert!(unit.contains("Restart=on-failure\n"));
        assert!(unit.contains("StartLimitBurst=5\n"));
        assert!(unit.contains("StartLimitIntervalSec=60\n"));
    }

    #[test]
    fn unit_confines_what_a_hijacked_core_could_change() {
        let unit = installed_unit();

        for directive in [
            "NoNewPrivileges=yes\n",
            "ProtectSystem=full\n",
            "ProtectHome=read-only\n",
            "ReadWritePaths=\"/var/home/huayang\"\n",
            "ProtectKernelModules=yes\n",
            "RestrictSUIDSGID=yes\n",
        ] {
            assert!(unit.contains(directive), "missing {directive}");
        }
        let read_only = unit
            .lines()
            .find_map(|line| line.strip_prefix("ReadOnlyPaths="))
            .unwrap();
        for path in [
            "-/var/home",
            "-/opt",
            "-/var/opt",
            "-/var/spool",
            "-/var/lib",
        ] {
            assert!(read_only.split(' ').any(|entry| entry == path), "{path}");
        }
        let capabilities: Vec<&str> = unit
            .lines()
            .find_map(|line| line.strip_prefix("CapabilityBoundingSet="))
            .unwrap()
            .split(' ')
            .collect();
        assert!(capabilities.contains(&"CAP_NET_ADMIN"));
        assert!(capabilities.contains(&"CAP_SYS_TIME"));
        for absent in [
            "CAP_SYS_ADMIN",
            "CAP_SYS_MODULE",
            "CAP_SYS_RAWIO",
            "CAP_MKNOD",
        ] {
            assert!(!capabilities.contains(&absent), "{absent}");
        }
    }

    #[test]
    fn unit_argument_survives_whitespace_and_specifiers() {
        assert_eq!(
            quoted_unit_argument(Path::new("/home/u/My Apps/100%/a\"b\\c")),
            r#""/home/u/My Apps/100%%/a\"b\\c""#
        );
    }

    #[test]
    fn reads_the_owner_and_version_back_out_of_an_installed_unit() {
        let unit = installed_unit();

        assert_eq!(installed_owner_uid(&unit), Some(1000));
        assert_eq!(installed_owner(&unit), Some(OWNER));
        assert!(unit.starts_with("# panorama-secure-access-helper-unit-version=2\n"));
        assert_eq!(installed_owner_uid("[Unit]\n"), None);
        assert_eq!(
            installed_owner("Environment=PSA_HELPER_OWNER_UID=0\n"),
            None
        );
    }

    #[test]
    fn polkit_rule_lets_only_the_owner_recover_this_unit() {
        let rules = polkit_rules(&account()).unwrap();

        assert!(rules.contains("action.id === \"org.freedesktop.systemd1.manage-units\""));
        assert!(rules.contains("action.lookup(\"unit\") === \"panorama-secure-access-helper.service\""));
        assert!(rules.contains("[\"start\", \"restart\", \"reset-failed\"]"));
        assert!(rules.contains("subject.user === \"huayang\""));
        assert!(rules.contains("subject.local && subject.active"));
        assert!(!rules.contains("stop"));
        assert!(!rules.contains("NOPASSWD"));
    }

    #[test]
    fn polkit_rule_is_withheld_for_names_it_cannot_quote() {
        for name in ["", "a\"b", "a b", "x\\y", "é"] {
            let account = OwnerAccount {
                name: name.into(),
                home: PathBuf::from("/home/x"),
            };
            assert_eq!(polkit_rules(&account), None, "{name}");
        }
    }

    #[test]
    fn looks_up_the_account_of_an_existing_user() {
        let uid = unsafe { libc::getuid() };
        let account = owner_account(uid).unwrap();
        assert!(!account.name.is_empty());
        assert!(account.home.is_absolute());
        assert!(owner_account(u32::MAX - 7).is_err());
    }
}
