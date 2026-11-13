import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_version.dart';

ReleaseVersion _parse(String tag, {DateTime? at, int run = 343}) =>
    ReleaseVersion.parse(
      tag,
      buildTime: at ?? DateTime.utc(2026, 11, 13, 5, 20),
      runNumber: run,
    );

/// dpkg's ordering of upstream versions without epoch or revision.
int _dpkgCompare(String a, String b) {
  int order(String c) {
    if (c == '~') return -1;
    if (c.isEmpty) return 0;
    final code = c.codeUnitAt(0);
    final letter = (code | 32) >= 97 && (code | 32) <= 122;
    return letter ? code : code + 256;
  }

  var i = 0;
  var j = 0;
  while (i < a.length || j < b.length) {
    while ((i < a.length && !_isDigit(a[i])) ||
        (j < b.length && !_isDigit(b[j]))) {
      final ca = i < a.length && !_isDigit(a[i]) ? a[i] : '';
      final cb = j < b.length && !_isDigit(b[j]) ? b[j] : '';
      final diff = order(ca) - order(cb);
      if (diff != 0) return diff;
      if (ca.isNotEmpty) i++;
      if (cb.isNotEmpty) j++;
    }
    var na = 0;
    var nb = 0;
    while (i < a.length && _isDigit(a[i])) {
      na = na * 10 + int.parse(a[i++]);
    }
    while (j < b.length && _isDigit(b[j])) {
      nb = nb * 10 + int.parse(b[j++]);
    }
    if (na != nb) return na - nb;
  }
  return 0;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

void main() {
  group('ReleaseVersion', () {
    test('a beta tag shows as itself everywhere the user reads it', () {
      final version = _parse('v3.5.9-beta.343');

      expect(version.display, '3.5.9-beta.343');
      expect(version.isStable, isFalse);
      expect(version.pubspecVersion('android'), '3.5.9-beta.343+2026111321');
      expect(version.pubspecVersion('windows'), '3.5.9-beta.343');
      expect(version.windowsFileVersion, '3.5.9.343');
      expect(version.buildName('macos'), '3.5.9');
      expect(version.pubspecVersion('macos'), '3.5.9+2026111321');
      expect(version.linuxPackageVersion, '3.5.9+0.beta.343');
    });

    test('a stable tag carries its build number', () {
      final version = _parse('v3.5.9');

      expect(version.display, '3.5.9');
      expect(version.linuxPackageVersion, '3.5.9+2026111321');
      expect(version.toOutputs()['channel'], 'stable');
    });

    test('rejects tags that are not releases', () {
      for (final tag in [
        '3.5.9',
        'v3.5',
        'v3.5.9-rc.1',
        'v03.5.9',
        'v3.5.9-beta.0',
        'v3.5.9-beta.1 ',
        'v70000.0.0',
      ]) {
        expect(() => _parse(tag), throwsFormatException, reason: tag);
      }
      expect(() => _parse('v3.5.9', run: 70000), throwsFormatException);
    });

    test('build numbers rise with time and stay above 3.5.8', () {
      const shipped = 2026110901;
      final earlier = ReleaseVersion.buildNumberAt(
        DateTime.utc(2026, 11, 13, 23, 59),
      );
      final later = ReleaseVersion.buildNumberAt(DateTime.utc(2026, 11, 14));

      expect(earlier, 2026111395);
      expect(later, greaterThan(earlier));
      expect(earlier, greaterThan(shipped));
      expect(
        ReleaseVersion.buildNumberAt(DateTime.utc(2099, 12, 31, 23, 59)),
        lessThanOrEqualTo(ReleaseVersion.maxAndroidVersionCode),
      );
    });

    test('Linux package versions sort beta < next beta < stable', () {
      final versions = [
        '3.5.8+2026110901',
        _parse('v3.5.9-beta.309').linuxPackageVersion,
        _parse('v3.5.9-beta.343').linuxPackageVersion,
        _parse('v3.5.9', at: DateTime.utc(2026, 11, 20)).linuxPackageVersion,
        _parse('v3.5.10-beta.1').linuxPackageVersion,
      ];
      for (var k = 0; k + 1 < versions.length; k++) {
        expect(
          _dpkgCompare(versions[k], versions[k + 1]),
          isNegative,
          reason: '${versions[k]} < ${versions[k + 1]}',
        );
      }
    });

    test('replaces only the version line of pubspec.yaml', () {
      const pubspec = 'name: x\nversion: 3.5.8+2026110901\nenvironment:\n';

      expect(
        withPubspecVersion(pubspec, '3.5.9-beta.1'),
        'name: x\nversion: 3.5.9-beta.1\nenvironment:\n',
      );
      expect(
        () => withPubspecVersion('name: x\n', '1.0.0'),
        throwsFormatException,
      );
    });
  });
}
