import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:rust_api/install.dart' as native;
import 'package:rust_api/install.dart' show DataCandidate, LegacyPackageKind;
import 'package:rust_api/rust_api.dart' show isRustLibInitialized;

export 'package:rust_api/install.dart' show DataCandidate, LegacyPackageKind;

// The dart* functions are the reference for `install` in rust_api, and the
// fallback wherever the Rust library is not loaded, which includes the
// bootstrap code that runs before RustLib.init.

const legacyBundleId = 'com.follow.clash';

const _legacyPublisher = 'Panorama';
const _legacyHelperUnit = 'flclash-helper.service';
const _legacyHelperRules = '/etc/polkit-1/rules.d/49-flclash-helper.rules';

List<String> legacyDataDirectories({
  required String operatingSystem,
  required Map<String, String> environment,
}) => isRustLibInitialized
    ? native.legacyDataDirectories(
        operatingSystem: operatingSystem,
        environment: environment,
      )
    : dartLegacyDataDirectories(operatingSystem, environment);

int? pickImportSource({
  required bool targetHasData,
  required bool targetEmpty,
  required List<DataCandidate> candidates,
}) => isRustLibInitialized
    ? native.pickImportSource(
        targetHasData: targetHasData,
        targetEmpty: targetEmpty,
        candidates: candidates,
      )
    : dartPickImportSource(targetHasData, targetEmpty, candidates);

bool isTransientEntry(String name, String executableName) =>
    isRustLibInitialized
    ? native.isTransientEntry(name: name, executableName: executableName)
    : dartIsTransientEntry(name, executableName);

/// FlClash itself carries another maintainer, so it never counts.
bool isLegacyDebStatus(String output) => isRustLibInitialized
    ? native.isLegacyDebStatus(output: output)
    : dartIsLegacyDebStatus(output);

bool isLegacyRpmPackager(String output) => isRustLibInitialized
    ? native.isLegacyRpmPackager(output: output)
    : dartIsLegacyRpmPackager(output);

bool isLegacyMacBundle(String bundleName, String bundleIdentifier) =>
    isRustLibInitialized
    ? native.isLegacyMacBundle(
        bundleName: bundleName,
        bundleIdentifier: bundleIdentifier,
      )
    : dartIsLegacyMacBundle(bundleName, bundleIdentifier);

/// The script runs as root, so a package name earlier releases never used
/// gets null rather than a script.
String? linuxRemovalScript(LegacyPackageKind kind, String package) =>
    isRustLibInitialized
    ? native.linuxRemovalScript(kind: kind, package: package)
    : dartLinuxRemovalScript(kind, package);

String _join(p.Context context, List<String> parts) =>
    context.joinAll(parts.where((part) => part.isNotEmpty));

@visibleForTesting
List<String> dartLegacyDataDirectories(
  String operatingSystem,
  Map<String, String> environment,
) {
  final home = environment['HOME'] ?? environment['USERPROFILE'] ?? '';
  switch (operatingSystem) {
    case 'linux':
      final dataHome = environment['XDG_DATA_HOME'];
      final base = dataHome != null && dataHome.isNotEmpty
          ? dataHome
          : _join(p.posix, [home, '.local', 'share']);
      return [
        _join(p.posix, [base, legacyBundleId]),
        _join(p.posix, [base, 'FlClash']),
      ];
    case 'macos':
      return [
        _join(p.posix, [
          home,
          'Library',
          'Application Support',
          legacyBundleId,
        ]),
      ];
    case 'windows':
      final appData = environment['APPDATA'];
      if (appData == null || appData.isEmpty) {
        return const [];
      }
      return [
        _join(p.windows, [appData, 'com.follow', 'clash']),
      ];
  }
  return const [];
}

@visibleForTesting
int? dartPickImportSource(
  bool targetHasData,
  bool targetEmpty,
  List<DataCandidate> candidates,
) {
  if (targetHasData || !targetEmpty) {
    return null;
  }
  final index = candidates.indexWhere(
    (candidate) => !candidate.sameAsTarget && candidate.hasUserData,
  );
  return index < 0 ? null : index;
}

@visibleForTesting
bool dartIsTransientEntry(String name, String executableName) =>
    name == 'FlClash.lock' ||
    name == 'restore' ||
    name == '$executableName.lock';

@visibleForTesting
bool dartIsLegacyDebStatus(String output) =>
    output.contains('install ok installed') &&
    output.contains(_legacyPublisher);

@visibleForTesting
bool dartIsLegacyRpmPackager(String output) =>
    output.contains(_legacyPublisher);

@visibleForTesting
bool dartIsLegacyMacBundle(String bundleName, String bundleIdentifier) =>
    bundleName == 'Panorama Secure Access' &&
    bundleIdentifier == legacyBundleId;

@visibleForTesting
String? dartLinuxRemovalScript(LegacyPackageKind kind, String package) {
  if (package != 'flclash' && package != 'FlClash') {
    return null;
  }
  final remove = switch (kind) {
    LegacyPackageKind.deb => 'dpkg -r $package',
    LegacyPackageKind.rpm => 'rpm -e $package',
    LegacyPackageKind.ostree => 'rpm-ostree uninstall $package',
  };
  return [
    'systemctl disable --now $_legacyHelperUnit >/dev/null 2>&1',
    'rm -f /etc/systemd/system/$_legacyHelperUnit $_legacyHelperRules',
    'systemctl daemon-reload >/dev/null 2>&1',
    remove,
  ].join('; ');
}
