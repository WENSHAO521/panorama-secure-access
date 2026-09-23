import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/backup_and_restore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio({int? status, DioExceptionType? type}) {
  final options = RequestOptions(path: '/FlClash/backup.zip');
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('classifyBackupError', () {
    test('HTTP status and transport errors map to categories', () {
      expect(
        classifyBackupError(_dio(status: 401)),
        BackupErrorKind.unauthorized,
      );
      expect(
        classifyBackupError(_dio(status: 403)),
        BackupErrorKind.unauthorized,
      );
      expect(classifyBackupError(_dio(status: 404)), BackupErrorKind.notFound);
      expect(classifyBackupError(_dio(status: 503)), BackupErrorKind.server);
      expect(
        classifyBackupError(_dio(type: DioExceptionType.connectionTimeout)),
        BackupErrorKind.unreachable,
      );
      expect(
        classifyBackupError(_dio(type: DioExceptionType.connectionError)),
        BackupErrorKind.unreachable,
      );
      expect(classifyBackupError(StateError('x')), BackupErrorKind.failed);
    });
  });

  group('BackupHistory', () {
    final t0 = DateTime(2026, 9, 23, 10);

    test('records successes and a remote error; a later success clears it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final history = container.read(backupHistorySettingProvider.notifier);

      history.recordSuccess(BackupEvent.localBackup, at: t0);
      history.recordRemoteError(_dio(status: 401), at: t0);
      var state = container.read(backupHistorySettingProvider);
      expect(state.localBackupAt, t0);
      expect(state.remoteError, BackupErrorKind.unauthorized);
      expect(state.hasRemoteError, isTrue);

      history.recordSuccess(
        BackupEvent.remoteBackup,
        at: t0.add(const Duration(minutes: 1)),
      );
      state = container.read(backupHistorySettingProvider);
      expect(state.hasRemoteError, isFalse);
    });

    test('an error after the last success still shows', () {
      final h = BackupHistory(
        remoteBackupAt: t0,
        remoteError: BackupErrorKind.unreachable,
        remoteErrorAt: t0.add(const Duration(hours: 1)),
      );
      expect(h.hasRemoteError, isTrue);
    });

    test('is saved with the config; older configs load without it', () {
      final config = Config(
        themeProps: defaultThemeProps,
        backupHistory: BackupHistory(localBackupAt: t0),
      );
      // Persisted as JSON text.
      final json =
          jsonDecode(jsonEncode(config.toJson())) as Map<String, Object?>;
      expect(Config.fromJson(json).backupHistory.localBackupAt, t0);
      json.remove('backupHistory');
      expect(Config.fromJson(json).backupHistory, const BackupHistory());
    });

    test('the config builder includes it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(backupHistorySettingProvider.notifier)
          .recordSuccess(BackupEvent.remoteRestore, at: t0);
      expect(container.read(configProvider).backupHistory.remoteRestoreAt, t0);
    });
  });

  group('Backup page', () {
    late ProviderContainer container;

    tearDown(() => container.dispose());

    Future<void> pumpPage(
      WidgetTester tester, {
      BackupHistory history = const BackupHistory(),
      DAVProps? dav,
    }) async {
      container = ProviderContainer(
        overrides: [
          backupHistorySettingProvider.overrideWithBuild((_, _) => history),
          davSettingProvider.overrideWithBuild((_, _) => dav),
        ],
      );
      globalState.container = container;
      tester.view.physicalSize = const Size(390, 1200);
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
            home: const BackupAndRestore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('never-run actions say so', (tester) async {
      await pumpPage(tester);
      // Local backup and local restore.
      expect(find.text('Not yet'), findsNWidgets(2));
    });

    testWidgets('shows when each action last succeeded', (tester) async {
      await pumpPage(
        tester,
        history: BackupHistory(
          localBackupAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      );
      expect(find.text('Last: 3 hours ago'), findsOneWidget);
      expect(find.text('Not yet'), findsOneWidget);
    });

    testWidgets('a failed WebDAV attempt is explained, without the URL', (
      tester,
    ) async {
      await pumpPage(
        tester,
        dav: const DAVProps(
          uri: 'https://dav.example.com/secret-path',
          user: 'me',
          password: 'pw',
        ),
        history: BackupHistory(
          remoteError: BackupErrorKind.unauthorized,
          remoteErrorAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      expect(
        find.text('Last attempt failed: sign-in rejected'),
        findsOneWidget,
      );
      expect(find.textContaining('secret-path'), findsNothing);
      // The connection check reports in text, not only a coloured dot.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              const [
                'Checking…',
                'Reachable',
                "Can't connect",
              ].contains(w.data),
        ),
        findsOneWidget,
      );
    });
  });
}
