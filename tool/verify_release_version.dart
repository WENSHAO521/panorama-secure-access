import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'release_version.dart';

/// Reads the version back out of what `dart setup.dart` built, so a package
/// that only carries the tag in its file name cannot be published:
/// `dart run tool/verify_release_version.dart <platform> <tag> <unix-seconds> <run>`.
Future<void> main(List<String> args) async {
  if (args.length != 4) {
    stderr.writeln(
      'usage: dart run tool/verify_release_version.dart '
      '<platform> <tag> <unix-seconds> <run>',
    );
    exit(64);
  }
  final platform = args[0];
  final version = ReleaseVersion.parse(
    args[1],
    buildTime: DateTime.fromMillisecondsSinceEpoch(
      int.parse(args[2]) * 1000,
      isUtc: true,
    ),
    runNumber: int.parse(args[3]),
  );
  final problems = await verifyBuild(platform, version, Directory.current);
  if (problems.isEmpty) {
    stdout.writeln('$platform packages carry ${version.display}.');
    return;
  }
  for (final problem in problems) {
    stderr.writeln('::error::$problem');
  }
  exit(1);
}

Future<List<String>> verifyBuild(
  String platform,
  ReleaseVersion version,
  Directory root,
) async {
  final problems = <String>[];
  final dist = Directory(p.join(root.path, 'dist'));
  final files = dist.existsSync()
      ? dist.listSync(recursive: true).whereType<File>().toList()
      : <File>[];
  final env = File(p.join(root.path, 'env.json'));
  if (!env.existsSync() ||
      (jsonDecode(env.readAsStringSync()) as Map)['APP_RELEASE_TAG'] !=
          version.tag) {
    problems.add('env.json does not define APP_RELEASE_TAG=${version.tag}');
  }
  switch (platform) {
    case 'android':
      await _verifyAndroid(files, version, problems);
    case 'windows':
      await _verifyWindows(root, files, version, problems);
    case 'macos':
      await _verifyMacos(root, files, version, problems);
    case 'linux':
      await _verifyLinux(root, files, version, problems);
    default:
      problems.add('Unknown platform $platform');
  }
  return problems;
}

void _expect(List<String> problems, String what, Object? actual, Object want) {
  if (actual != want) {
    problems.add('$what is "$actual", expected "$want"');
  }
}

/// The snapshot keeps `String.fromEnvironment` constants as one-byte string
/// data, so the tag shows up verbatim in the compiled Dart code.
void _expectEmbeddedTag(
  List<String> problems,
  String what,
  List<int>? bytes,
  String tag,
) {
  if (bytes == null) {
    problems.add('$what not found');
    return;
  }
  if (!_contains(bytes, ascii.encode(tag))) {
    problems.add('$what does not embed $tag');
  }
}

bool _contains(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}

Future<String> _run(String executable, List<String> args) async {
  final result = await Process.run(executable, args);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      args,
      '${result.stderr}',
      result.exitCode,
    );
  }
  return '${result.stdout}'.trim();
}

const _abiCodes = {'armeabi-v7a': 1, 'arm64-v8a': 2, 'x86_64': 4};

Future<void> _verifyAndroid(
  List<File> files,
  ReleaseVersion version,
  List<String> problems,
) async {
  final apks = files.where((file) => file.path.endsWith('.apk')).toList();
  if (apks.isEmpty) {
    problems.add('No APK in dist/');
    return;
  }
  final aapt = _findAapt();
  if (aapt == null) {
    problems.add('aapt not found under ANDROID_HOME/build-tools');
    return;
  }
  for (final apk in apks) {
    final name = p.basename(apk.path);
    final badging = await _run(aapt, ['dump', 'badging', apk.path]);
    final package = RegExp(
      r"versionCode='(\d+)' versionName='([^']*)'",
    ).firstMatch(badging);
    _expect(problems, '$name versionName', package?.group(2), version.display);
    final abi = _abiCodes.entries
        .where((entry) => name.contains(entry.key))
        .map((entry) => entry.value)
        .firstOrNull;
    final code = int.tryParse(package?.group(1) ?? '');
    _expect(
      problems,
      '$name versionCode',
      code,
      abi == null ? version.buildNumber : abi * 1000 + version.buildNumber,
    );
    final archive = ZipDecoder().decodeStream(InputFileStream(apk.path));
    final libapp = archive.files
        .where((entry) => entry.name.endsWith('/libapp.so'))
        .firstOrNull;
    _expectEmbeddedTag(
      problems,
      '$name libapp.so',
      libapp?.readBytes(),
      version.tag,
    );
  }
}

String? _findAapt() {
  final home =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (home == null) return null;
  final tools = Directory(p.join(home, 'build-tools'));
  if (!tools.existsSync()) return null;
  final versions = tools.listSync().whereType<Directory>().toList()
    ..sort((a, b) => b.path.compareTo(a.path));
  for (final dir in versions) {
    final aapt = File(p.join(dir.path, 'aapt'));
    if (aapt.existsSync()) return aapt.path;
  }
  return null;
}

Future<void> _verifyWindows(
  Directory root,
  List<File> files,
  ReleaseVersion version,
  List<String> problems,
) async {
  if (!files.any((file) => file.path.endsWith('-setup.exe'))) {
    problems.add('No setup .exe in dist/');
  }
  final release = Directory(p.join(root.path, 'build', 'windows'))
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            p.basename(file.path) == 'panorama-secure-access.exe' &&
            p.split(file.path).contains('Release'),
      )
      .firstOrNull;
  if (release == null) {
    problems.add('No Release panorama-secure-access.exe under build/windows');
    return;
  }
  final info = await _run('powershell', [
    '-NoProfile',
    '-Command',
    [
      "\$v = (Get-Item -LiteralPath '${release.path}').VersionInfo",
      "'{0}.{1}.{2}.{3}' -f \$v.FileMajorPart, \$v.FileMinorPart, "
          '\$v.FileBuildPart, \$v.FilePrivatePart',
      '\$v.ProductVersion',
    ].join('; '),
  ]);
  final lines = const LineSplitter().convert(info);
  _expect(
    problems,
    'exe file version',
    lines.firstOrNull,
    version.windowsFileVersion,
  );
  final product = lines.length > 1 ? lines[1] : '';
  if (product.split('+').first != version.display) {
    problems.add(
      'exe product version is "$product", expected '
      '"${version.display}"',
    );
  }
  _expectEmbeddedTag(
    problems,
    'data/app.so',
    _readIfExists(p.join(release.parent.path, 'data', 'app.so')),
    version.tag,
  );
}

Future<void> _verifyMacos(
  Directory root,
  List<File> files,
  ReleaseVersion version,
  List<String> problems,
) async {
  if (!files.any((file) => file.path.endsWith('.dmg'))) {
    problems.add('No .dmg in dist/');
  }
  final products = Directory(
    p.join(root.path, 'build', 'macos', 'Build', 'Products', 'Release'),
  );
  final app = products.existsSync()
      ? products
            .listSync()
            .whereType<Directory>()
            .where((dir) => dir.path.endsWith('.app'))
            .firstOrNull
      : null;
  if (app == null) {
    problems.add('No .app under build/macos/Build/Products/Release');
    return;
  }
  final plist = p.join(app.path, 'Contents', 'Info.plist');
  Future<String> read(String key) =>
      _run('plutil', ['-extract', key, 'raw', '-o', '-', plist]);
  _expect(
    problems,
    'CFBundleShortVersionString',
    await read('CFBundleShortVersionString'),
    version.core,
  );
  _expect(
    problems,
    'CFBundleVersion',
    await read('CFBundleVersion'),
    '${version.buildNumber}',
  );
  _expectEmbeddedTag(
    problems,
    'App.framework',
    _readIfExists(
      p.join(app.path, 'Contents', 'Frameworks', 'App.framework', 'App'),
    ),
    version.tag,
  );
}

Future<void> _verifyLinux(
  Directory root,
  List<File> files,
  ReleaseVersion version,
  List<String> problems,
) async {
  final debs = files.where((file) => file.path.endsWith('.deb'));
  final rpms = files.where((file) => file.path.endsWith('.rpm'));
  if (debs.isEmpty) problems.add('No .deb in dist/');
  if (rpms.isEmpty) problems.add('No .rpm in dist/');
  if (!files.any((file) => file.path.endsWith('.AppImage'))) {
    problems.add('No .AppImage in dist/');
  }
  for (final deb in debs) {
    _expect(
      problems,
      '${p.basename(deb.path)} Version',
      await _run('dpkg-deb', ['-f', deb.path, 'Version']),
      version.linuxPackageVersion,
    );
  }
  for (final rpm in rpms) {
    _expect(
      problems,
      '${p.basename(rpm.path)} Version',
      await _run('rpm', ['-qp', '--queryformat', '%{VERSION}', rpm.path]),
      version.linuxPackageVersion,
    );
  }
  final libapp = Directory(p.join(root.path, 'build', 'linux'))
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            p.basename(file.path) == 'libapp.so' &&
            p.split(file.path).contains('release'),
      )
      .firstOrNull;
  _expectEmbeddedTag(
    problems,
    'bundle libapp.so',
    libapp?.readAsBytesSync(),
    version.tag,
  );
}

List<int>? _readIfExists(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsBytesSync() : null;
}
