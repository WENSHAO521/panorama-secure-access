import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'constant.dart';
import 'linux_elevation.dart';
import 'print.dart';
import 'protocol.dart';
import 'system.dart';

/// Windows has a real uninstaller, so it never shows the in-app action.
enum AppInstallKind { deb, rpm, ostree, appImage, macApp }

typedef DetachedStarter =
    Future<void> Function(String executable, List<String> arguments);

typedef ElevatedRunner = Future<bool> Function(List<String> command);

const _helperRulesPath = '/etc/polkit-1/rules.d/49-$appHelperService.rules';
const _packageNamePattern = r'^[\w.+-]+$';

class AppUninstall {
  final ProcessRunner run;
  final ElevatedRunner elevate;
  final DetachedStarter startDetached;
  final Map<String, String> environment;
  final String executable;
  final String operatingSystem;
  final bool appImage;
  final bool ostree;

  AppUninstall({
    ProcessRunner? run,
    ElevatedRunner? elevate,
    DetachedStarter? startDetached,
    Map<String, String>? environment,
    String? executable,
    String? operatingSystem,
    bool? appImage,
    bool? ostree,
  }) : run = run ?? Process.run,
       elevate = elevate ?? linuxElevation.elevate,
       startDetached = startDetached ?? _startDetached,
       environment = environment ?? Platform.environment,
       executable = executable ?? Platform.resolvedExecutable,
       operatingSystem = operatingSystem ?? Platform.operatingSystem,
       appImage = appImage ?? system.isAppImage,
       ostree = ostree ?? system.isOstree;

  AppInstallKind? get kind {
    switch (operatingSystem) {
      case 'macos':
        return macBundle != null ? AppInstallKind.macApp : null;
      case 'linux':
        if (appImage) {
          return AppInstallKind.appImage;
        }
        if (p.isWithin('/opt/$appExecutableName', executable)) {
          return AppInstallKind.deb;
        }
        if (p.isWithin('/usr/share/$appExecutableName', executable)) {
          return ostree ? AppInstallKind.ostree : AppInstallKind.rpm;
        }
    }
    return null;
  }

  @visibleForTesting
  String? get macBundle {
    final bundle = p.dirname(p.dirname(p.dirname(executable)));
    return bundle.endsWith('.app') ? bundle : null;
  }

  String get _home => environment['HOME'] ?? '';

  @visibleForTesting
  List<String> userPaths({required bool deleteData}) {
    if (operatingSystem == 'macos') {
      final library = p.join(_home, 'Library');
      return [
        p.join(library, 'Caches', packageName),
        p.join(library, 'HTTPStorages', packageName),
        p.join(library, 'WebKit', packageName),
        p.join(library, 'Saved Application State', '$packageName.savedState'),
        if (deleteData) ...[
          p.join(library, 'Application Support', packageName),
          p.join(library, 'Preferences', '$packageName.plist'),
        ],
      ];
    }
    String xdg(String name, String fallback) {
      final value = environment[name];
      return value != null && value.isNotEmpty
          ? value
          : p.join(_home, fallback);
    }

    final dataHome = xdg('XDG_DATA_HOME', '.local/share');
    final appImageFile = environment['APPIMAGE'];
    return [
      p.join(xdg('XDG_CACHE_HOME', '.cache'), packageName),
      // launch_at_startup ignores XDG_CONFIG_HOME.
      p.join(_home, '.config', 'autostart', '$appName.desktop'),
      p.join(dataHome, 'applications', linuxUrlHandlerDesktopId),
      if (deleteData) p.join(dataHome, packageName),
      if (kind == AppInstallKind.appImage && appImageFile?.isNotEmpty == true)
        appImageFile!,
    ];
  }

  /// The Helper goes first so a running one stops holding the TUN, and its
  /// files go here because an rpm-ostree scriptlet cannot reach the booted /etc.
  @visibleForTesting
  static String linuxRemovalScript(AppInstallKind kind, String package) {
    final remove = switch (kind) {
      AppInstallKind.deb => 'dpkg -r $package',
      AppInstallKind.rpm => 'rpm -e $package',
      AppInstallKind.ostree => 'rpm-ostree uninstall $package',
      _ => throw ArgumentError.value(kind, 'kind'),
    };
    return [
      'systemctl disable --now $helperUnitName >/dev/null 2>&1',
      'rm -f $helperUnitPath $_helperRulesPath',
      'systemctl daemon-reload >/dev/null 2>&1',
      remove,
    ].join('; ');
  }

  /// Waits for this process to exit so its exit path cannot recreate the
  /// folders; cfprefsd would rewrite a deleted plist, hence `defaults delete`.
  @visibleForTesting
  static List<String> cleanupCommand(
    int pid,
    List<String> paths, {
    String? defaultsDomain,
  }) {
    final script = [
      r'pid=$1; shift; while kill -0 "$pid" 2>/dev/null; do sleep 0.2; done;',
      if (defaultsDomain != null)
        'defaults delete $defaultsDomain >/dev/null 2>&1;',
      r'rm -rf -- "$@"',
    ].join(' ');
    return ['-c', script, 'sh', '$pid', ...paths];
  }

  Future<String> _packageName(AppInstallKind kind) async {
    try {
      final deb = kind == AppInstallKind.deb;
      final result = deb
          ? await run('dpkg-query', ['-S', executable])
          : await run('rpm', ['-qf', '--queryformat', '%{NAME}', executable]);
      final output = result.stdout.toString().trim();
      final name = deb ? output.split(':').first.trim() : output;
      if (result.exitCode == 0 && RegExp(_packageNamePattern).hasMatch(name)) {
        return name;
      }
    } on ProcessException catch (error) {
      commonPrint.log('package lookup failed: $error');
    }
    return appExecutableName;
  }

  Future<bool> _removeInstall(AppInstallKind kind) async {
    switch (kind) {
      case AppInstallKind.appImage:
        return true;
      case AppInstallKind.macApp:
        final result = await run('osascript', [
          '-e',
          'tell application "Finder" to delete POSIX file "$macBundle"',
        ]);
        return result.exitCode == 0;
      case AppInstallKind.deb:
      case AppInstallKind.rpm:
      case AppInstallKind.ostree:
        final package = await _packageName(kind);
        return elevate(['/bin/sh', '-c', linuxRemovalScript(kind, package)]);
    }
  }

  Future<bool> uninstall({required bool deleteData}) async {
    final kind = this.kind;
    if (kind == null || !await _removeInstall(kind)) {
      return false;
    }
    final macOS = kind == AppInstallKind.macApp;
    await startDetached(
      '/bin/sh',
      cleanupCommand(
        pid,
        userPaths(deleteData: deleteData),
        defaultsDomain: macOS && deleteData ? packageName : null,
      ),
    );
    return true;
  }

  static Future<void> _startDetached(
    String executable,
    List<String> arguments,
  ) async {
    await Process.start(executable, arguments, mode: ProcessStartMode.detached);
  }
}

final appUninstall = system.isLinux || system.isMacOS ? AppUninstall() : null;
