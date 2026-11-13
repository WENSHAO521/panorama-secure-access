import 'package:rust_api/install.dart' as native;
import 'package:rust_api/install.dart' show DataCandidate, LegacyPackageKind;

export 'package:rust_api/install.dart' show DataCandidate, LegacyPackageKind;

const legacyBundleId = 'com.follow.clash';

List<String> legacyDataDirectories({
  required String operatingSystem,
  required Map<String, String> environment,
}) => native.legacyDataDirectories(
  operatingSystem: operatingSystem,
  environment: environment,
);

int? pickImportSource({
  required bool targetHasData,
  required bool targetEmpty,
  required List<DataCandidate> candidates,
}) => native.pickImportSource(
  targetHasData: targetHasData,
  targetEmpty: targetEmpty,
  candidates: candidates,
);

bool isTransientEntry(String name, String executableName) =>
    native.isTransientEntry(name: name, executableName: executableName);

/// FlClash itself carries another maintainer, so it never counts.
bool isLegacyDebStatus(String output) =>
    native.isLegacyDebStatus(output: output);

bool isLegacyRpmPackager(String output) =>
    native.isLegacyRpmPackager(output: output);

bool isLegacyMacBundle(String bundleName, String bundleIdentifier) =>
    native.isLegacyMacBundle(
      bundleName: bundleName,
      bundleIdentifier: bundleIdentifier,
    );

/// The script runs as root, so a package name earlier releases never used
/// gets null rather than a script.
String? linuxRemovalScript(LegacyPackageKind kind, String package) =>
    native.linuxRemovalScript(kind: kind, package: package);
