import 'package:test/test.dart';

import '../setup.dart' as setup;
import '../tool/release_version.dart';

void main() {
  group('setup.dart', () {
    test('parses -v as verbose mode', () {
      final results = setup.createSetupArgParser().parse(['android', '-v']);

      expect(results['verbose'], isTrue);
      expect(results.rest, ['android']);
    });

    test('accepts dev application environment', () {
      final results = setup.createSetupArgParser().parse([
        'android',
        '--env',
        'dev',
      ]);

      expect(results['env'], 'dev');
    });

    test('Flutter build environment does not depend on Core SHA256', () {
      expect(setup.createBuildEnvironment('dev'), {'APP_ENV': 'dev'});
    });

    test('passes the release tag to the app', () {
      expect(setup.createBuildEnvironment('pre', releaseTag: 'v1.2.1-beta.4'), {
        'APP_ENV': 'pre',
        'APP_RELEASE_TAG': 'v1.2.1-beta.4',
      });
    });

    test('omits verbose from flutter build args by default', () {
      final args = setup.createFlutterBuildArgs(
        platform: 'android',
        verbose: false,
      );

      expect(args, ['dart-define-from-file=env.json', 'split-per-abi']);
    });

    test('passes every platform the build name and number of the tag', () {
      final release = ReleaseVersion.parse(
        'v3.5.9-beta.300',
        buildTime: DateTime.utc(2026, 11, 13, 5, 20),
        runNumber: 300,
      );
      List<String> argsFor(String platform) => setup.createFlutterBuildArgs(
        platform: platform,
        verbose: false,
        release: release,
      );

      expect(
        argsFor('android'),
        containsAll(['build-name=3.5.9-beta.300', 'build-number=2026111321']),
      );
      expect(
        argsFor('windows'),
        containsAll(['build-name=3.5.9-beta.300', 'build-number=300']),
      );
      expect(
        argsFor('macos'),
        containsAll(['build-name=3.5.9', 'build-number=2026111321']),
      );
      expect(
        setup.createFlutterBuildArgs(platform: 'linux', verbose: false),
        isNot(contains(startsWith('build-name='))),
      );
    });

    test('adds verbose to flutter build args with -v', () {
      final args = setup.createFlutterBuildArgs(
        platform: 'android',
        verbose: true,
      );

      expect(args, [
        'verbose',
        'dart-define-from-file=env.json',
        'split-per-abi',
      ]);
    });

    test('refuses to package while a native build hook is skipped', () {
      const pubspec = '''
hooks:
  user_defines:
    setup:
      build_assets: false
    rust_api:
      build_assets: true
''';

      expect(setup.packagesNotBuildingAssets(pubspec), ['setup']);
      expect(setup.packagesNotBuildingAssets('name: x\n'), isEmpty);
    });

    test('packages every Linux format on every architecture', () {
      expect(setup.createPackageTargets('linux', null), 'deb,appimage,rpm');
      expect(setup.createPackageTargets('linux', 'deb'), 'deb');
      expect(setup.createPackageTargets('macos', null), 'dmg');
    });

    test('names the architecture as appimagetool reads ARCH', () {
      expect(setup.appImageArchName('arm64'), 'arm_aarch64');
      expect(setup.appImageArchName('amd64'), 'x86_64');
    });

    test('downloads the appimagetool build matching the host', () {
      expect(setup.appImageToolArch('arm64'), 'aarch64');
      expect(setup.appImageToolArch('amd64'), 'x86_64');
    });
  });
}
