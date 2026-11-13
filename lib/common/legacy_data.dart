import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'constant.dart';
import 'install_policy.dart';
import 'print.dart';

export 'install_policy.dart' show legacyBundleId, legacyDataDirectories;

class LegacyDataImport {
  final String source;
  final bool preferences;

  const LegacyDataImport({required this.source, required this.preferences});
}

/// The source is only read, so FlClash or an older release keeps working.
class LegacyDataMigration {
  static const markerName = '.imported-from.json';

  final Directory target;
  final List<Directory> candidates;

  /// macOS keeps the settings in the bundle id's user defaults.
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

  Future<LegacyDataImport?> run() async {
    final targetPath = p.canonicalize(target.path);
    final index = pickImportSource(
      targetHasData: hasUserData(target),
      targetEmpty: _isEmptyOrMissing(target),
      candidates: [
        for (final candidate in candidates)
          DataCandidate(
            sameAsTarget: p.canonicalize(candidate.path) == targetPath,
            hasUserData: hasUserData(candidate),
          ),
      ],
    );
    if (index == null) {
      return null;
    }
    final from = candidates[index];
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

  /// A link could lead the copy out of the legacy directory.
  static Future<void> _copyDirectory(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (isTransientEntry(name, appExecutableName)) {
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

LegacyDataImport? get lastLegacyDataImport => _lastImport;

/// Must run before anything opens the data directory.
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
