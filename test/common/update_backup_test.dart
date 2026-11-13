import 'dart:io';

import 'package:fl_clash/common/update_backup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory home;
  late UpdateBackups backups;

  setUp(() async {
    home = await Directory.systemTemp.createTemp('update_backup_test');
    backups = UpdateBackups(homeDir: () async => home.path);
  });

  tearDown(() => home.delete(recursive: true));

  Future<String> archive(String content) async {
    final file = File(p.join(home.path, 'source-$content.zip'));
    await file.writeAsString(content);
    return file.path;
  }

  test('has nothing before the first update', () async {
    expect(await backups.latest(), isNull);
  });

  test('keeps only the backup from the latest update', () async {
    await backups.save(
      await archive('old'),
      fromVersion: '3.5.8',
      toTag: 'v3.5.9-beta.1',
    );
    await backups.save(
      await archive('new'),
      fromVersion: '3.5.9',
      toTag: 'v3.6.0',
      time: DateTime.utc(2026, 11, 13),
    );

    final latest = (await backups.latest())!;

    expect(latest.fromVersion, '3.5.9');
    expect(latest.toTag, 'v3.6.0');
    expect(latest.time, DateTime.utc(2026, 11, 13));
    expect(await File(latest.archivePath).readAsString(), 'new');
    expect(
      Directory(
        p.join(home.path, UpdateBackups.directoryName),
      ).listSync().map((item) => p.basename(item.path)).toSet(),
      {'backup.zip', 'manifest.json'},
    );
  });

  test('ignores a backup whose manifest is broken', () async {
    final info = await backups.save(
      await archive('x'),
      fromVersion: '1',
      toTag: 'v2',
    );
    await File(
      p.join(p.dirname(info.archivePath), 'manifest.json'),
    ).writeAsString('{');

    expect(await backups.latest(), isNull);
  });

  test('a save left half done by a crash does not block the next', () async {
    await Directory(
      p.join(home.path, '${UpdateBackups.directoryName}.saving'),
    ).create();

    await backups.save(await archive('y'), fromVersion: '1', toTag: 'v2');

    expect(await backups.latest(), isNotNull);
  });
}
