import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart' as prism show ListHeader, Switch;

import '../helpers/test_app.dart';

IconButtonData _action(String tooltip) =>
    IconButtonData(glyph: Glyphs.sort, tooltip: tooltip, onPressed: () {});

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  var _on = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      title: 'Page',
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: generateSection(
              title: 'Switches',
              actions: [_action('a'), _action('b'), _action('c')],
              footer: 'Footer',
              items: [
                ListItem.toggle(
                  leading: const GlyphIcon(Glyphs.sort),
                  title: const Text('Toggle'),
                  value: _on,
                  onChanged: (value) => setState(() => _on = value),
                ),
                const ListItem(
                  leading: GlyphIcon(Glyphs.sort),
                  title: Text('Plain'),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: generateSection(items: [const ListItem(title: Text('Gap'))]),
          ),
          SliverToBoxAdapter(
            child: generateAnimatedSection(
              title: 'Animated',
              footer: 'Animated footer',
              items: [const ListItem(key: ValueKey(1), title: Text('A'))],
            ),
          ),
          generateSliverSection<int>(
            title: 'Sliver',
            footer: 'Sliver footer',
            items: const [1, 2],
            itemBuilder: (item) => ListItem(title: Text('Row $item')),
          ),
          generateSliverSection<int>(
            items: const [3],
            itemBuilder: (item) => ListItem(title: Text('Row $item')),
          ),
          generateSliverSection<int>(
            items: const [],
            itemBuilder: (item) => ListItem(title: Text('Row $item')),
          ),
          const SliverToBoxAdapter(
            child: ListHeader(title: 'Trailing', trailing: Text('T')),
          ),
          const SliverToBoxAdapter(
            child: Switch(value: true, onChanged: null, semanticLabel: 'Off'),
          ),
        ],
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required bool enabled,
  bool lit = false,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: StarChartColors.gold,
      brightness: brightness,
    ).toStarChart(),
  );
  final container = ProviderContainer();
  addTearDown(container.dispose);
  globalState.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TestApp(
        theme: theme,
        darkTheme: theme,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        child: StarChartScope(enabled: enabled, lit: lit, child: const _Page()),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
}

bool _framed(Decoration decoration) => decoration is StarFrameDecoration;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('dresses a page in the star chart look, $brightness', (
      tester,
    ) async {
      await _pump(tester, enabled: true, lit: true, brightness: brightness);

      expect(find.byType(StarChartBackdrop), findsOneWidget);
      expect(
        tester.widget<StarChartBackdrop>(find.byType(StarChartBackdrop)).lit,
        isTrue,
      );
      expect(find.byType(prism.ListHeader), findsNothing);
      expect(find.byType(prism.Switch), findsNothing);
      expect(find.byType(YaoSwitch), findsNWidgets(2));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is DecoratedBox && _framed(widget.decoration),
        ),
        findsNWidgets(3),
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is DecoratedSliver && _framed(widget.decoration),
        ),
        findsNWidgets(2),
      );
      for (final text in ['Footer', 'Animated footer', 'Sliver footer']) {
        expect(find.text(text), findsOneWidget);
      }
      final title = tester.widget<Text>(find.text('Switches'));
      expect(title.style?.fontFamily, starChartSerifFamilies.first);
      expect(title.style?.color, StarChartColors.giltOf(brightness));

      final toggle = find.byType(YaoSwitch).first;
      expect(tester.widget<YaoSwitch>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<YaoSwitch>(toggle).value, isTrue);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keeps prism_ui widgets with the look off', (tester) async {
    await _pump(tester, enabled: false);

    expect(find.byType(StarChartBackdrop), findsNothing);
    expect(find.byType(YaoSwitch), findsNothing);
    expect(find.byType(prism.Switch), findsNWidgets(2));
    expect(find.byType(prism.ListHeader), findsNWidgets(4));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            (widget is DecoratedBox && _framed(widget.decoration)) ||
            (widget is DecoratedSliver && _framed(widget.decoration)),
      ),
      findsNothing,
    );
  });

  testWidgets('a widget that reads only enabled ignores lit', (tester) async {
    var builds = 0;
    final child = Builder(
      builder: (context) {
        builds++;
        return Text(
          '${StarChartScope.of(context)}',
          textDirection: TextDirection.ltr,
        );
      },
    );
    Widget scope({required bool lit}) =>
        StarChartScope(enabled: true, lit: lit, child: child);
    await tester.pumpWidget(scope(lit: false));
    await tester.pumpWidget(scope(lit: true));
    expect(builds, 1);
  });

  test('frames compare by radius and color', () {
    final a = StarFrameDecoration(
      radius: AppRadius.all(AppCorner.xl),
      color: StarChartColors.gold,
    );
    final b = StarFrameDecoration(
      radius: AppRadius.all(AppCorner.xl),
      color: StarChartColors.gold,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(
        StarFrameDecoration(
          radius: AppRadius.all(AppCorner.md),
          color: StarChartColors.gold,
        ),
      ),
    );
  });

  test('the backdrop painter repaints on what it draws from', () {
    const painter = StarChartBackdropPainter(
      brightness: Brightness.dark,
      lit: 0,
    );
    expect(painter.shouldRepaint(painter), isFalse);
    expect(
      painter.shouldRepaint(
        const StarChartBackdropPainter(brightness: Brightness.dark, lit: 1),
      ),
      isTrue,
    );
  });
}
