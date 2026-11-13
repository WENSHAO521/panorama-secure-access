import 'package:fl_clash/common/install_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rust_api/install.dart' as native;

import '../helpers/rust_native.dart';

const _bools = [false, true];

void main() {
  setUpAll(initRustNative);

  test('legacy data directories agree', () {
    final environments = [
      <String, String>{},
      {'HOME': '/home/a'},
      {'HOME': '/home/a/', 'XDG_DATA_HOME': ''},
      {'HOME': '/home/a', 'XDG_DATA_HOME': '/data/'},
      {'USERPROFILE': r'C:\Users\a', 'APPDATA': r'C:\Users\a\AppData\Roaming'},
      {'APPDATA': 'C:\\Roaming\\'},
      {'HOME': '/Users/a'},
    ];
    for (final os in ['linux', 'macos', 'windows', 'android', 'ios']) {
      for (final environment in environments) {
        expect(
          native.legacyDataDirectories(
            operatingSystem: os,
            environment: environment,
          ),
          dartLegacyDataDirectories(os, environment),
          reason: '$os $environment',
        );
      }
    }
  });

  test('import source choice agrees', () {
    final candidateSets = [
      for (final first in _bools)
        for (final second in _bools)
          for (final same in _bools)
            [
              DataCandidate(sameAsTarget: same, hasUserData: first),
              DataCandidate(sameAsTarget: false, hasUserData: second),
            ],
      <DataCandidate>[],
    ];
    for (final hasData in _bools) {
      for (final empty in _bools) {
        for (final candidates in candidateSets) {
          expect(
            native.pickImportSource(
              targetHasData: hasData,
              targetEmpty: empty,
              candidates: candidates,
            ),
            dartPickImportSource(hasData, empty, candidates),
          );
        }
      }
    }
  });

  test('install recognition and removal agree', () {
    for (final name in [
      'FlClash.lock',
      'panorama-secure-access.lock',
      'restore',
      'database.sqlite',
      '.lock',
      'restore.lock',
    ]) {
      expect(
        native.isTransientEntry(
          name: name,
          executableName: 'panorama-secure-access',
        ),
        dartIsTransientEntry(name, 'panorama-secure-access'),
        reason: name,
      );
    }
    for (final output in [
      'install ok installed|Panorama Scholarly Group',
      'install ok installed|chen08209',
      'deinstall ok config-files|Panorama',
      '',
    ]) {
      expect(
        native.isLegacyDebStatus(output: output),
        dartIsLegacyDebStatus(output),
      );
      expect(
        native.isLegacyRpmPackager(output: output),
        dartIsLegacyRpmPackager(output),
      );
    }
    for (final (name, id) in [
      ('Panorama Secure Access', 'com.follow.clash'),
      ('FlClash', 'com.follow.clash'),
      ('Panorama Secure Access', 'com.panoramasg.secureaccess'),
    ]) {
      expect(
        native.isLegacyMacBundle(bundleName: name, bundleIdentifier: id),
        dartIsLegacyMacBundle(name, id),
      );
    }
    for (final kind in LegacyPackageKind.values) {
      for (final package in ['flclash', 'FlClash', 'x; rm -rf /', '']) {
        expect(
          native.linuxRemovalScript(kind: kind, package: package),
          dartLinuxRemovalScript(kind, package),
          reason: '$kind $package',
        );
      }
    }
  });
}
