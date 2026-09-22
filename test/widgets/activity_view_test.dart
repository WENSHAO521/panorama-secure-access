import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/activity.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/views/connection/requests.dart';
import 'package:fl_clash/views/logs.dart';
import 'package:fl_clash/widgets/widgets.dart';
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

  Future<void> pumpActivity(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          // Inactive so ConnectionsView doesn't start polling the (absent)
          // core; these tests only cover the Activity shell itself.
          child: PageActivityScope(isActive: false, child: ActivityView()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows one Activity title with Connections and Requests', (
    tester,
  ) async {
    await pumpActivity(tester);

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Connections'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Logs'), findsNothing);
    expect(find.byType(ConnectionsView), findsOneWidget);
  });

  testWidgets('offers Logs only while log capture is enabled', (tester) async {
    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(openLogs: true));

    await pumpActivity(tester);

    expect(find.text('Logs'), findsOneWidget);
    // Let the settings update's debounced save fire before teardown.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('builds only the selected tab', (tester) async {
    await pumpActivity(tester);

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    expect(find.byType(RequestsView), findsOneWidget);
    expect(find.byType(ConnectionsView), findsNothing);
    expect(find.byType(LogsView), findsNothing);
    expect(find.text('Activity'), findsOneWidget);
  });

  testWidgets('falls back to Connections when Logs is turned off', (
    tester,
  ) async {
    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(openLogs: true));
    await pumpActivity(tester);

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(find.byType(LogsView), findsOneWidget);

    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(openLogs: false));
    await tester.pumpAndSettle();

    expect(find.byType(LogsView), findsNothing);
    expect(find.byType(ConnectionsView), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: child,
    );
  }
}
