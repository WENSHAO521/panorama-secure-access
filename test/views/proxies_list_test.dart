import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/card.dart';
import 'package:fl_clash/views/proxies/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression coverage for the ProxiesListView refactor (lazy _buildLayout/
// _buildSlot per index instead of eagerly mapping every group's proxies
// into a Widget list before handing it to ListView.builder). The
// refactor's whole point is that ListView.builder's laziness now actually
// reaches widget construction, not just layout/paint — this proves that,
// rather than trusting the index arithmetic by inspection.

void main() {
  ProviderContainer? container;

  tearDown(() {
    container?.dispose();
  });

  Group buildGroup(String name, int proxyCount) {
    return Group(
      type: GroupType.Selector,
      name: name,
      all: List.generate(
        proxyCount,
        (i) => Proxy(name: '$name-proxy-$i', type: 'ss'),
      ),
    );
  }

  Future<void> pumpProxiesList(
    WidgetTester tester, {
    required List<Group> groups,
    required Set<String> currentUnfoldSet,
    int columns = 1,
  }) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    container = ProviderContainer(
      overrides: [
        proxiesListStateProvider.overrideWithValue(
          ProxiesListState(
            groups: groups,
            currentUnfoldSet: currentUnfoldSet,
            proxyCardType: ProxyCardType.expand,
            columns: columns,
          ),
        ),
        // ProxyCard reads the selected-proxy-per-group map, which chains
        // through the profiles database (Profiles -> profilesStreamProvider
        // -> a real drift/path_provider database connection) — mocked out
        // here so it resolves to "no profile" instead of touching a real
        // database that doesn't exist in the test environment.
        profilesStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    globalState.container = container!;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container!,
        child: const _TestApp(child: ProxiesListView()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'ProxiesListView lazily builds only visible ProxyCards for a large expanded group',
    (tester) async {
      final group = buildGroup('big', 300);
      await pumpProxiesList(
        tester,
        groups: [group],
        currentUnfoldSet: {'big'},
      );
      await tester.pump();

      final builtCards = find.byType(ProxyCard).evaluate().length;
      expect(builtCards, greaterThan(0));
      expect(builtCards, lessThan(group.all.length));
      expect(find.text('big-proxy-0', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProxiesListView renders the correct proxy names after scrolling deep into a large group',
    (tester) async {
      final group = buildGroup('big', 300);
      await pumpProxiesList(
        tester,
        groups: [group],
        currentUnfoldSet: {'big'},
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('big-proxy-299', findRichText: true),
        800,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down &&
              widget.controller != null,
        ),
      );

      expect(find.text('big-proxy-299', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProxiesListView shows only the header for a collapsed group and expands correctly',
    (tester) async {
      final collapsed = buildGroup('collapsed', 5);
      final expanded = buildGroup('expanded', 5);
      await pumpProxiesList(
        tester,
        groups: [collapsed, expanded],
        currentUnfoldSet: {'expanded'},
      );
      await tester.pump();

      expect(find.text('collapsed-proxy-0', findRichText: true), findsNothing);
      expect(find.text('expanded-proxy-0', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
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
      home: Scaffold(body: child),
    );
  }
}
