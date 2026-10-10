import 'package:fl_clash/common/update.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _names = [
  'PanoramaSecureAccess-3.4.1-android-arm64-v8a.apk',
  'PanoramaSecureAccess-3.4.1-android-armeabi-v7a.apk',
  'PanoramaSecureAccess-3.4.1-linux-amd64.deb',
  'PanoramaSecureAccess-3.4.1-linux-amd64.AppImage',
  'PanoramaSecureAccess-3.4.1-macos-arm64.dmg',
  'PanoramaSecureAccess-3.4.1-windows-amd64-setup.exe',
  'PanoramaSecureAccess-3.4.1-windows-amd64.zip',
  'SHA256SUMS',
];

final _assets = [
  for (final name in _names)
    UpdateAsset(name: name, url: 'https://example.test/$name', size: 10),
];

String? _pick(
  UpdatePlatform platform, {
  String arch = 'amd64',
  List<String> abis = const [],
}) {
  return selectUpdateAsset(
    _assets,
    platform: platform,
    arch: arch,
    androidAbis: abis,
  )?.name;
}

void main() {
  group('selectUpdateAsset', () {
    test('follows the device ABI preference on Android', () {
      expect(
        _pick(UpdatePlatform.android, abis: ['armeabi-v7a', 'arm64-v8a']),
        endsWith('android-armeabi-v7a.apk'),
      );
      expect(_pick(UpdatePlatform.android, abis: ['x86_64']), isNull);
    });

    test('prefers the Windows installer over the zip', () {
      expect(
        _pick(UpdatePlatform.windows),
        endsWith('windows-amd64-setup.exe'),
      );
      expect(_pick(UpdatePlatform.windows, arch: 'arm64'), isNull);
    });

    test('prefers AppImage over deb on Linux', () {
      expect(_pick(UpdatePlatform.linux), endsWith('linux-amd64.AppImage'));
    });

    test('matches the macOS architecture', () {
      expect(_pick(UpdatePlatform.macos, arch: 'arm64'), endsWith('.dmg'));
      expect(_pick(UpdatePlatform.macos), isNull);
    });
  });

  group('parseUpdateAssets', () {
    test('skips entries without a name or download url', () {
      final assets = parseUpdateAssets([
        {'name': 'a.apk', 'browser_download_url': 'https://x/a.apk', 'size': 7},
        {'name': '', 'browser_download_url': 'https://x/b'},
        {'name': 'c', 'browser_download_url': null},
        'not a map',
      ]);
      expect(assets, hasLength(1));
      expect(assets.single.size, 7);
    });
  });

  group('findChecksum', () {
    const sums =
        'ABCDEF01  PanoramaSecureAccess-3.4.1-android-arm64-v8a.apk\n'
        '1234abcd *PanoramaSecureAccess-3.4.1-windows-amd64-setup.exe\n';

    test('reads text and binary mode entries case-insensitively', () {
      expect(
        findChecksum(sums, 'PanoramaSecureAccess-3.4.1-android-arm64-v8a.apk'),
        'abcdef01',
      );
      expect(
        findChecksum(
          sums,
          'PanoramaSecureAccess-3.4.1-windows-amd64-setup.exe',
        ),
        '1234abcd',
      );
    });

    test('returns null for an unknown file', () {
      expect(findChecksum(sums, 'missing.apk'), isNull);
    });
  });

  group('UpdateState.progress', () {
    final asset = _assets.first;

    test(
      'derives the fraction from the asset size until the total is known',
      () {
        final state = UpdateState(
          tag: 'v3.4.1',
          asset: asset,
          stage: UpdateStage.downloading,
          received: 5,
        );
        expect(state.progress, 0.5);
        expect(state.copyWith(total: 20).progress, 0.25);
      },
    );

    test('is indeterminate while verifying and full when ready', () {
      final state = UpdateState(tag: 'v3.4.1', asset: asset);
      expect(state.copyWith(stage: UpdateStage.verifying).progress, isNull);
      expect(state.copyWith(stage: UpdateStage.ready).progress, 1);
    });

    test('strips the tag prefix for display', () {
      expect(UpdateState(tag: 'v3.4.1', asset: asset).version, '3.4.1');
    });
  });
}
