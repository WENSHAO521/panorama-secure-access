import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/network_diagnosis.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/network_diagnosis.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

const _results = [
  DiagnosisResult(DiagnosisCheck.core, DiagnosisLevel.ok),
  DiagnosisResult(
    DiagnosisCheck.dns,
    DiagnosisLevel.failure,
    detail:
        'Failed host lookup: www.cloudflare.com (OS Error: '
        'Temporary failure in name resolution, errno = -3)',
    cause: DiagnosisCause.hostLookup,
    repair: DiagnosisRepair.flushDns,
  ),
  DiagnosisResult(
    DiagnosisCheck.ipv6,
    DiagnosisLevel.skipped,
    detail: 'Network is unreachable',
    cause: DiagnosisCause.notConfigured,
  ),
  DiagnosisResult(
    DiagnosisCheck.proxyRequest,
    DiagnosisLevel.failure,
    detail: 'HTTP 502',
    cause: DiagnosisCause.proxy,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pushPage(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    double pixelRatio = 1,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    container.read(viewSizeProvider.notifier).value = size;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          themeMode: themeMode,
          child: Builder(
            builder: (context) => FilledButton(
              onPressed: () => BaseNavigator.push(
                context,
                NetworkDiagnosisPage(
                  results: _results,
                  running: false,
                  onRun: () {},
                  onRepair: (_) {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  void expectContentBelowBar(WidgetTester tester) {
    final l10n = currentAppLocalizations;
    final summary = tester.getRect(find.text(l10n.networkDiagnosisProblems(2)));
    final title = tester.getRect(find.text(l10n.networkDiagnosis).last);
    final refresh = tester.getRect(find.byTooltip(l10n.networkDiagnosisRun));

    expect(summary.top, greaterThanOrEqualTo(title.bottom));
    expect(summary.top, greaterThanOrEqualTo(refresh.bottom));
    expect(summary.overlaps(title), isFalse);
    expect(summary.overlaps(refresh), isFalse);
  }

  for (final (name, size) in [
    ('a phone', const Size(390, 844)),
    ('a desktop window', const Size(1280, 800)),
  ]) {
    testWidgets('the summary starts below the bar on $name', (tester) async {
      await pushPage(tester, size: size);

      expectContentBelowBar(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large text at 200% scale in dark mode lays out without '
      'overflow', (tester) async {
    await pushPage(
      tester,
      size: const Size(360, 780),
      textScale: 2,
      pixelRatio: 2,
      themeMode: ThemeMode.dark,
    );

    expectContentBelowBar(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each failure shows its cause before the raw error', (
    tester,
  ) async {
    await pushPage(tester, size: const Size(1280, 800));
    final l10n = currentAppLocalizations;

    expect(find.text('${l10n.diagnosisProxyFault} · HTTP 502'), findsOne);
    expect(
      find.text('${l10n.diagnosisNotConfigured} · Network is unreachable'),
      findsOne,
    );
    expect(find.text(l10n.repairFlushDns), findsOne);
  });
}
