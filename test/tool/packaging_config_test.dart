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
        expect(removal, contains('/etc/systemd/system/flclash-helper.service'));
        expect(
          removal,
          contains('/etc/polkit-1/rules.d/49-flclash-helper.rules'),
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
            .singleWhere((script) => script.contains('FlClashHelperService'));

        expect(upgrade, contains('FlClashHelperService upgrade'));
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
}
