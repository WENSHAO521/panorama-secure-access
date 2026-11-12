import 'dart:io';

import 'package:fl_clash/common/legacy_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory legacy;
  late Directory target;

  setUp(() {
    root = Directory.systemTemp.createTempSync('psa-legacy-');
    legacy = Directory(p.join(root.path, 'com.follow.clash'))..createSync();
    target = Directory(p.join(root.path, 'com.panoramasg.secureaccess'));
  });

  tearDown(() => root.deleteSync(recursive: true));

  void write(Directory directory, String relative, String content) {
    File(p.join(directory.path, relative))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  String read(Directory directory, String relative) =>
      File(p.join(directory.path, relative)).readAsStringSync();

  LegacyDataMigration migration({
    Future<bool> Function()? importPreferences,
    Future<void> Function()? discardPreferences,
  }) => LegacyDataMigration(
    target: target,
    candidates: [legacy],
    importPreferences: importPreferences,
    discardPreferences: discardPreferences,
  );

  test('copies profiles, database and settings, leaving the source', () async {
    write(legacy, 'database.sqlite', 'db');
    write(legacy, 'shared_preferences.json', '{"a":1}');
    write(legacy, 'profiles/1.yaml', 'proxies: []');
    write(legacy, 'FlClash.lock', '123');

    final result = await migration().run();

    expect(result?.source, legacy.path);
    expect(read(target, 'database.sqlite'), 'db');
    expect(read(target, 'profiles/1.yaml'), 'proxies: []');
    expect(File(p.join(target.path, 'FlClash.lock')).existsSync(), isFalse);
    expect(
      File(p.join(target.path, LegacyDataMigration.markerName)).existsSync(),
      isTrue,
    );
    expect(read(legacy, 'database.sqlite'), 'db');
    expect(read(legacy, 'FlClash.lock'), '123');
  });

  test('replaces the empty folder path_provider already created', () async {
    target.createSync();
    write(legacy, 'database.sqlite', 'db');

    expect(await migration().run(), isNotNull);
    expect(read(target, 'database.sqlite'), 'db');
  });

  test('never touches a target that already holds data', () async {
    write(legacy, 'database.sqlite', 'old');
    write(target, 'database.sqlite', 'new');

    expect(await migration().run(), isNull);
    expect(read(target, 'database.sqlite'), 'new');
  });

  test('leaves a non-empty target without data alone', () async {
    write(legacy, 'database.sqlite', 'old');
    write(target, 'notes.txt', 'mine');

    expect(await migration().run(), isNull);
    expect(File(p.join(target.path, 'database.sqlite')).existsSync(), isFalse);
  });

  test('does nothing without a legacy install', () async {
    legacy.deleteSync();

    expect(await migration().run(), isNull);
  });

  test('skips links so the copy cannot leave the legacy folder', () async {
    final outside = Directory(p.join(root.path, 'outside'))..createSync();
    write(outside, 'secret', 'x');
    write(legacy, 'database.sqlite', 'db');
    Link(p.join(legacy.path, 'escape')).createSync(outside.path);

    await migration().run();

    expect(
      FileSystemEntity.typeSync(
        p.join(target.path, 'escape'),
        followLinks: false,
      ),
      FileSystemEntityType.notFound,
    );
  });

  test('rolls back the copy and the settings when a step fails', () async {
    write(legacy, 'database.sqlite', 'db');
    target.createSync();
    var discarded = false;

    final result = await migration(
      importPreferences: () async => throw const FileSystemException('full'),
      discardPreferences: () async => discarded = true,
    ).run();

    expect(result, isNull);
    expect(target.listSync(), isEmpty);
    expect(
      root.listSync().map((item) => p.basename(item.path)),
      isNot(contains(startsWith('com.panoramasg.secureaccess.importing'))),
    );
    expect(discarded, isFalse);
    expect(read(legacy, 'database.sqlite'), 'db');
  });

  group('legacyDataDirectories', () {
    test('Linux honours XDG_DATA_HOME and the executable-name folder', () {
      expect(
        legacyDataDirectories(
          operatingSystem: 'linux',
          environment: {'HOME': '/home/a', 'XDG_DATA_HOME': '/data'},
        ),
        ['/data/com.follow.clash', '/data/FlClash'],
      );
      expect(
        legacyDataDirectories(
          operatingSystem: 'linux',
          environment: {'HOME': '/home/a'},
        ).first,
        '/home/a/.local/share/com.follow.clash',
      );
    });

    test('macOS reads the legacy bundle id folder', () {
      expect(
        legacyDataDirectories(
          operatingSystem: 'macos',
          environment: {'HOME': '/Users/a'},
        ),
        ['/Users/a/Library/Application Support/com.follow.clash'],
      );
    });

    test('Windows only offers FlClash\'s own folder', () {
      expect(
        legacyDataDirectories(
          operatingSystem: 'windows',
          environment: {'APPDATA': r'C:\Users\a\AppData\Roaming'},
        ),
        [r'C:\Users\a\AppData\Roaming\com.follow\clash'],
      );
    });
  });
}
