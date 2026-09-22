import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/features/network_insight/identity.dart';
import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/network_insight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/network_insight/fake_service_http.dart';

void main() {
  late ProviderContainer container;
  late Map<String, int> runs;
  late int lookups;

  ServiceDefinition service(
    String id,
    String name,
    ServiceCheckOutcome outcome,
  ) {
    return ServiceDefinition(
      id: id,
      name: name,
      category: ServiceCategory.streaming,
      run: (_) async {
        runs[id] = (runs[id] ?? 0) + 1;
        return outcome;
      },
    );
  }

  setUp(() {
    runs = {};
    lookups = 0;
    container = ProviderContainer(
      overrides: [
        serviceRouteKeyProvider.overrideWithValue('p|rule|Proxy=JP'),
        networkInsightSourcesProvider.overrideWithValue(
          NetworkInsightSources(
            lookupPublicIp: () async {
              lookups++;
              return const IpInfo(
                ip: '203.0.113.7',
                countryCode: 'JP',
                countryName: 'Japan',
                isp: 'IIJ',
                asn: 2497,
              );
            },
            httpFactory: () => FakeServiceHttp({
              'https://1.1.1.1/': reply('ip=203.0.113.7\nloc=JP\n'),
              'https://[2606:4700:4700::1111]/': failWith(),
            }),
            listInterfaces: (_) async => const [],
            connectionKinds: () async => {ConnectionKind.ethernet},
            services: [
              service(
                'netflix',
                'Netflix',
                const ServiceCheckOutcome(
                  ServiceCheckStatus.limited,
                  message: serviceNoteOriginalsOnly,
                ),
              ),
              service(
                'disney_plus',
                'Disney+',
                const ServiceCheckOutcome(
                  ServiceCheckStatus.available,
                  regionCode: 'JP',
                ),
              ),
              service(
                'prime_video',
                'Prime Video',
                const ServiceCheckOutcome(ServiceCheckStatus.ipRestricted),
              ),
            ],
          ),
        ),
      ],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pumpView(WidgetTester tester) async {
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
          home: const NetworkInsightView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opening the page reads identity but checks no services', (
    tester,
  ) async {
    await pumpView(tester);

    expect(lookups, 1);
    expect(runs, isEmpty);
    expect(find.text('203.0.113.7'), findsOneWidget);
    expect(find.textContaining('AS2497'), findsOneWidget);
    expect(find.text('Not checked'), findsNWidgets(3));
  });

  testWidgets('Check all fills every row with a text status', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Check all'));
    await tester.pumpAndSettle();

    expect(runs, {'netflix': 1, 'disney_plus': 1, 'prime_video': 1});
    expect(find.text('Limited'), findsOneWidget);
    expect(find.text('Originals only'), findsOneWidget);
    expect(find.text('Available · 🇯🇵 JP'), findsOneWidget);
    expect(find.text('IP restricted'), findsOneWidget);
    expect(find.text('1 of 3 available'), findsOneWidget);
  });

  testWidgets('tapping a row re-checks only that service', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Prime Video'));
    await tester.pumpAndSettle();

    expect(runs, {'prime_video': 1});
    expect(find.text('IP restricted'), findsOneWidget);
    expect(find.text('Not checked'), findsNWidgets(2));
  });
}
