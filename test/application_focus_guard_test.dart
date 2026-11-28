import 'package:fl_clash/application.dart';
import 'package:fl_clash/manager/manager.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const app = SizedBox.shrink();

  test('without a desktop window the app is used as it is', () {
    expect(guardHiddenWindowFocus(app, null), same(app));
  });

  test('a desktop window guards the app by whether it is shown', () {
    final shown = ValueNotifier(false);
    addTearDown(shown.dispose);

    final guarded = guardHiddenWindowFocus(app, shown);

    expect(guarded, isA<HiddenWindowFocusGuard>());
    guarded as HiddenWindowFocusGuard;
    expect(guarded.shown, same(shown));
    expect(guarded.child, same(app));
  });

  test('a stable build is no prerelease and cannot crash the core', () {
    globalState.appEnv = 'stable';

    expect(globalState.isPre, isFalse);
    expect(globalState.canCrashCore, kDebugMode);
  });
}
