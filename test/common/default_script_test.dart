import 'dart:io';

import 'package:drift/native.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/default_script.dart';
import 'package:fl_clash/database/database.dart' as db;
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_paths.dart';
import '../helpers/preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory home;
  late db.Database database;

  Profile profile(int id, {ExtendType? extendType, int? scriptId}) =>
      Profile.normal(label: 'p$id').copyWith(
        id: id,
        extendType: extendType ?? ExtendType.standard,
        scriptId: scriptId,
      );

  Future<Profile> read(int id) async => (await database.profilesDao.get(id))!;

  setUp(() async {
    home = Directory.systemTemp.createTempSync('default-script-');
    await useAppPaths(home);
    database = db.Database(NativeDatabase.memory());
    db.database = database;
    await AppLocalizations.load(const Locale('en'));
  });

  tearDown(() async {
    await database.close();
    home.deleteSync(recursive: true);
  });

  test('upgrade replaces the old default script and enables it on profiles '
      'without a script of their own', () async {
    await mockPreferences({'defaultScriptSeeded': true});
    final own = Script(id: 50, label: 'Mine', lastUpdateTime: DateTime(2026));
    await database.scriptsDao.putAll([
      Script(
        id: 1,
        label: 'Renamed default',
        lastUpdateTime: DateTime(2026),
      ).toCompanion(),
      own.toCompanion(),
    ]);
    await database.profilesDao.setAll([
      profile(10),
      profile(11, extendType: ExtendType.script, scriptId: 50),
      profile(12, extendType: ExtendType.script, scriptId: 99),
      profile(13, extendType: ExtendType.script, scriptId: 1),
    ]);

    await seedDefaultScript();

    final script = (await database.scriptsDao.get(1).getSingleOrNull())!;
    expect(script.label, 'Renamed default');
    expect(await script.content, contains('链式出口'));
    expect(
      await script.content,
      isNot(contains('Koolson/Qure/master/IconSet/Color/Global.png')),
    );
    for (final id in [10, 12, 13]) {
      final p = await read(id);
      expect(p.extendType, ExtendType.script, reason: 'profile $id');
      expect(p.scriptId, 1, reason: 'profile $id');
    }
    expect((await read(11)).scriptId, 50);
    expect(await preferences.getDefaultScriptRevision(), defaultScriptRevision);
    expect(withDefaultScript(Profile.normal()).scriptId, 1);
  });

  test('a deleted default script stays deleted within a revision', () async {
    await mockPreferences({'defaultScriptRevision': defaultScriptRevision});
    await database.profilesDao.setAll([profile(10)]);

    await seedDefaultScript();

    expect(await database.scriptsDao.get(1).getSingleOrNull(), isNull);
    expect((await read(10)).extendType, ExtendType.standard);
    expect(withDefaultScript(Profile.normal()).extendType, ExtendType.standard);
  });

  test('a fresh install gets the default script', () async {
    await mockPreferences();

    await seedDefaultScript();

    final script = (await database.scriptsDao.get(1).getSingleOrNull())!;
    expect(script.label, currentAppLocalizations.defaultScript);
    expect(script.url, endsWith('/assets/data/default_script.js'));
  });
}
