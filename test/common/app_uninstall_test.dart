import 'dart:io';

import 'package:fl_clash/common/app_uninstall.dart';
import 'package:fl_clash/common/system.dart' show ProcessRunner;
import 'package:flutter_test/flutter_test.dart';

const _home = '/var/home/rana';

AppUninstall _linux({
  String executable =
      '/usr/share/panorama-secure-access/panorama-secure-access',
  Map<String, String> environment = const {'HOME': _home},
  bool appImage = false,
  bool ostree = false,
  ProcessRunner? run,
  ElevatedRunner? elevate,
  DetachedStarter? startDetached,
}) {
  return AppUninstall(
    operatingSystem: 'linux',
    executable: executable,
    environment: environment,
    appImage: appImage,
    ostree: ostree,
    run:
        run ??
        (_, _) async => ProcessResult(0, 0, 'panorama-secure-access', ''),
    elevate: elevate ?? (_) async => true,
    startDetached: startDetached ?? (_, _) async {},
  );
}

void main() {
  group('kind', () {
    test('tells the package forms apart by install location', () {
      expect(
        _linux(
          executable: '/opt/panorama-secure-access/panorama-secure-access',
        ).kind,
        AppInstallKind.deb,
      );
      expect(_linux().kind, AppInstallKind.rpm);
      expect(_linux(ostree: true).kind, AppInstallKind.ostree);
      expect(_linux(appImage: true).kind, AppInstallKind.appImage);
      expect(_linux(executable: '/home/dev/build/app').kind, isNull);
    });

    test('a macOS bundle is recognised from its executable', () {
      final uninstall = AppUninstall(
        operatingSystem: 'macos',
        executable:
            '/Applications/Panorama Secure Access.app/Contents/MacOS/Panorama Secure Access',
        environment: const {},
        appImage: false,
        ostree: false,
      );
      expect(uninstall.kind, AppInstallKind.macApp);
      expect(uninstall.macBundle, '/Applications/Panorama Secure Access.app');
    });

    test('Windows keeps its own uninstaller', () {
      final uninstall = AppUninstall(
        operatingSystem: 'windows',
        executable: r'C:\Program Files\Panorama Secure Access\app.exe',
        environment: const {},
        appImage: false,
        ostree: false,
      );
      expect(uninstall.kind, isNull);
    });
  });

  group('userPaths', () {
    test('keeps subscriptions unless asked and always drops the cache', () {
      final paths = _linux().userPaths(deleteData: false);
      expect(paths, [
        '$_home/.cache/com.panoramasg.secureaccess',
        '$_home/.config/autostart/Panorama Secure Access.desktop',
        '$_home/.local/share/applications/panorama-secure-access-url-handler.desktop',
      ]);
      expect(
        _linux().userPaths(deleteData: true),
        contains('$_home/.local/share/com.panoramasg.secureaccess'),
      );
    });

    test('follows XDG overrides and removes the AppImage file', () {
      final paths = _linux(
        appImage: true,
        environment: const {
          'HOME': _home,
          'XDG_DATA_HOME': '/data',
          'XDG_CACHE_HOME': '/cache',
          'APPIMAGE': '/var/home/rana/Apps/psa.AppImage',
        },
      ).userPaths(deleteData: true);
      expect(paths, contains('/cache/com.panoramasg.secureaccess'));
      expect(paths, contains('/data/com.panoramasg.secureaccess'));
      expect(paths, contains('/var/home/rana/Apps/psa.AppImage'));
    });

    test('macOS settings live in Preferences and go only with the data', () {
      final uninstall = AppUninstall(
        operatingSystem: 'macos',
        executable: '/Applications/P.app/Contents/MacOS/P',
        environment: const {'HOME': '/Users/r'},
        appImage: false,
        ostree: false,
      );
      const plist =
          '/Users/r/Library/Preferences/com.panoramasg.secureaccess.plist';
      expect(uninstall.userPaths(deleteData: false), isNot(contains(plist)));
      expect(
        uninstall.userPaths(deleteData: false),
        contains('/Users/r/Library/Caches/com.panoramasg.secureaccess'),
      );
      expect(uninstall.userPaths(deleteData: true), contains(plist));
    });
  });

  test('removal stops the Helper before the package goes', () {
    final script = AppUninstall.linuxRemovalScript(
      AppInstallKind.ostree,
      'panorama-secure-access',
    );
    expect(
      script.indexOf('systemctl disable --now panorama-secure-access-helper'),
      lessThan(script.indexOf('rpm-ostree uninstall panorama-secure-access')),
    );
    expect(script, contains('49-panorama-secure-access-helper.rules'));
  });

  test('cleanup waits for the app to exit and passes paths as arguments', () {
    final command = AppUninstall.cleanupCommand(42, [
      '/a b',
    ], defaultsDomain: 'com.example');
    expect(command[1], startsWith(r'pid=$1; shift; while kill -0'));
    expect(command[1], contains('defaults delete com.example'));
    expect(command[1], endsWith(r'rm -rf -- "$@"'));
    expect(command.sublist(2), ['sh', '42', '/a b']);
  });

  group('uninstall', () {
    test('a declined password deletes nothing', () async {
      var started = false;
      final done = await _linux(
        elevate: (_) async => false,
        startDetached: (_, _) async => started = true,
      ).uninstall(deleteData: true);
      expect(done, isFalse);
      expect(started, isFalse);
    });

    test('removes the queried package, then schedules the user files', () async {
      List<String>? elevated;
      List<String>? cleanup;
      final done = await _linux(
        executable: '/opt/panorama-secure-access/panorama-secure-access',
        run: (_, _) async => ProcessResult(
          0,
          0,
          'panorama-secure-access: /opt/panorama-secure-access/panorama-secure-access',
          '',
        ),
        elevate: (command) async {
          elevated = command;
          return true;
        },
        startDetached: (_, arguments) async => cleanup = arguments,
      ).uninstall(deleteData: false);
      expect(done, isTrue);
      expect(elevated!.last, endsWith('dpkg -r panorama-secure-access'));
      expect(cleanup, contains('$_home/.cache/com.panoramasg.secureaccess'));
      expect(
        cleanup,
        isNot(contains('$_home/.local/share/com.panoramasg.secureaccess')),
      );
    });

    test('an AppImage needs no password', () async {
      var elevated = false;
      final done = await _linux(
        appImage: true,
        elevate: (_) async => elevated = true,
      ).uninstall(deleteData: false);
      expect(done, isTrue);
      expect(elevated, isFalse);
    });
  });
}
