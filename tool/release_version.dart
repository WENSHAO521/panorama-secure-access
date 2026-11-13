import 'dart:io';

/// The one version a release tag stands for, and what each platform's
/// packaging may carry of it.
///
/// Every number a store, installer or package manager compares derives from
/// the tag and the build time, so a beta and the stable release after it never
/// reuse or reverse a number. `pubspec.yaml` only names the last stable release.
class ReleaseVersion {
  ReleaseVersion._({
    required this.tag,
    required this.major,
    required this.minor,
    required this.patch,
    required this.betaNumber,
    required this.buildNumber,
    required this.runNumber,
  });

  /// [buildTime] orders builds for Android, macOS and Linux; [runNumber] is the
  /// only number small enough for the last field of a Windows file version.
  factory ReleaseVersion.parse(
    String tag, {
    required DateTime buildTime,
    required int runNumber,
  }) {
    final match = _tagPattern.firstMatch(tag);
    if (match == null) {
      throw FormatException('Not a release tag (vX.Y.Z or vX.Y.Z-beta.N)', tag);
    }
    if (runNumber < 0 || runNumber > maxWindowsField) {
      throw FormatException('Run number out of range', '$runNumber');
    }
    final parts = [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
    if (parts.any((part) => part > maxWindowsField)) {
      throw FormatException('Version field above $maxWindowsField', tag);
    }
    final beta = match.group(4);
    return ReleaseVersion._(
      tag: tag,
      major: parts[0],
      minor: parts[1],
      patch: parts[2],
      betaNumber: beta == null ? null : int.parse(beta),
      buildNumber: buildNumberAt(buildTime),
      runNumber: runNumber,
    );
  }

  static final _tagPattern = RegExp(
    r'^v(0|[1-9]\d{0,4})\.(0|[1-9]\d{0,4})\.(0|[1-9]\d{0,4})(?:-beta\.([1-9]\d{0,8}))?$',
  );

  /// The largest value of one field of a Windows `VS_FIXEDFILEINFO` version.
  static const maxWindowsField = 65535;

  /// Google Play's ceiling for `versionCode`, less the room Flutter's
  /// split-per-abi adds (ABI code × 1000, at most 4).
  static const maxAndroidVersionCode = 2100000000 - 4000;

  /// `yyyyMMdd` followed by the quarter hour of the day, 00–95, in UTC. Stays
  /// above every pubspec build number shipped so far (`yyyyMMdd01` style) for
  /// any later day, and below [maxAndroidVersionCode] until 2099.
  static int buildNumberAt(DateTime time) {
    final utc = time.toUtc();
    final quarter = (utc.hour * 60 + utc.minute) ~/ 15;
    final code = (utc.year * 10000 + utc.month * 100 + utc.day) * 100 + quarter;
    if (code > maxAndroidVersionCode) {
      throw FormatException('Build time past 2099', '$time');
    }
    return code;
  }

  final String tag;
  final int major;
  final int minor;
  final int patch;
  final int? betaNumber;
  final int buildNumber;
  final int runNumber;

  bool get isStable => betaNumber == null;

  String get core => '$major.$minor.$patch';

  /// What people see: the tag without its `v`.
  String get display => isStable ? core : '$core-beta.$betaNumber';

  /// Debian's `+0.beta.N` and RPM's equivalent sort below the stable `+<build>`
  /// of the same version and above every earlier version, which a `-beta`
  /// cannot do: dpkg would read it as a revision and RPM rejects the dash.
  String get linuxPackageVersion =>
      isStable ? '$core+$buildNumber' : '$core+0.beta.$betaNumber';

  String get windowsFileVersion => '$core.$runNumber';

  /// The `version:` the packager reads for [platform]. flutter_distributor
  /// writes it into the installer metadata and the package names.
  String pubspecVersion(String platform) => switch (platform) {
    'linux' => linuxPackageVersion,
    'windows' => display,
    'macos' => '$core+$buildNumber',
    _ => '$display+$buildNumber',
  };

  /// `--build-name` for [platform]. Apple only accepts dotted integers in
  /// `CFBundleShortVersionString`; the app itself shows [display] either way,
  /// from `APP_RELEASE_TAG`.
  String buildName(String platform) => platform == 'macos' ? core : display;

  /// `--build-number` for [platform]. Windows puts it in the 16-bit last field
  /// of the file version.
  int buildNumberFor(String platform) =>
      platform == 'windows' ? runNumber : buildNumber;

  Map<String, String> toOutputs() => {
    'tag': tag,
    'display': display,
    'core': core,
    'channel': isStable ? 'stable' : 'beta',
    'build_number': '$buildNumber',
    'windows_file_version': windowsFileVersion,
    'linux_package_version': linuxPackageVersion,
  };
}

/// Replaces the `version:` line of [pubspec], keeping everything else intact.
String withPubspecVersion(String pubspec, String version) {
  final pattern = RegExp(r'^version:.*$', multiLine: true);
  if (!pattern.hasMatch(pubspec)) {
    throw const FormatException('pubspec.yaml has no version line');
  }
  return pubspec.replaceFirst(pattern, 'version: $version');
}

/// Prints the version plan for a tag as `key=value` lines, for
/// `$GITHUB_OUTPUT`: `dart run tool/release_version.dart <tag> <unix seconds> <run number>`.
void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(
      'usage: dart run tool/release_version.dart <tag> <unix-seconds> <run>',
    );
    exit(64);
  }
  final ReleaseVersion version;
  try {
    version = ReleaseVersion.parse(
      args[0],
      buildTime: DateTime.fromMillisecondsSinceEpoch(
        int.parse(args[1]) * 1000,
        isUtc: true,
      ),
      runNumber: int.parse(args[2]),
    );
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exit(1);
  }
  version.toOutputs().forEach((key, value) => stdout.writeln('$key=$value'));
}
