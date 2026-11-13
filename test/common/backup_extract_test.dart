import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:fl_clash/common/backup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('backup_extract');
  });

  tearDown(() => root.delete(recursive: true));

  Future<String> zipOf(Map<String, List<int>> files) async {
    final path = join(root.path, 'archive.zip');
    final encoder = ZipFileEncoder()..create(path);
    for (final MapEntry(:key, :value) in files.entries) {
      encoder.addArchiveFile(ArchiveFile.bytes(key, value));
    }
    await encoder.close();
    return path;
  }

  Set<String> stagedFiles(String staging) => {
    for (final entity in Directory(staging).listSync(recursive: true))
      if (entity is File)
        relative(entity.path, from: staging).replaceAll(r'\', '/'),
  };

  Matcher rejected() => throwsA(
    isA<BackupException>().having(
      (error) => error.failure,
      'failure',
      BackupFailure.invalid,
    ),
  );

  test('stages every file inside the staging directory, '
      'as the Dart reference does', () async {
    final archive = await zipOf({
      'config.json': '{}'.codeUnits,
      'profiles/1.yaml': 'proxies: []'.codeUnits,
      'a/../scripts/2.js': 'body'.codeUnits,
      '../outside.txt': 'x'.codeUnits,
      '/absolute.txt': 'x'.codeUnits,
    });
    final rust = join(root.path, 'rust');

    await extractBackupArchive(archive, rust);

    expect(stagedFiles(rust), {
      'config.json',
      'profiles/1.yaml',
      'scripts/2.js',
    });
    expect(File(join(root.path, 'outside.txt')).existsSync(), isFalse);
    expect(
      File(join(rust, 'profiles', '1.yaml')).readAsStringSync(),
      'proxies: []',
    );

    final dart = join(root.path, 'dart');
    await expectLater(
      readBackupArchive(archivePath: archive, stagingDirPath: dart),
      completes,
    );
    expect(stagedFiles(dart), stagedFiles(rust));
  });

  test('rejects what is not a zip archive', () async {
    final path = join(root.path, 'archive.zip');
    File(path).writeAsStringSync('not a zip');

    await expectLater(
      extractBackupArchive(path, join(root.path, 'staging')),
      rejected(),
    );
  });

  test('rejects a compression bomb before writing it out', () async {
    final archive = await zipOf({'config.json': List.filled(8 << 20, 0)});
    final staging = join(root.path, 'staging');

    await expectLater(extractBackupArchive(archive, staging), rejected());
    expect(File(join(staging, 'config.json')).existsSync(), isFalse);
  });

  test('restoreTask unpacks through Rust and reads the config', () async {
    final archive = await zipOf({'config.json': '{"version": 1}'.codeUnits});

    final data = await restoreTask((
      archivePath: archive,
      stagingDirPath: join(root.path, 'staging'),
    ));

    expect(data.configMap?['version'], 1);
  });
}
