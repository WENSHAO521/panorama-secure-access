import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/beta_program.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late List<Config> saved;
  late bool saveSucceeds;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
    globalState.releaseTag = 'v3.5.9-beta.343';
    container.read(viewSizeProvider.notifier).value = const Size(1000, 1600);
    saved = [];
    saveSucceeds = true;
    BetaProgramView.saveConfig = (config) async {
      saved.add(config);
      return saveSucceeds;
    };
  });

  tearDown(() {
    container.dispose();
    globalState.releaseTag = '';
    BetaProgramView.saveConfig = preferences.saveConfig;
  });

  bool joined() => container.read(appSettingProvider).betaUpdates;

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: BetaProgramView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester) async {
    await tester.tap(find.text(currentAppLocalizations.betaUpdates));
    await tester.pumpAndSettle();
  }

  testWidgets('joining waits for the confirmation and the save', (
    tester,
  ) async {
    await pumpView(tester);
    final l10n = currentAppLocalizations;

    await toggle(tester);
    expect(find.text(l10n.betaJoinConfirmTitle), findsOne);
    expect(joined(), isFalse);

    await tester.tap(find.text(l10n.betaJoinConfirm));
    await tester.pumpAndSettle();

    expect(joined(), isTrue);
    expect(saved.single.appSettingProps.betaUpdates, isTrue);
  });

  testWidgets('cancelling or dismissing keeps the channel', (tester) async {
    await pumpView(tester);
    final l10n = currentAppLocalizations;

    await toggle(tester);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(joined(), isFalse);

    await toggle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(l10n.betaJoinConfirmTitle), findsNothing);
    expect(joined(), isFalse);
    expect(saved, isEmpty);
  });

  testWidgets('a failed save keeps the channel and says so', (tester) async {
    saveSucceeds = false;
    await pumpView(tester);
    final l10n = currentAppLocalizations;

    await toggle(tester);
    await tester.tap(find.text(l10n.betaJoinConfirm));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(joined(), isFalse);
    expect(find.text(l10n.betaChannelSaveFailed), findsOne);
  });

  testWidgets('leaving asks with its own wording and keeps the beta on '
      'Keep the beta', (tester) async {
    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(betaUpdates: true));
    await pumpView(tester);
    final l10n = currentAppLocalizations;

    expect(find.text(l10n.updateChannel), findsOne);
    expect(find.text(l10n.installedVersion), findsOne);
    expect(find.text('v3.5.9-beta.343'), findsOne);

    await toggle(tester);
    expect(find.text(l10n.betaLeaveConfirmTitle), findsOne);
    await tester.tap(find.text(l10n.betaStay));
    await tester.pumpAndSettle();
    expect(joined(), isTrue);

    await toggle(tester);
    await tester.tap(find.text(l10n.betaLeaveConfirm));
    await tester.pumpAndSettle();
    expect(joined(), isFalse);
    expect(saved.single.appSettingProps.betaUpdates, isFalse);
  });

  testWidgets('a double tap asks only once', (tester) async {
    await pumpView(tester);
    final l10n = currentAppLocalizations;

    await tester.tap(find.text(l10n.betaUpdates));
    await tester.tap(find.text(l10n.betaUpdates));
    await tester.pumpAndSettle();

    expect(find.text(l10n.betaJoinConfirmTitle), findsOne);
    await tester.tap(find.text(l10n.betaJoinConfirm));
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(joined(), isTrue);
  });
}
