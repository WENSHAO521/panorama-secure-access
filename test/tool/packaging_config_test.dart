import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Linux packaging teardown', () {
    for (final format in ['deb', 'rpm']) {
      test('$format removes the Helper unit only on a real uninstall', () {
        final config =
            loadYaml(
                  File(
                    'linux/packaging/$format/make_config.yaml',
                  ).readAsStringSync(),
                )
                as YamlMap;
        final scripts = (config['postuninstall_scripts'] as YamlList)
            .cast<String>();

        expect(scripts.first, contains('exit 0'));
        final removal = scripts.firstWhere(
          (script) => script.startsWith('rm -f '),
        );
        expect(
          removal,
          contains('/etc/systemd/system/panorama-secure-access-helper.service'),
        );
        expect(
          removal,
          contains(
            '/etc/polkit-1/rules.d/49-panorama-secure-access-helper.rules',
          ),
        );
        expect(
          scripts.any((script) => script.contains('systemctl daemon-reload')),
          isTrue,
        );
      });

      test('$format upgrades an installed Helper only on an upgrade', () {
        final config =
            loadYaml(
                  File(
                    'linux/packaging/$format/make_config.yaml',
                  ).readAsStringSync(),
                )
                as YamlMap;
        final upgrade = (config['postinstall_scripts'] as YamlList)
            .cast<String>()
            .singleWhere(
              (script) => script.contains('panorama-secure-access-helper'),
            );

        expect(upgrade, contains('panorama-secure-access-helper upgrade'));
        expect(upgrade, endsWith(format == 'deb' ? '|| true' : '|| :'));
        expect(
          upgrade,
          format == 'deb'
              ? startsWith('[ "\${1:-}" = configure ] && [ -n "\${2:-}" ]')
              : startsWith('[ "\$1" -gt 1 ]'),
        );
      });
    }
  });

  test('every Linux package names the GTK application id as its window '
      'class', () {
    final applicationId = RegExp(
      r'set\(APPLICATION_ID "([^"]+)"\)',
    ).firstMatch(File('linux/CMakeLists.txt').readAsStringSync())!.group(1);

    for (final format in ['deb', 'rpm', 'appimage']) {
      final config =
          loadYaml(
                File(
                  'linux/packaging/$format/make_config.yaml',
                ).readAsStringSync(),
              )
              as YamlMap;
      expect(config['startup_wm_class'], applicationId, reason: format);
    }
  });

  test('rpm keeps the Core bytes the Helper was built against', () {
    final config =
        loadYaml(
              File('linux/packaging/rpm/make_config.yaml').readAsStringSync(),
            )
            as YamlMap;
    final macros = (config['spec_macros'] as YamlList).cast<String>();

    expect(macros, contains('%global debug_package %{nil}'));
    expect(macros, contains('%global __os_install_post %{nil}'));
  });

  group('app identity', () {
    const appId = 'com.panoramasg.secureaccess';

    String read(String path) => File(path).readAsStringSync();

    test('every platform ships under the same application id', () {
      expect(
        read('android/app/build.gradle.kts'),
        contains('applicationId = "$appId"'),
      );
      expect(
        read('macos/Runner/Configs/AppInfo.xcconfig'),
        contains('PRODUCT_BUNDLE_IDENTIFIER = $appId'),
      );
      expect(
        read('linux/CMakeLists.txt'),
        contains('set(APPLICATION_ID "$appId")'),
      );
    });

    test('binaries, packages and services carry no FlClash name', () {
      final buildConfig = loadYaml(read('build_config.yaml')) as YamlMap;
      expect(buildConfig['core_name'], 'panorama-secure-access-core');
      expect(buildConfig['helper_name'], 'panorama-secure-access-helper');
      expect(
        read('linux/CMakeLists.txt'),
        contains('set(BINARY_NAME "panorama-secure-access")'),
      );
      expect(
        read('windows/CMakeLists.txt'),
        contains('set(BINARY_NAME "panorama-secure-access")'),
      );
      final deb =
          loadYaml(read('linux/packaging/deb/make_config.yaml')) as YamlMap;
      expect(deb['package_name'], 'panorama-secure-access');
      for (final format in ['deb', 'rpm', 'appimage']) {
        expect(
          read('linux/packaging/$format/make_config.yaml'),
          isNot(contains('x-scheme-handler/flclash')),
          reason: format,
        );
      }
    });

    test('the Windows installer has its own AppId and spares FlClash', () {
      final exe =
          loadYaml(read('windows/packaging/exe/make_config.yaml')) as YamlMap;
      expect(exe['app_id'], isNot('728B3532-C74B-4870-9068-BE70FE12A3E6'));
      expect(exe['publisher_name'], 'Panorama Scholarly Group');
      final script = read('windows/packaging/exe/inno_setup.iss');
      expect(script, isNot(contains(r'{userappdata}\com.follow')));
      expect(script, isNot(contains("'FlClash.exe'")));
      expect(script, contains("LegacyDisplayName = 'Panorama Secure Access'"));
    });
  });

  group('Windows installer metadata', () {
    test('names the app icon for the installed apps list', () {
      final script = File(
        'windows/packaging/exe/inno_setup.iss',
      ).readAsStringSync();

      expect(
        script,
        contains(r'UninstallDisplayIcon={app}\\{{EXECUTABLE_NAME}},0'),
      );
      expect(script, contains('UninstallDisplayName={{DISPLAY_NAME}}'));
      expect(script, contains('SetupIconFile={{SETUP_ICON_FILE}}'));
    });

    test('builds the setup icon from the branded runner icon', () {
      final config =
          loadYaml(
                File(
                  'windows/packaging/exe/make_config.yaml',
                ).readAsStringSync(),
              )
              as YamlMap;

      expect(
        config['setup_icon_file'],
        r'windows\runner\resources\app_icon.ico',
      );
      expect(
        File('windows/runner/resources/app_icon.ico').readAsBytesSync(),
        File('assets/images/icon.ico').readAsBytesSync(),
      );
      expect(config['publisher_name'], 'Panorama Scholarly Group');
      expect(config['display_name'], 'Panorama Secure Access');
    });
  });
}
