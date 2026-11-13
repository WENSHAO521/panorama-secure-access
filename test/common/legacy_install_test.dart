import 'dart:io';

import 'package:fl_clash/common/legacy_install.dart';
import 'package:flutter_test/flutter_test.dart';

ProcessResult _result(int code, String stdout) =>
    ProcessResult(0, code, stdout, '');

void main() {
  group('Linux', () {
    test('finds our deb by its maintainer and skips FlClash\'s', () async {
      Future<ProcessResult> run(String executable, List<String> arguments) {
        final maintainer = arguments.last == 'flclash'
            ? 'chen08209 <chen08209@gmail.com>'
            : 'Panorama Scholarly Group <psa@panorama-sg.com>';
        return Future.value(_result(0, 'install ok installed|$maintainer'));
      }

      final found = await LegacyInstalls(
        run: run,
        exists: (path) => path == '/usr/bin/dpkg-query',
      ).findDesktop(operatingSystem: 'linux');

      expect(found, [const LegacyInstall(LegacyInstallKind.deb, 'FlClash')]);
    });

    test('leaves an upstream FlClash rpm alone', () async {
      final found = await LegacyInstalls(
        run: (_, _) async => _result(0, 'chen08209'),
        exists: (path) => path == '/usr/bin/rpm',
      ).findDesktop(operatingSystem: 'linux');

      expect(found, isEmpty);
    });

    test('an rpm-ostree system layers the removal', () async {
      final found = await LegacyInstalls(
        run: (_, _) async => _result(0, 'Panorama Scholarly Group'),
        exists: (path) => path == '/usr/bin/rpm',
      ).findDesktop(operatingSystem: 'linux', ostree: true);

      expect(found.single.kind, LegacyInstallKind.ostree);
      expect(
        LegacyInstalls.linuxRemovalScript(found.single),
        endsWith('rpm-ostree uninstall FlClash'),
      );
    });

    test('removal stops the legacy Helper before the package goes', () {
      final script = LegacyInstalls.linuxRemovalScript(
        const LegacyInstall(LegacyInstallKind.deb, 'flclash'),
      );

      expect(
        script.indexOf('disable --now flclash-helper.service'),
        lessThan(script.indexOf('dpkg -r flclash')),
      );
      expect(script, contains('49-flclash-helper.rules'));
    });
  });

  group('macOS', () {
    LegacyInstalls installs(String name, String id) => LegacyInstalls(
      exists: (_) => true,
      run: (_, arguments) async =>
          _result(0, arguments[1] == 'CFBundleName' ? name : id),
    );

    test('finds FlClash.app only when it carries our name', () async {
      expect(
        await installs(
          'Panorama Secure Access',
          'com.follow.clash',
        ).findDesktop(operatingSystem: 'macos'),
        [
          const LegacyInstall(
            LegacyInstallKind.macApp,
            '/Applications/FlClash.app',
          ),
        ],
      );
      expect(
        await installs(
          'FlClash',
          'com.follow.clash',
        ).findDesktop(operatingSystem: 'macos'),
        isEmpty,
      );
    });
  });
}
