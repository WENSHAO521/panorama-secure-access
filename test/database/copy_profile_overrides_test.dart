import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database db;

  const source = Profile(id: 1, label: 'Work', autoUpdateDuration: Duration());
  const copy = Profile(id: 2, label: 'Work(1)', autoUpdateDuration: Duration());

  const globalRule = Rule(
    id: 100,
    ruleAction: RuleAction.DOMAIN,
    content: 'global.example',
    ruleTarget: 'DIRECT',
  );
  const addedRule = Rule(
    id: 200,
    ruleAction: RuleAction.DOMAIN_SUFFIX,
    content: 'added.example',
    ruleTarget: 'Proxy',
  );
  const customRules = [
    Rule(id: 300, content: 'first.example', ruleTarget: 'Proxy'),
    Rule(id: 301, content: 'second.example', ruleTarget: 'DIRECT'),
  ];
  const groups = [
    ProxyGroup(id: 400, name: 'Proxy', type: GroupType.Selector),
    ProxyGroup(id: 401, name: 'Auto', type: GroupType.URLTest),
  ];

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = Database(NativeDatabase.memory());
    await db.profiles.put(source.toCompanion());
    await db.profiles.put(copy.toCompanion());
    await db.rulesDao.putGlobalRule(globalRule);
    await db.rulesDao.putProfileAddedRule(source.id, addedRule);
    await db.rulesDao.putDisabledLink(source.id, globalRule.id);
    await db.setProfileCustomData(source.id, groups, customRules);
  });

  tearDown(() async {
    await db.close();
  });

  test('copies added, disabled and custom rules and groups', () async {
    await db.copyProfileOverrides(source.id, copy.id);

    final added = await db.rulesDao.queryProfileAddedRules(copy.id).get();
    expect(added.map((r) => r.content), ['added.example']);
    expect(added.single.ruleAction, RuleAction.DOMAIN_SUFFIX);

    final disabled = await db.rulesDao.queryProfileDisabledRules(copy.id).get();
    expect(disabled.map((r) => r.id), [globalRule.id]);
    // So the global rule stays switched off in the copy too.
    final effective = await db.rulesDao.queryAddedRules(copy.id).get();
    expect(effective.map((r) => r.content), ['added.example']);

    final custom = await db.rulesDao.queryProfileCustomRules(copy.id).get();
    expect(custom.map((r) => r.content), ['first.example', 'second.example']);

    final copiedGroups = await db.proxyGroupsDao.query(copy.id).get();
    expect(copiedGroups.map((g) => g.name), ['Proxy', 'Auto']);
    expect(copiedGroups.map((g) => g.profileId), everyElement(copy.id));
  });

  test('copies get their own ids', () async {
    await db.copyProfileOverrides(source.id, copy.id);

    final added = await db.rulesDao.queryProfileAddedRules(copy.id).get();
    final custom = await db.rulesDao.queryProfileCustomRules(copy.id).get();
    final copiedGroups = await db.proxyGroupsDao.query(copy.id).get();
    expect(added.single.id, isNot(addedRule.id));
    expect(custom.map((r) => r.id).toSet().intersection({300, 301}), isEmpty);
    expect(
      copiedGroups.map((g) => g.id).toSet().intersection({400, 401}),
      isEmpty,
    );
  });

  test('changing the copy leaves the original alone', () async {
    await db.copyProfileOverrides(source.id, copy.id);

    final added = await db.rulesDao.queryProfileAddedRules(copy.id).get();
    final custom = await db.rulesDao.queryProfileCustomRules(copy.id).get();
    await db.rulesDao.delRules([added.single.id, custom.first.id]);
    await db.setProfileCustomData(copy.id, const [], const []);

    expect(
      (await db.rulesDao.queryProfileAddedRules(source.id).get()).single.id,
      addedRule.id,
    );
    expect(
      (await db.rulesDao.queryProfileCustomRules(source.id).get()).map(
        (r) => r.id,
      ),
      [300, 301],
    );
    expect((await db.proxyGroupsDao.query(source.id).get()).map((g) => g.id), [
      400,
      401,
    ]);
  });

  test('a profile without overrides copies to nothing', () async {
    await db.copyProfileOverrides(copy.id, 3);

    expect(await db.rulesDao.queryProfileAddedRules(3).get(), isEmpty);
    expect(await db.rulesDao.queryProfileCustomRules(3).get(), isEmpty);
    expect(await db.proxyGroupsDao.query(3).get(), isEmpty);
  });
}
