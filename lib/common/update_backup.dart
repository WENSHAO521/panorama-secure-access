import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'path.dart';

class UpdateBackupInfo {
  final String archivePath;
  final String fromVersion;
  final String toTag;
  final DateTime time;

  const UpdateBackupInfo({
    required this.archivePath,
    required this.fromVersion,
    required this.toTag,
    required this.time,
  });
}

/// A backup archive taken right before an update is installed, which the
/// version it came from can restore if the update goes wrong. Only the one
/// from the latest update is kept.
class UpdateBackups {
  static const directoryName = 'update-backup';
  static const _archiveName = 'backup.zip';
  static const _manifestName = 'manifest.json';

  final Future<String> Function() homeDir;

  UpdateBackups({Future<String> Function()? homeDir})
    : homeDir = homeDir ?? (() => appPath.homeDirPath);

  Future<Directory> get _directory async =>
      Directory(p.join(await homeDir(), directoryName));

  Future<UpdateBackupInfo> save(
    String archivePath, {
    required String fromVersion,
    required String toTag,
    DateTime? time,
  }) async {
    final directory = await _directory;
    final staging = Directory('${directory.path}.saving');
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    await staging.create(recursive: true);
    final info = UpdateBackupInfo(
      archivePath: p.join(directory.path, _archiveName),
      fromVersion: fromVersion,
      toTag: toTag,
      time: (time ?? DateTime.now()).toUtc(),
    );
    await File(archivePath).copy(p.join(staging.path, _archiveName));
    await File(p.join(staging.path, _manifestName)).writeAsString(
      json.encode({
        'from': info.fromVersion,
        'to': info.toTag,
        'time': info.time.toIso8601String(),
      }),
    );
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await staging.rename(directory.path);
    return info;
  }

  Future<UpdateBackupInfo?> latest() async {
    final directory = await _directory;
    final archive = File(p.join(directory.path, _archiveName));
    final manifest = File(p.join(directory.path, _manifestName));
    if (!await archive.exists() || !await manifest.exists()) {
      return null;
    }
    try {
      final data = json.decode(await manifest.readAsString());
      return UpdateBackupInfo(
        archivePath: archive.path,
        fromVersion: data['from'] as String,
        toTag: data['to'] as String,
        time: DateTime.parse(data['time'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

final updateBackups = UpdateBackups();
