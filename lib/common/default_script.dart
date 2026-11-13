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

// Kept in memory so adding a profile never waits on the database.
var _defaultScriptInstalled = false;

/// Adds the bundled script once per install. Existing profiles keep the
/// extension they had; only profiles added afterwards pick it up.
Future<void> seedDefaultScript() async {
  try {
    var script = await database.scriptsDao
        .get(_defaultScriptId)
        .getSingleOrNull();
    if (script == null && !await preferences.getDefaultScriptSeeded()) {
      final labels = await database.scriptsDao.query().get();
      script = await Script(
        id: _defaultScriptId,
        label: labels.uniqueLabel(
          currentAppLocalizations.defaultScript,
          fallback: currentAppLocalizations.script,
        ),
        lastUpdateTime: DateTime.now(),
        url: _defaultScriptUrl,
        order: -1,
      ).save(await rootBundle.loadString(_defaultScriptAsset));
      await database.scriptsDao.putAll([script.toCompanion()]);
    }
    await preferences.setDefaultScriptSeeded();
    _defaultScriptInstalled = script != null;
  } catch (e) {
    commonPrint.log('default script not seeded: $e');
  }
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
