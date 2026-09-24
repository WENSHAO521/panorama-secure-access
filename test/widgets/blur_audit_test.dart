import 'dart:ui';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/card.dart';
import 'package:fl_clash/widgets/blur_audit.dart';
import 'package:fl_clash/widgets/card.dart';
import 'package:fl_clash/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _blur() => BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
  child: const SizedBox(width: 10, height: 10),
);

void main() {
  group('visibleBackdropFilters (§102)', () {
    testWidgets('counts what the frame composited, not what is mounted', (
      tester,
    ) async {
      await tester.pumpWidget(
        Column(
          children: [
            _blur(),
            _blur(),
            Offstage(child: _blur()),
          ],
        ),
      );
      expect(visibleBackdropFilters(), 2);

      await tester.pumpWidget(const SizedBox());
      expect(visibleBackdropFilters(), 0);
    });

    testWidgets('one glass panel is one blur; nested glass adds none', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: GlassSurface.modal(
              child: GlassSurface.panel(child: SizedBox(height: 40)),
            ),
          ),
        ),
      );
      expect(visibleBackdropFilters(), 1);
    });

    testWidgets('the badge names the metric', (tester) async {
      await tester.pumpWidget(const BlurAuditBadge(count: 3));
      expect(find.text('visibleBackdropFilters: 3'), findsOneWidget);
    });
  });

  group('long lists stay unblurred (§103)', () {
    testWidgets('40 CommonCards composite no BackdropFilter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 40,
              itemExtent: 56,
              itemBuilder: (_, i) =>
                  CommonCard(onPressed: () {}, child: Text('item $i')),
            ),
          ),
        ),
      );
      expect(find.byType(CommonCard), findsWidgets);
      expect(visibleBackdropFilters(), 0);
    });

    testWidgets('a screen of proxy rows composites no BackdropFilter', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [profilesProvider.overrideWithBuild((_, _) => const [])],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
              body: ListView.builder(
                itemCount: 40,
                itemExtent: 64,
                itemBuilder: (_, i) => ProxyCard(
                  groupName: 'Proxy',
                  testUrl: null,
                  proxy: Proxy(name: 'node-$i', type: 'Hysteria2'),
                  groupType: GroupType.Selector,
                  type: ProxyCardType.row,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProxyCard), findsAtLeastNWidgets(10));
      expect(visibleBackdropFilters(), 0);
    });
  });
}
