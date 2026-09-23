import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Log _log(
  String payload, {
  LogLevel level = LogLevel.info,
  String at = '2026-09-23 10:15:42',
}) => Log(payload: payload, logLevel: level, dateTime: at);

void main() {
  group('splitLogLine', () {
    test('module from the leading [tag], time without the date', () {
      final parts = splitLogLine(
        _log('[TCP] 192.168.1.20:51000 --> claude.ai:443 using JP-01'),
      );
      expect(parts.time, '10:15:42');
      expect(parts.module, 'TCP');
      expect(parts.message, '192.168.1.20:51000 --> claude.ai:443 using JP-01');
    });

    test('lines without a tag have no module', () {
      final parts = splitLogLine(_log('Start initial configuration'));
      expect(parts.module, '');
      expect(parts.message, 'Start initial configuration');
    });

    test('a bracketed address is not a module', () {
      final parts = splitLogLine(_log('[2001:db8::1]:443 unreachable'));
      expect(parts.module, '');
    });

    test('copied line keeps the full date, level and module', () {
      expect(
        logLineText(_log('[DNS] resolve failed', level: LogLevel.warning)),
        '2026-09-23 10:15:42 WRN [DNS] resolve failed',
      );
    });
  });

  group('LogsView', () {
    late ProviderContainer container;
    String? clipboard;

    setUp(() {
      container = ProviderContainer();
      globalState.container = container;
      container.read(logsProvider.notifier).value = FixedList(500);
      clipboard = null;
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> pumpLogs(WidgetTester tester, {double width = 1024}) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
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
            home: const LogsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    void add(Log log) => container.read(logsProvider.notifier).add(log);

    // New lines reach the view through a throttle and a post-frame callback.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets('shows time, level, module and message', (tester) async {
      add(_log('[TCP] a.example:443 using JP-01'));
      await pumpLogs(tester);

      expect(find.text('10:15:42'), findsOneWidget);
      expect(find.text('INF'), findsOneWidget);
      expect(find.text('TCP'), findsOneWidget);
      expect(find.text('a.example:443 using JP-01'), findsOneWidget);
    });

    testWidgets('pause holds the view and counts new lines', (tester) async {
      add(_log('first'));
      await pumpLogs(tester);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      add(_log('second', at: '2026-09-23 10:15:43'));
      add(_log('third', at: '2026-09-23 10:15:44'));
      await settle(tester);

      expect(find.text('second'), findsNothing);
      expect(find.text('Paused · 2 new lines'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await settle(tester);

      expect(find.text('second'), findsOneWidget);
      expect(find.text('third'), findsOneWidget);
      expect(find.textContaining('Paused'), findsNothing);
    });

    testWidgets('copy all copies the visible lines', (tester) async {
      add(_log('[DNS] one'));
      add(_log('two', level: LogLevel.error, at: '2026-09-23 10:15:43'));
      await pumpLogs(tester);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy all'));
      await tester.pumpAndSettle();

      expect(clipboard, isNotNull);
      expect(clipboard, contains('2026-09-23 10:15:42 INF [DNS] one'));
      expect(clipboard, contains('2026-09-23 10:15:43 ERR two'));
    });

    testWidgets('clear empties the log', (tester) async {
      add(_log('one'));
      await pumpLogs(tester);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear logs'));
      await settle(tester);

      expect(container.read(logsProvider).list, isEmpty);
      expect(find.text('one'), findsNothing);
    });

    testWidgets('narrow: the message goes under the meta line', (tester) async {
      add(_log('[TCP] message text'));
      await pumpLogs(tester, width: 390);

      final meta = tester.getTopLeft(find.text('TCP'));
      final message = tester.getTopLeft(find.text('message text'));
      expect(message.dy, greaterThan(meta.dy));
    });
  });
}
