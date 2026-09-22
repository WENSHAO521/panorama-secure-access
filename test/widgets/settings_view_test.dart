import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        // The navigation items read the profile database; the overflow
        // destinations aren't what these tests cover.
        moreToolsSelectorStateProvider.overrideWithValue(
          const MoreToolsSelectorState(navigationItems: []),
        ),
      ],
    );
    globalState.container = container;
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
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
          home: const SettingsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('groups settings in the brief §22 order', (tester) async {
    await pumpSettings(tester);

    final order = [
      'General',
      'Language',
      'Application',
      'Connection',
      'Network',
      'DNS',
      'Added rules',
      'On Demand',
      'Profiles',
      'Script',
      'Theme',
      'Backup and Restore',
      'Advanced',
      'Core',
      'About',
      'Disclaimer',
    ];
    for (final text in order) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    for (var i = 1; i < order.length; i++) {
      expect(
        top(tester, order[i]),
        greaterThan(top(tester, order[i - 1])),
        reason: '${order[i - 1]} before ${order[i]}',
      );
    }
  });

  testWidgets('the old intermediate pages are gone', (tester) async {
    await pumpSettings(tester);

    // Their rows are now listed directly (Network, DNS, … under Connection;
    // Core under Advanced).
    expect(find.text('Advanced configuration'), findsNothing);
    expect(find.text('Basic configuration'), findsNothing);
  });

  testWidgets('hides rows that do not apply to this platform', (tester) async {
    await pumpSettings(tester);

    // Tests run on a desktop host: hotkeys yes, Android per-app routing no.
    expect(
      find.text('Hotkey Management'),
      system.isDesktop ? findsOne : findsNothing,
    );
    expect(
      find.text('AccessControl'),
      system.isAndroid ? findsOne : findsNothing,
    );
    expect(
      find.text('Loopback unlock tool'),
      system.isWindows ? findsOne : findsNothing,
    );
  });

  testWidgets('Developer appears under Advanced once enabled', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Developer mode'), findsNothing);

    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(developerMode: true));
    await tester.pumpAndSettle();

    expect(find.text('Developer mode'), findsOneWidget);
    expect(top(tester, 'Developer mode'), greaterThan(top(tester, 'Core')));
    expect(top(tester, 'Developer mode'), lessThan(top(tester, 'About')));
  });
}
