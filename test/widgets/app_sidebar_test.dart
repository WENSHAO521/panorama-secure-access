import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/manager/app_manager.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Navigation per layout class (brief §92-94): bottom bar on compact (owned
/// by HomePage, so no rail here), rail on medium, sidebar on expanded.
void main() {
  final items = [
    for (final label in [PageLabel.dashboard, PageLabel.proxies])
      NavigationItem(
        icon: const Icon(Icons.circle),
        label: label,
        builder: (_) => const SizedBox(),
      ),
  ];

  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    bool showLabel = false,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        // A fresh scope per pump: overrides of a mounted scope don't rebuild.
        key: UniqueKey(),
        overrides: [
          viewSizeProvider.overrideWithBuild((_, _) => Size(width, 800)),
          navigationItemsStateProvider.overrideWithValue(
            NavigationItemsState(value: items),
          ),
          appSettingProvider.overrideWithBuild(
            (_, _) => AppSettingProps(showLabel: showLabel),
          ),
        ],
        child: const MaterialApp(
          home: AppSidebarContainer(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  NavigationRail rail(WidgetTester tester) =>
      tester.widget<NavigationRail>(find.byType(NavigationRail));

  testWidgets('compact: no rail', (tester) async {
    await pumpAt(tester, 400);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('medium: a rail, labels follow the toggle', (tester) async {
    await pumpAt(tester, 800);
    expect(rail(tester).extended, isFalse);
    expect(rail(tester).labelType, NavigationRailLabelType.none);
    expect(find.byType(IconButton), findsOneWidget);

    await pumpAt(tester, 800, showLabel: true);
    expect(rail(tester).labelType, NavigationRailLabelType.all);
  });

  testWidgets('expanded: a sidebar with labels, no label toggle', (
    tester,
  ) async {
    await pumpAt(tester, 1280);
    expect(rail(tester).extended, isTrue);
    expect(find.text('dashboard'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('the same class boundaries as PanoramaLayoutClass', (
    tester,
  ) async {
    await pumpAt(tester, 1023);
    expect(rail(tester).extended, isFalse);
    await pumpAt(tester, 1024);
    expect(rail(tester).extended, isTrue);
  });
}
