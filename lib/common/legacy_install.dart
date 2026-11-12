import 'dart:io';

import 'package:flutter/foundation.dart';

import 'legacy_data.dart';
import 'linux_elevation.dart';
import 'print.dart';
import 'system.dart';

enum LegacyInstallKind { deb, rpm, ostree, macApp, androidPackage }

/// FlClash itself never counts: it is told apart by the display name or
/// packager our releases carried.
class LegacyInstall {
  final LegacyInstallKind kind;

  final String id;

  const LegacyInstall(this.kind, this.id);

  @override
  bool operator ==(Object other) =>
      other is LegacyInstall && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'LegacyInstall(${kind.name}, $id)';
}

const _legacyPackagePublisher = 'Panorama';
const _legacyHelperUnit = 'flclash-helper.service';
const _legacyHelperRules = '/etc/polkit-1/rules.d/49-flclash-helper.rules';
const _legacyMacApp = '/Applications/FlClash.app';

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class LegacyInstalls {
  final ProcessRunner run;
  final bool Function(String path) exists;

  LegacyInstalls({ProcessRunner? run, bool Function(String path)? exists})
    : run = run ?? Process.run,
      exists =
          exists ??
          ((path) =>
              FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound);

  Future<List<LegacyInstall>> findDesktop({
    required String operatingSystem,
    bool ostree = false,
  }) async {
    try {
      switch (operatingSystem) {
        case 'linux':
          return await _findLinux(ostree: ostree);
        case 'macos':
          return await _findMacOS();
      }
    } catch (error) {
      commonPrint.log('legacy install lookup failed: $error');
    }
    return const [];
  }

  Future<List<LegacyInstall>> _findLinux({required bool ostree}) async {
    if (exists('/usr/bin/dpkg-query')) {
      for (final name in const ['flclash', 'FlClash']) {
        final result = await run('dpkg-query', [
          '-W',
          r'-f=${Status}|${Maintainer}',
          name,
        ]);
        final output = result.stdout.toString();
        if (result.exitCode == 0 &&
            output.contains('install ok installed') &&
            output.contains(_legacyPackagePublisher)) {
          return [LegacyInstall(LegacyInstallKind.deb, name)];
        }
      }
    }
    if (exists('/usr/bin/rpm')) {
      final result = await run('rpm', ['-q', '--qf', '%{PACKAGER}', 'FlClash']);
      if (result.exitCode == 0 &&
          result.stdout.toString().contains(_legacyPackagePublisher)) {
        return [
          LegacyInstall(
            ostree ? LegacyInstallKind.ostree : LegacyInstallKind.rpm,
            'FlClash',
          ),
        ];
      }
    }
    return const [];
  }

  Future<List<LegacyInstall>> _findMacOS() async {
    const plist = '$_legacyMacApp/Contents/Info.plist';
    if (!exists(plist)) {
      return const [];
    }
    Future<String> read(String key) async {
      final result = await run('plutil', ['-extract', key, 'raw', plist]);
      return result.exitCode == 0 ? result.stdout.toString().trim() : '';
    }

    final ours =
        await read('CFBundleName') == 'Panorama Secure Access' &&
        await read('CFBundleIdentifier') == legacyBundleId;
    return ours
        ? const [LegacyInstall(LegacyInstallKind.macApp, _legacyMacApp)]
        : const [];
  }

  /// The legacy Helper goes first so a running one stops holding the TUN.
  @visibleForTesting
  static String linuxRemovalScript(LegacyInstall install) {
    final package = install.id;
    final remove = switch (install.kind) {
      LegacyInstallKind.deb => 'dpkg -r $package',
      LegacyInstallKind.rpm => 'rpm -e $package',
      LegacyInstallKind.ostree => 'rpm-ostree uninstall $package',
      _ => throw ArgumentError.value(install, 'install'),
    };
    return [
      'systemctl disable --now $_legacyHelperUnit >/dev/null 2>&1',
      'rm -f /etc/systemd/system/$_legacyHelperUnit $_legacyHelperRules',
      'systemctl daemon-reload >/dev/null 2>&1',
      remove,
    ].join('; ');
  }

  Future<bool> remove(LegacyInstall install) async {
    switch (install.kind) {
      case LegacyInstallKind.deb:
      case LegacyInstallKind.rpm:
      case LegacyInstallKind.ostree:
        return linuxElevation.elevate([
          '/bin/sh',
          '-c',
          linuxRemovalScript(install),
        ]);
      case LegacyInstallKind.macApp:
        final result = await run('osascript', [
          '-e',
          'tell application "Finder" to delete POSIX file "${install.id}"',
        ]);
        return result.exitCode == 0;
      case LegacyInstallKind.androidPackage:
        return false;
    }
  }
}

const legacyAndroidPackages = [legacyBundleId, legacyBetaPackage];

final legacyInstalls = LegacyInstalls();

Future<List<LegacyInstall>> findLegacyDesktopInstalls() {
  return legacyInstalls.findDesktop(
    operatingSystem: Platform.operatingSystem,
    ostree: system.isOstree,
  );
}
