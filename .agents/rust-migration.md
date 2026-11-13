# Incremental Rust Migration

Logic moves from Dart into `plugins/rust_api` one independent module at a time. Flutter stays the UI, the mihomo Go
core stays the core, and the platform adapters (Android `VpnService`, the Windows and Linux Helper, macOS setuid Core,
`plugins/proxy`) stay native. No new FFI framework: every module is a `rust/src/<module>/` crate module behind a thin
`rust/src/api/<module>.rs`, as `.agents/architecture.md` describes.

## Per-module procedure

1. Implement the module in Rust with unit tests (`cargo test` in `plugins/rust_api/rust`).
2. Route the existing Dart entry points to it when `RustLib` is initialized, keeping the old Dart code as a fallback
   and as the reference.
3. Add a parity test that loads the library (`test/helpers/rust_native.dart`) and compares Rust with the Dart
   reference, including generated inputs. Differences are either fixed or written down as intended.
4. Compare performance against the Dart path the app actually took (for work run off the UI isolate, `Isolate.run`).
5. Ship to beta. Delete the Dart fallback only after the user confirms the beta on every platform.

One module per pull request, into `beta`; `main` only with the user's authorization.

## Order

| Stage | Module | State |
|---|---|---|
| 1 | Config validation: CIDR, host, listen address, port range, TUN route subtraction (`netcfg`) | Rust primary, Dart fallback |
| 2 | Core process state machine (desktop lifecycle convergence in `lib/core/desktop/`) | Not started |
| 3 | DNS and IPv4/IPv6 diagnosis | Waits on the network diagnosis page in Dart |
| 4 | Network recovery after TUN or interface changes | Waits on stage 3 |
| 5 | System service install and legacy install migration (`legacy_install.dart`, `legacy_data.dart`) | Waits on device tests of the brand migration |

Stages 3 to 5 overlap code that is still changing in Dart; start one only once its Dart version has been tested on
devices, so the Rust port is not chasing a moving reference.
