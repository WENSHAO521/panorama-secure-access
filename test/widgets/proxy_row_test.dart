import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 23, 12);

ServiceCheckResult _result(
  String id,
  ServiceCategory category,
  ServiceCheckStatus status, [
  String? region,
]) => ServiceCheckResult(
  serviceId: id,
  serviceName: id,
  category: category,
  status: status,
  regionCode: region,
);

NodeReport _report({
  List<ServiceCheckResult> services = const [],
  DateTime? checkedAt,
  bool isRunning = false,
}) => NodeReport(
  proxyName: 'JP-01',
  services: services,
  checkedAt: checkedAt ?? _now,
  isRunning: isRunning,
);

void main() {
  group('NodeCapability', () {
    test('untested or running: nothing to show', () {
      expect(NodeCapability.of(null), isNull);
      expect(NodeCapability.of(_report(isRunning: true)), isNull);
      expect(NodeCapability.of(const NodeReport(proxyName: 'JP-01')), isNull);
    });

    test('AI counts and the Netflix region first', () {
      final c = NodeCapability.of(
        _report(
          services: [
            _result(
              'chatgpt',
              ServiceCategory.ai,
              ServiceCheckStatus.available,
            ),
            _result('claude', ServiceCategory.ai, ServiceCheckStatus.available),
            _result('gemini', ServiceCategory.ai, ServiceCheckStatus.blocked),
            _result(
              'disney_plus',
              ServiceCategory.streaming,
              ServiceCheckStatus.available,
              'US',
            ),
            _result(
              'netflix',
              ServiceCategory.streaming,
              ServiceCheckStatus.limited,
              'JP',
            ),
            _result(
              'spotify',
              ServiceCategory.streaming,
              ServiceCheckStatus.checking,
            ),
          ],
        ),
        now: _now,
      )!;
      expect(c.aiChecked, 3);
      expect(c.aiAvailable, 2);
      // Still-running checks aren't counted.
      expect(c.streamingChecked, 2);
      expect(c.streamingUsable, 2);
      expect(c.streamingRegion, 'JP');
      expect(c.isStale, isFalse);
    });

    test('an old report is stale', () {
      final c = NodeCapability.of(
        _report(checkedAt: _now.subtract(const Duration(hours: 1))),
        now: _now,
      )!;
      expect(c.isStale, isTrue);
    });
  });

  group('ProxyCard rows', () {
    late ProviderContainer container;
    const proxy = Proxy(name: 'JP-01', type: 'Hysteria2');

    ProviderContainer build([Map<String, NodeReport> reports = const {}]) {
      return ProviderContainer(
        overrides: [
          // Keeps the selection lookup off the profile database.
          profilesProvider.overrideWithBuild((_, _) => const []),
          nodeDiagnosticsProvider.overrideWithBuild((_, _) => reports),
        ],
      );
    }

    tearDown(() => container.dispose());

    Future<void> pumpRow(WidgetTester tester, ProviderContainer c) async {
      container = c;
      globalState.container = c;
      tester.view.physicalSize = const Size(390, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
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
            home: const Scaffold(
              body: SizedBox(
                height: 64,
                child: ProxyCard(
                  groupName: 'Proxy',
                  testUrl: null,
                  proxy: proxy,
                  groupType: GroupType.Selector,
                  type: ProxyCardType.row,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an untested node shows its protocol only', (tester) async {
      await pumpRow(tester, build());

      expect(find.text('JP-01', findRichText: true), findsOneWidget);
      expect(find.text('Hysteria2'), findsOneWidget);
    });

    testWidgets('a tested node adds the capability hint (§52)', (tester) async {
      await pumpRow(
        tester,
        build({
          'JP-01': _report(
            services: [
              _result(
                'claude',
                ServiceCategory.ai,
                ServiceCheckStatus.available,
              ),
              _result(
                'netflix',
                ServiceCategory.streaming,
                ServiceCheckStatus.available,
                'JP',
              ),
            ],
          ),
        }),
      );

      expect(
        find.text('Hysteria2  ·  AI 1/1  ·  Streaming JP'),
        findsOneWidget,
      );
    });

    testWidgets('long press and right click open the §48 menu', (tester) async {
      await pumpRow(tester, build());

      await tester.longPress(find.text('Hysteria2'));
      await tester.pumpAndSettle();
      for (final label in [
        'Delay Test',
        'Test node',
        'Node details',
        'Copy name',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tapAt(const Offset(5, 250));
      await tester.pumpAndSettle();
      expect(find.text('Copy name'), findsNothing);

      await tester.tap(find.text('Hysteria2'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.text('Copy name'), findsOneWidget);
    });
  });
}
