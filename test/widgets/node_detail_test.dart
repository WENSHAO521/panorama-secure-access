import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/node_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/network_insight/fake_service_http.dart';

void main() {
  late ProviderContainer container;
  late List<String> probed;
  late bool connected;

  setUp(() {
    probed = [];
    connected = true;
    container = ProviderContainer(
      overrides: [
        isStartProvider.overrideWith((ref) => connected),
        networkInsightSourcesProvider.overrideWithValue(
          NetworkInsightSources(
            lookupPublicIp: () async => null,
            httpFactory: () => FakeServiceHttp({}),
            listInterfaces: (_) async => const [],
            connectionKinds: () async => const {},
            startProbe: (name) async {
              probed.add(name);
              return 40000;
            },
            stopProbe: () async {},
            probeHttp: (_) => FakeServiceHttp({
              'https://1.1.1.1/': reply('ip=198.51.100.20\nloc=SG\n'),
              'https://[2606:4700:4700::1111]/': failWith(),
            }),
            nodeDelay: (_) async => 38,
            services: [
              ServiceDefinition(
                id: 'claude',
                name: 'Claude',
                category: ServiceCategory.ai,
                run: (_) async => const ServiceCheckOutcome(
                  ServiceCheckStatus.available,
                  regionCode: 'SG',
                ),
              ),
            ],
          ),
        ),
      ],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
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
          home: const Scaffold(
            body: NodeDetailSheet(
              proxy: Proxy(name: 'SG-01', type: 'Hysteria2'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('testing a node shows its exit, latency and services', (
    tester,
  ) async {
    await pumpSheet(tester);
    expect(find.text('Hysteria2'), findsOneWidget);
    expect(probed, isEmpty);

    await tester.tap(find.text('Test node'));
    await tester.pumpAndSettle();

    expect(probed, ['SG-01']);
    expect(find.text('38 ms'), findsOneWidget);
    expect(find.textContaining('198.51.100.20'), findsOneWidget);
    expect(find.text('Available · 🇸🇬 SG'), findsOneWidget);
    expect(find.text('1 of 1 available'), findsOneWidget);
  });

  testWidgets('explains that a node test needs a connection', (tester) async {
    connected = false;
    await pumpSheet(tester);

    await tester.tap(find.text('Test node'));
    await tester.pumpAndSettle();

    expect(probed, isEmpty);
    expect(find.text('Connect first to test this node.'), findsOneWidget);
  });
}
