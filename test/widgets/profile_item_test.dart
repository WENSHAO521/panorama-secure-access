import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/profiles/profiles.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    globalState.container = container;
  });

  tearDown(() {
    container.dispose();
  });

  final expiry = DateTime.now().add(const Duration(days: 60));
  final subscription = Profile(
    id: 1,
    label: 'Work',
    url: 'https://sub.example.com/link?token=SECRET123',
    autoUpdateDuration: const Duration(hours: 12),
    lastUpdateDate: DateTime.now().subtract(const Duration(hours: 3)),
    subscriptionInfo: SubscriptionInfo(
      download: 3 << 30,
      total: 12 << 30,
      expire: expiry.millisecondsSinceEpoch ~/ 1000,
    ),
  );
  const local = Profile(id: 2, label: 'Home', autoUpdateDuration: Duration());

  Future<void> pumpItem(
    WidgetTester tester,
    Profile profile, {
    int? current,
  }) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: globalState.navigatorKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          builder: (context, child) {
            globalState.measure = Measure.of(context, 1);
            globalState.theme = CommonTheme.of(context, 1);
            return child!;
          },
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ProfileItem(
                profile: profile,
                groupValue: current,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows name, source host, update time, traffic and expiry', (
    tester,
  ) async {
    await pumpItem(tester, subscription, current: 1);

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    expect(find.text('sub.example.com  ·  Updated 3 hours ago'), findsOne);
    expect(find.text('3GB / 12GB  ·  Expires ${expiry.show}'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // The subscription token never reaches the screen.
    expect(find.textContaining('SECRET123'), findsNothing);
  });

  testWidgets('a local profile shows no quota and no state', (tester) async {
    await pumpItem(tester, local);

    expect(find.text('Local file'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('In use'), findsNothing);
  });

  testWidgets('the menu has the brief §74 actions', (tester) async {
    await pumpItem(tester, subscription);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    for (final label in [
      'Update',
      'Edit',
      'Duplicate',
      'Export file',
      'More',
      'Delete',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('a local file cannot be updated', (tester) async {
    await pumpItem(tester, local);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsNothing);
    expect(find.text('Duplicate'), findsOneWidget);
  });

  testWidgets('right click opens the same menu', (tester) async {
    await pumpItem(tester, subscription);

    await tester.tap(find.text('Work'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    expect(find.text('Duplicate'), findsOneWidget);
  });

  testWidgets('long press opens the same menu', (tester) async {
    await pumpItem(tester, subscription);

    await tester.longPress(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate'), findsOneWidget);
  });
}
