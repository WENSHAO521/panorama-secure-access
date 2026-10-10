import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:path/path.dart' as p;

enum UpdatePlatform { android, windows, macos, linux }

class UpdateAsset {
  const UpdateAsset({required this.name, required this.url, this.size = 0});

  final String name;
  final String url;
  final int size;
}

class UpdateChecksumException implements Exception {
  const UpdateChecksumException(this.name);

  final String name;

  @override
  String toString() => 'Checksum mismatch for $name';
}

const _checksumAssetName = 'SHA256SUMS';
const _updateDirName = 'updates';

List<UpdateAsset> parseUpdateAssets(List<dynamic> raw) {
  return [
    for (final entry in raw.whereType<Map>())
      if ((entry['name'] as String?)?.isNotEmpty == true &&
          (entry['browser_download_url'] as String?)?.isNotEmpty == true)
        UpdateAsset(
          name: entry['name'] as String,
          url: entry['browser_download_url'] as String,
          size: (entry['size'] as num?)?.toInt() ?? 0,
        ),
  ];
}

UpdateAsset? selectUpdateAsset(
  List<UpdateAsset> assets, {
  required UpdatePlatform platform,
  required String arch,
  List<String> androidAbis = const [],
}) {
  UpdateAsset? firstWhere(bool Function(String name) test) {
    for (final asset in assets) {
      if (test(asset.name)) return asset;
    }
    return null;
  }

  switch (platform) {
    case UpdatePlatform.android:
      for (final abi in androidAbis) {
        final match = firstWhere((name) => name.endsWith('-android-$abi.apk'));
        if (match != null) return match;
      }
      return null;
    case UpdatePlatform.windows:
      return firstWhere((name) => name.endsWith('-windows-$arch-setup.exe'));
    case UpdatePlatform.macos:
      return firstWhere((name) => name.endsWith('-macos-$arch.dmg'));
    case UpdatePlatform.linux:
      for (final extension in const ['.AppImage', '.deb', '.rpm']) {
        final match = firstWhere(
          (name) => name.contains('-linux-$arch') && name.endsWith(extension),
        );
        if (match != null) return match;
      }
      return null;
  }
}

String? findChecksum(String sums, String name) {
  for (final line in sums.split('\n')) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    if (parts.last.replaceFirst('*', '') == name) {
      return parts.first.toLowerCase();
    }
  }
  return null;
}

class Updater {
  const Updater._();

  static String get _desktopArch {
    return switch (Abi.current()) {
      Abi.windowsArm64 || Abi.linuxArm64 || Abi.macosArm64 => 'arm64',
      _ => 'amd64',
    };
  }

  static UpdatePlatform? get _platform {
    if (system.isAndroid) return UpdatePlatform.android;
    if (system.isWindows) return UpdatePlatform.windows;
    if (system.isMacOS) return UpdatePlatform.macos;
    if (system.isLinux) return UpdatePlatform.linux;
    return null;
  }

  static Future<List<String>> _androidAbis() async {
    try {
      final abis = (await DeviceInfoPlugin().androidInfo).supportedAbis;
      if (abis.isNotEmpty) return abis;
    } catch (_) {}
    return const ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
  }

  static Future<UpdateAsset?> pickAsset(List<UpdateAsset> assets) async {
    final platform = _platform;
    if (platform == null) return null;
    return selectUpdateAsset(
      assets,
      platform: platform,
      arch: _desktopArch,
      androidAbis: platform == UpdatePlatform.android
          ? await _androidAbis()
          : const [],
    );
  }

  static Future<String?> expectedChecksum(
    List<UpdateAsset> assets,
    UpdateAsset asset,
  ) async {
    for (final candidate in assets) {
      if (candidate.name != _checksumAssetName) continue;
      try {
        final response = await request.getTextResponseForUrl(candidate.url);
        return findChecksum(response.data ?? '', asset.name);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<String> _sha256(File file) async {
    return (await sha256.bind(file.openRead()).first).toString();
  }

  static Future<Directory> _updateDir() async {
    final base = await appPath.tempDir.future;
    return Directory(p.join(base.path, _updateDirName)).create(recursive: true);
  }

  /// Downloads [asset] and returns the verified file. An earlier download of the
  /// same asset is reused when its checksum still matches.
  static Future<File> download(
    UpdateAsset asset, {
    String? sha256,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
    void Function()? onVerifying,
  }) async {
    final directory = await _updateDir();
    final target = File(p.join(directory.path, asset.name));
    final partial = File('${target.path}.part');
    await for (final entity in directory.list()) {
      if (entity.path != target.path && entity.path != partial.path) {
        await entity.delete(recursive: true);
      }
    }
    if (await target.exists()) {
      if (sha256 != null && await _sha256(target) == sha256) return target;
      await target.delete();
    }
    await request.download(
      asset.url,
      partial.path,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
    if (sha256 != null) {
      onVerifying?.call();
      if (await _sha256(partial) != sha256) {
        await partial.delete();
        throw UpdateChecksumException(asset.name);
      }
    }
    return partial.rename(target.path);
  }

  static Future<bool> install(File file) async {
    if (system.isWindows) {
      await Process.start(file.path, const [], mode: ProcessStartMode.detached);
      return true;
    }
    if (system.isMacOS) {
      return (await Process.run('open', [file.path])).exitCode == 0;
    }
    if (system.isLinux) {
      if (file.path.endsWith('.AppImage')) {
        await Process.run('chmod', ['+x', file.path]);
      }
      return (await Process.run('xdg-open', [file.path])).exitCode == 0;
    }
    if (system.isAndroid) {
      return await app?.openFile(file.path) ?? false;
    }
    return false;
  }
}
