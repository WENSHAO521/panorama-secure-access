import 'package:drift/drift.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/services.dart';

/// Snowflake ids are far above this, so the bundled script keeps one id on
/// every install and new profiles can find it after a rename.
const _defaultScriptId = 1;

const _defaultScriptUrl =
    'https://raw.githubusercontent.com/WENSHAO521/panorama-secure-access/main/assets/data/default_script.js';

const _defaultScriptAsset = 'assets/data/default_script.js';

/// Raised when the bundled script changes in a way every install should get
/// once, even where the user had deleted or edited the previous one.
/// 1: our own script (v3.5.11). 2: ziji script, enabled on every profile.
const defaultScriptRevision = 2;

// Kept in memory so adding a profile never waits on the database.
var _defaultScriptInstalled = false;

/// Installs the bundled script once per [defaultScriptRevision] and turns it
/// on for every profile that does not run a script of its own. Between
/// revisions a user who deletes it or switches a profile away keeps that.
Future<void> seedDefaultScript() async {
  try {
    var script = await database.scriptsDao
        .get(_defaultScriptId)
        .getSingleOrNull();
    if (await preferences.getDefaultScriptRevision() < defaultScriptRevision) {
      final content = await rootBundle.loadString(_defaultScriptAsset);
      final String label;
      if (script != null) {
        label = script.label;
      } else {
        final labels = await database.scriptsDao.query().get();
        label = labels.uniqueLabel(
          currentAppLocalizations.defaultScript,
          fallback: currentAppLocalizations.script,
        );
      }
      script = await Script(
        id: _defaultScriptId,
        label: label,
        lastUpdateTime: DateTime.now(),
        url: _defaultScriptUrl,
        order: -1,
      ).save(content);
      await database.scriptsDao.putAll([script.toCompanion()]);
      await _enableOnProfiles();
      await preferences.setDefaultScriptRevision(defaultScriptRevision);
    }
    _defaultScriptInstalled = script != null;
  } catch (e) {
    commonPrint.log('default script not seeded: $e');
  }
}

/// Profiles that already run another script the user still has keep it.
Future<void> _enableOnProfiles() async {
  final scriptIds = await database.scriptsDao
      .query()
      .map((script) => script.id)
      .get();
  final profiles = database.profiles;
  await (profiles.update()..where(
        (t) =>
            t.extendType.equalsValue(ExtendType.standard) |
            t.scriptId.isNull() |
            t.scriptId.isNotIn(scriptIds),
      ))
      .write(
        const ProfilesCompanion(
          extendType: Value(ExtendType.script),
          scriptId: Value(_defaultScriptId),
        ),
      );
}

void forgetDefaultScript(int scriptId) {
  if (scriptId == _defaultScriptId) {
    _defaultScriptInstalled = false;
  }
}

/// A new subscription runs the default script while the user keeps it.
Profile withDefaultScript(Profile profile) {
  if (!_defaultScriptInstalled) {
    return profile;
  }
  return profile.copyWith(
    extendType: ExtendType.script,
    scriptId: _defaultScriptId,
  );
}
