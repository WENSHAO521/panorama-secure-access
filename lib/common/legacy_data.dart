import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'constant.dart';
import 'print.dart';

/// What [LegacyDataMigration.run] copied, kept for the notice after start.
class LegacyDataImport {
  final String source;
  final bool preferences;

  const LegacyDataImport({required this.source, required this.preferences});
}

/// Copies the data of an install that used FlClash's identifiers into this
/// app's own directory. The source is only read, so FlClash, or an older
/// release still installed beside this one, keeps working.
class LegacyDataMigration {
  static const markerName = '.imported-from.json';

  /// Names that belong to a running instance rather than to the user's data.
  static const _transient = {
    'FlClash.lock',
    '$appExecutableName.lock',
    'restore',
  };

  final Directory target;
  final List<Directory> candidates;

  /// Copies the macOS user defaults of the legacy bundle id, which hold the
  /// settings there instead of shared_preferences.json.
  final Future<bool> Function()? importPreferences;
  final Future<void> Function()? discardPreferences;

  LegacyDataMigration({
    required this.target,
    required this.candidates,
    this.importPreferences,
    this.discardPreferences,
  });

  static bool hasUserData(Directory directory) {
    return File(p.join(directory.path, 'database.sqlite')).existsSync() ||
        File(p.join(directory.path, 'shared_preferences.json')).existsSync() ||
        Directory(p.join(directory.path, profilesDirectoryName)).existsSync();
  }

  /// Returns null when nothing was copied: the target already holds data, no
  /// candidate has any, or the copy failed and was rolled back.
  Future<LegacyDataImport?> run() async {
    if (hasUserData(target) || !_isEmptyOrMissing(target)) {
      return null;
    }
    final source = candidates.where(
      (item) => p.canonicalize(item.path) != p.canonicalize(target.path),
    );
    final from = source.where(hasUserData).firstOrNull;
    if (from == null) {
      return null;
    }
    final staging = Directory('${target.path}.importing-$pid');
    var importedPreferences = false;
    try {
      await _deleteIfExists(staging);
      await _copyDirectory(from, staging);
      importedPreferences = await importPreferences?.call() ?? false;
      await File(p.join(staging.path, markerName)).writeAsString(
        json.encode({
          'source': from.path,
          'preferences': importedPreferences,
          'time': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      if (!_isEmptyOrMissing(target)) {
        await _deleteIfExists(staging);
        return null;
      }
      await _deleteIfExists(target);
      await target.parent.create(recursive: true);
      await staging.rename(target.path);
      commonPrint.log('imported legacy data from ${from.path}');
      return LegacyDataImport(
        source: from.path,
        preferences: importedPreferences,
      );
    } catch (error) {
      commonPrint.log(
        'legacy data import from ${from.path} failed, rolled back: $error',
      );
      await _deleteIfExists(staging);
      if (importedPreferences) {
        await discardPreferences?.call();
      }
      if (!target.existsSync()) {
        await target.create(recursive: true);
      }
      return null;
    }
  }

  static bool _isEmptyOrMissing(Directory directory) {
    if (!directory.existsSync()) {
      return true;
    }
    return directory.listSync(followLinks: false).isEmpty;
  }

  static Future<void> _deleteIfExists(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  /// Links and sockets are skipped: a link could point the copy outside the
  /// legacy directory, and a socket belongs to a running Core.
  static Future<void> _copyDirectory(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (_transient.contains(name)) {
        continue;
      }
      final destination = p.join(to.path, name);
      switch (await FileSystemEntity.type(entity.path, followLinks: false)) {
        case FileSystemEntityType.directory:
          await _copyDirectory(Directory(entity.path), Directory(destination));
        case FileSystemEntityType.file:
          await File(entity.path).copy(destination);
        default:
          continue;
      }
    }
  }
}

/// Where FlClash and releases up to 3.5.x kept their data, in the order they
/// are tried. Windows releases already used their own folder; only FlClash's
/// is a candidate there.
@visibleForTesting
List<String> legacyDataDirectories({
  required String operatingSystem,
  required Map<String, String> environment,
}) {
  final home = environment['HOME'] ?? environment['USERPROFILE'] ?? '';
  switch (operatingSystem) {
    case 'linux':
      final dataHome = environment['XDG_DATA_HOME'];
      final base = dataHome != null && dataHome.isNotEmpty
          ? dataHome
          : p.join(home, '.local', 'share');
      return [p.join(base, legacyBundleId), p.join(base, 'FlClash')];
    case 'macos':
      return [p.join(home, 'Library', 'Application Support', legacyBundleId)];
    case 'windows':
      final appData = environment['APPDATA'];
      if (appData == null || appData.isEmpty) {
        return const [];
      }
      return [p.windows.join(appData, 'com.follow', 'clash')];
  }
  return const [];
}

/// The bundle id, GTK application id and Android package FlClash ships under.
const legacyBundleId = 'com.follow.clash';

/// The Android package of the 3.5.9 betas, between FlClash's and this one.
const legacyBetaPackage = 'com.panorama.secureaccess';

Future<bool> _importMacOSDefaults() async {
  final current = await Process.run('defaults', ['read', packageName]);
  if (current.exitCode == 0 && current.stdout.toString().contains('flutter.')) {
    return false;
  }
  final exported = await Process.run('defaults', [
    'export',
    legacyBundleId,
    '-',
  ]);
  final plist = exported.stdout.toString();
  if (exported.exitCode != 0 || !plist.contains('flutter.')) {
    return false;
  }
  final process = await Process.start('defaults', ['import', packageName, '-']);
  process.stdin.write(plist);
  await process.stdin.close();
  if (await process.exitCode != 0) {
    throw const ProcessException('defaults', ['import', packageName, '-']);
  }
  return true;
}

Future<void> _discardMacOSDefaults() async {
  await Process.run('defaults', ['delete', packageName]);
}

LegacyDataImport? _lastImport;

/// The import the current launch made, if any.
LegacyDataImport? get lastLegacyDataImport => _lastImport;

/// Runs once per launch before anything opens the data directory.
Future<void> importLegacyData(String targetPath) async {
  if (safeModeBuild ||
      !(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    return;
  }
  try {
    final migration = LegacyDataMigration(
      target: Directory(targetPath),
      candidates: legacyDataDirectories(
        operatingSystem: Platform.operatingSystem,
        environment: Platform.environment,
      ).map(Directory.new).toList(),
      importPreferences: Platform.isMacOS ? _importMacOSDefaults : null,
      discardPreferences: Platform.isMacOS ? _discardMacOSDefaults : null,
    );
    _lastImport = await migration.run();
  } catch (error) {
    commonPrint.log('legacy data import skipped: $error');
  }
}
