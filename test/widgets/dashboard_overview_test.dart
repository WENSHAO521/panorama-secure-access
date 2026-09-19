import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/overview.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashboardOverview shows live controls and opens profiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        coreStatusProvider.overrideWithValue(CoreStatus.connected),
        isStartProvider.overrideWithValue(true),
        runTimeProvider.overrideWithValue(3_723_000),
        currentProfileProvider.overrideWithValue(
          Profile.normal(label: 'Helsinki'),
        ),
        patchClashConfigProvider.overrideWithValue(defaultClashConfig),
        networkSettingProvider.overrideWithValue(defaultNetworkProps),
        trafficsProvider.overrideWithValue(
          FixedList<Traffic>(
            4,
            list: [
              const Traffic(up: 1024 * 1024, down: 2 * 1024 * 1024),
              const Traffic(up: 2 * 1024 * 1024, down: 3 * 1024 * 1024),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: DashboardOverview()),
      ),
    );
    await tester.pump();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Helsinki'), findsOneWidget);
    expect(find.text('Outbound mode'), findsOneWidget);
    expect(find.byType(LineChart), findsNWidgets(2));
    final previousGoldenFileComparator = goldenFileComparator;
    goldenFileComparator = _PaperlineGoldenFileComparator(
      Uri.parse('test/widgets/dashboard_overview_test.dart'),
    );
    addTearDown(() => goldenFileComparator = previousGoldenFileComparator);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dashboard_overview.png'),
    );

    tester.view.physicalSize = const Size(480, 900);
    await tester.pump();

    expect(find.byType(LineChart), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1440, 1024);
    await tester.pump();

    await tester.tap(find.text('Helsinki'));
    await tester.pump();

    expect(container.read(currentPageLabelProvider), PageLabel.profiles);
    expect(tester.takeException(), isNull);
  });
}

class _PaperlineGoldenFileComparator extends LocalFileComparator {
  _PaperlineGoldenFileComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= 0.01;
    if (passed) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
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
      home: Scaffold(body: child),
    );
  }
}
