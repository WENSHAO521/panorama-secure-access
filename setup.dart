import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'tool/release_version.dart';

const _allTargets = <String, String>{
  'android': 'apk',
  'linux': 'deb,appimage,rpm',
  'macos': 'dmg',
  'windows': 'exe,zip',
};

const _androidFlutterTarget = {
  'arm': 'android-arm',
  'arm64': 'android-arm64',
  'amd64': 'android-x64',
};

const _hostPlatform = {
  'linux': 'linux',
  'macos': 'macos',
  'windows': 'windows',
};

Future<void> main(List<String> args) async {
  final parser = createSetupArgParser();

  if (args.contains('--help') || args.contains('-h')) {
    _showHelp(parser);
    exit(0);
  }

  final results = parser.parse(args);
  final rest = results.rest;

  final hostOs = Platform.operatingSystem;
  final host = _hostPlatform[hostOs];
  if (host == null) {
    stderr.writeln('Unsupported host platform: $hostOs');
    exit(1);
  }

  final platform = rest.isNotEmpty ? rest.first : host;

  if (platform != host && platform != 'android') {
    stderr.writeln(
      'Cannot build "$platform" on $hostOs. Allowed: $host, android',
    );
    _showHelp(parser);
    exit(1);
  }

  final env = results['env'] as String;
  final releaseTag = results['release-tag'] as String?;
  final rootDir = Directory.current.path;
  final ReleaseVersion? release;
  try {
    release = releaseTag == null
        ? null
        : ReleaseVersion.parse(
            releaseTag,
            buildTime: DateTime.fromMillisecondsSinceEpoch(
              int.parse(results['build-time'] as String) * 1000,
              isUtc: true,
            ),
            runNumber: int.parse(results['run-number'] as String),
          );
  } on FormatException catch (error) {
    stderr.writeln('Invalid release version: ${error.message}');
    exit(1);
  }
  final skipped = packagesNotBuildingAssets(
    File(p.join(rootDir, 'pubspec.yaml')).readAsStringSync(),
  );
  if (skipped.isNotEmpty) {
    stderr.writeln(
      'pubspec.yaml sets hooks.user_defines.<package>.build_assets: false '
      'for ${skipped.join(', ')}; a package built this way would ship '
      'whatever is left in libclash/ and no Rust library. '
      'Restore "build_assets: true".',
    );
    exit(1);
  }
  final arch = _detectArch();
  final targets = createPackageTargets(platform, results['targets']);
  final androidArch = results['arch'] as String?;
  final verbose = results['verbose'] as bool;

  final exitCode = await _package(
    platform,
    env,
    targets,
    rootDir,
    arch,
    release: release,
    androidArch: androidArch,
    verbose: verbose,
  );
  exit(exitCode);
}

ArgParser createSetupArgParser() {
  return ArgParser()
    ..addOption(
      'env',
      defaultsTo: 'pre',
      allowed: ['dev', 'pre', 'stable'],
      help: 'Application environment',
    )
    ..addOption(
      'release-tag',
      valueHelp: 'v1.2.3-beta.4',
      help: 'Release tag the build is published under',
    )
    ..addOption(
      'build-time',
      valueHelp: 'unix seconds',
      defaultsTo: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      help: 'Time the build numbers of --release-tag derive from',
    )
    ..addOption(
      'run-number',
      defaultsTo: Platform.environment['GITHUB_RUN_NUMBER'] ?? '0',
      help: 'CI run number, the last field of the Windows file version',
    )
    ..addOption(
      'targets',
      valueHelp: 'exe,zip,dmg,apk,...',
      help: 'Package targets (default: all for platform)',
    )
    ..addOption(
      'arch',
      valueHelp: 'arm,arm64,amd64',
      allowed: ['arm', 'arm64', 'amd64'],
      help: 'Target architecture (Android only)',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose Flutter build output',
    );
}

List<String> createFlutterBuildArgs({
  required String platform,
  required bool verbose,
  ReleaseVersion? release,
}) {
  return [
    if (verbose) 'verbose',
    'dart-define-from-file=env.json',
    if (platform == 'android') 'split-per-abi',
    if (release != null) ...[
      'build-name=${release.buildName(platform)}',
      'build-number=${release.buildNumberFor(platform)}',
    ],
  ];
}

/// The invitation server and its public key come from the build's own
/// environment, so a build without them, a fork's included, asks for no code.
Map<String, String> createBuildEnvironment(
  String env, {
  String? releaseTag,
  Map<String, String> host = const {},
}) {
  String? fromHost(String name) =>
      host[name]?.trim().isNotEmpty == true ? host[name]!.trim() : null;
  return {
    'APP_ENV': env,
    'APP_RELEASE_TAG': ?releaseTag,
    'INVITE_API': ?fromHost('INVITE_API'),
    'INVITE_PUBLIC_KEY': ?fromHost('INVITE_PUBLIC_KEY'),
  };
}

/// Packages whose build hook `pubspec.yaml` turns into a no-op.
List<String> packagesNotBuildingAssets(String pubspec) {
  final document = loadYaml(pubspec);
  if (document is! Map) return const [];
  final defines = (document['hooks'] as Map?)?['user_defines'];
  if (defines is! Map) return const [];
  return [
    for (final MapEntry(:key, :value) in defines.entries)
      if (value is Map && value['build_assets'] == false) key.toString(),
  ]..sort();
}

String createPackageTargets(String platform, String? customTargets) {
  return customTargets ?? _allTargets[platform]!;
}

void _showHelp(ArgParser parser) {
  stderr.writeln('Usage: dart setup.dart [platform] [options]');
  stderr.writeln('Platform: current host platform (default) or android');
  stderr.writeln();
  stderr.writeln('Default package targets:');
  _allTargets.forEach((p, t) => stderr.writeln('  $p: $t'));
  stderr.writeln();
  stderr.writeln(parser.usage);
}

Future<int> _package(
  String platform,
  String env,
  String targets,
  String rootDir,
  String arch, {
  ReleaseVersion? release,
  String? androidArch,
  required bool verbose,
}) async {
  final file = File(p.join(rootDir, 'env.json'));
  await file.writeAsString(
    jsonEncode(
      createBuildEnvironment(
        env,
        releaseTag: release?.tag,
        host: Platform.environment,
      ),
    ),
  );

  final flutterBuildArgs = createFlutterBuildArgs(
    platform: platform,
    verbose: verbose,
    release: release,
  );
  final descriptionArgs = <String>[];
  if (platform != 'android') {
    descriptionArgs.addAll(['--description', arch]);
  }

  final depExit = await _ensureDependencies(platform);
  if (depExit != 0) return depExit;

  final activateResult = await Process.run('dart', [
    'pub',
    'global',
    'activate',
    '-s',
    'git',
    'https://github.com/chen08209/flutter_distributor.git',
    '--git-ref',
    'v0.6.11-flclash.4',
    '--git-path',
    'packages/flutter_distributor',
  ]);
  if (activateResult.exitCode != 0) {
    stderr.write(activateResult.stderr);
    return activateResult.exitCode;
  }

  // flutter_distributor reads the installer and package versions from
  // pubspec.yaml alone, so the release's version goes there for this build.
  final pubspec = File(p.join(rootDir, 'pubspec.yaml'));
  final originalPubspec = pubspec.readAsStringSync();
  if (release != null) {
    pubspec.writeAsStringSync(
      withPubspecVersion(originalPubspec, release.pubspecVersion(platform)),
    );
  }
  final int exitCode;
  try {
    exitCode = await _runDistributor(
      platform,
      targets,
      androidArch,
      flutterBuildArgs,
      descriptionArgs,
    );
  } finally {
    if (release != null) pubspec.writeAsStringSync(originalPubspec);
  }
  if (exitCode != 0 || platform != 'linux' || !targets.contains('appimage')) {
    return exitCode;
  }
  return _dropBundledRuntimeLibraries(p.join(rootDir, 'dist'), arch);
}

Future<int> _runDistributor(
  String platform,
  String targets,
  String? androidArch,
  List<String> flutterBuildArgs,
  List<String> descriptionArgs,
) async {
  final process = await Process.start(
    'flutter_distributor',
    [
      'package',
      '--skip-clean',
      '--platform',
      platform,
      '--targets',
      targets,
      if (androidArch != null)
        '--build-target-platform=${_androidFlutterTarget[androidArch]!}',
      if (flutterBuildArgs.isNotEmpty)
        '--flutter-build-args=${flutterBuildArgs.join(',')}',
      ...descriptionArgs,
    ],
    includeParentEnvironment: true,
    runInShell: Platform.isWindows,
  );

  process.stdout.listen((data) {
    stdout.write(utf8.decode(data));
  });
  process.stderr.listen((data) {
    stderr.write(utf8.decode(data));
  });
  return process.exitCode;
}

/// The packager bundles every library the plugins link, the C++ runtime
/// included. Run before the system's, an older runtime than the host's Mesa
/// needs leaves EGL without a driver and the window black (FlClash#2946).
const appImageExcludedLibraries = {'libstdc++.so.6', 'libgcc_s.so.1'};

Future<int> _dropBundledRuntimeLibraries(String distDir, String arch) async {
  final dist = Directory(distDir);
  if (!dist.existsSync()) return 0;
  final images = dist
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.AppImage'));
  for (final image in images) {
    final work = await Directory.systemTemp.createTemp('appimage');
    try {
      final extract = await Process.run(image.absolute.path, [
        '--appimage-extract',
      ], workingDirectory: work.path);
      if (extract.exitCode != 0) {
        stderr.write(extract.stderr);
        return extract.exitCode;
      }
      final appDir = p.join(work.path, 'squashfs-root');
      final bundled = appImageExcludedLibraries
          .map((name) => File(p.join(appDir, 'usr', 'lib', name)))
          .where((file) => file.existsSync())
          .toList();
      if (bundled.isEmpty) continue;
      for (final file in bundled) {
        file.deleteSync();
      }
      stdout.writeln(
        'Dropped ${bundled.map((file) => p.basename(file.path)).join(', ')} '
        'from ${p.basename(image.path)}',
      );
      final pack = await Process.run(
        'appimagetool',
        ['--no-appstream', appDir, image.absolute.path],
        environment: {'ARCH': appImageArchName(arch)},
      );
      if (pack.exitCode != 0) {
        stderr.write(pack.stderr);
        return pack.exitCode;
      }
    } finally {
      work.deleteSync(recursive: true);
    }
  }
  return 0;
}

String _detectArch() {
  if (Platform.isWindows) {
    final pa = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'AMD64';
    return pa.toUpperCase() == 'ARM64' ? 'arm64' : 'amd64';
  }
  final result = Process.runSync('uname', ['-m']);
  final machine = (result.stdout as String).trim();
  if (machine == 'aarch64') return 'arm64';
  if (machine == 'x86_64') return 'amd64';
  return machine;
}

Future<bool> _hasCommand(String cmd) async {
  final which = Platform.isWindows ? 'where' : 'command';
  final args = Platform.isWindows ? [cmd] : ['-v', cmd];
  final result = await Process.run(which, args);
  return result.exitCode == 0;
}

Future<int> _ensureDependencies(String platform) async {
  switch (platform) {
    case 'macos':
      return _ensureMacosDependencies();
    case 'linux':
      return _ensureLinuxDependencies();
    default:
      return 0;
  }
}

Future<int> _ensureMacosDependencies() async {
  if (await _hasCommand('appdmg')) {
    stdout.writeln('appdmg already installed, skipping.');
    return 0;
  }
  stdout.writeln('Installing appdmg (DMG creator)...');
  final result = await Process.run('npm', ['install', '-g', 'appdmg']);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
  }
  return result.exitCode;
}

Future<int> _ensureLinuxDependencies() async {
  const pkgGroups = <List<String>>[
    ['ninja-build', 'libgtk-3-dev'],
    ['libayatana-appindicator3-dev'],
    ['libsecret-1-dev'],
    ['locate'],
    ['rpm', 'patchelf'],
    ['libfuse2'],
  ];

  final missingGroups = <List<String>>[];
  for (final group in pkgGroups) {
    final missingPkgs = <String>[];
    for (final pkg in group) {
      if (!await _isDebianPackageInstalled(pkg)) {
        missingPkgs.add(pkg);
      }
    }
    if (missingPkgs.isNotEmpty) {
      missingGroups.add(missingPkgs);
    }
  }

  if (missingGroups.isEmpty) {
    stdout.writeln('All Linux build dependencies already installed, skipping.');
  } else {
    stdout.writeln('Updating apt package lists...');
    final updateExit = await _runLinuxDependencyCommand([
      'apt-get',
      'update',
      '-y',
    ]);
    if (updateExit != 0) {
      stderr.writeln(
        'apt-get update exited with $updateExit; continuing and verifying '
        'dependency installation directly.',
      );
    }

    for (final missingPkgs in missingGroups) {
      stdout.writeln(
        'Installing Linux build dependencies: ${missingPkgs.join(', ')}...',
      );
      final installExit = await _installLinuxPackages(missingPkgs);
      if (installExit != 0) return installExit;
    }
  }

  const appimagetool = '/usr/local/bin/appimagetool';
  if (File(appimagetool).existsSync()) {
    stdout.writeln('appimagetool already installed, skipping.');
    return 0;
  }
  stdout.writeln('Downloading appimagetool...');
  final downloadName =
      'appimagetool-${appImageToolArch(_detectArch())}.AppImage';
  final dlResult = await Process.run('wget', [
    '-O',
    appimagetool,
    'https://github.com/AppImage/AppImageKit/releases/download/continuous/$downloadName',
  ]);
  if (dlResult.exitCode != 0) {
    stderr.write(dlResult.stderr);
    return dlResult.exitCode;
  }
  await Process.run('chmod', ['+x', appimagetool]);
  return 0;
}

/// appimagetool reads aarch64 only by its ELF name in `ARCH`.
String appImageArchName(String arch) {
  return arch == 'arm64' ? 'arm_aarch64' : 'x86_64';
}

String appImageToolArch(String arch) {
  return arch == 'arm64' ? 'aarch64' : 'x86_64';
}

/// Ubuntu 24.04 ships libfuse2 under its time64 name, which `dpkg -s libfuse2` cannot see.
const _debianPackageAliases = <String, List<String>>{
  'libfuse2': ['libfuse2t64'],
};

Future<bool> _isDebianPackageInstalled(String pkg) async {
  for (final name in [pkg, ...?_debianPackageAliases[pkg]]) {
    final result = await Process.run('dpkg', ['-s', name]);
    if (result.exitCode == 0 &&
        (result.stdout as String).contains('Status: install ok installed')) {
      return true;
    }
  }
  return false;
}

Future<bool> _areDebianPackagesInstalled(List<String> pkgs) async {
  for (final pkg in pkgs) {
    if (!await _isDebianPackageInstalled(pkg)) {
      return false;
    }
  }
  return true;
}

Future<int> _installLinuxPackages(List<String> pkgs) async {
  final exitCode = await _runLinuxDependencyCommand([
    'apt-get',
    'install',
    '-y',
    ...pkgs,
  ]);
  if (exitCode == 0) return 0;

  if (await _areDebianPackagesInstalled(pkgs)) {
    stderr.writeln(
      'apt-get install exited with $exitCode, but all requested packages are '
      'installed; continuing.',
    );
    return 0;
  }

  return exitCode;
}

Future<int> _runLinuxDependencyCommand(List<String> command) async {
  final sudoCommand = [
    'env',
    'DEBIAN_FRONTEND=noninteractive',
    'NEEDRESTART_MODE=a',
    ...command,
  ];
  stdout.writeln('exec: sudo ${sudoCommand.join(' ')}');
  final result = await Process.start('sudo', sudoCommand);
  result.stdout.listen((data) {
    stdout.write(utf8.decode(data));
  });
  result.stderr.listen((data) {
    stderr.write(utf8.decode(data));
  });
  final exitCode = await result.exitCode;
  if (exitCode != 0) {
    stderr.writeln('Linux dependency command failed with exit code $exitCode.');
  }
  return exitCode;
}
