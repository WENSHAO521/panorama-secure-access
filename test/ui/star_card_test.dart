import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart' as prism show Card;

import '../helpers/test_app.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool enabled = true,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = ThemeData(
    colorScheme: appColorScheme(
      seedColor: StarChartColors.goldInk,
      brightness: brightness,
      style: AppColorStyle.xingGuan,
    ),
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
        child: StarChartScope(
          enabled: enabled,
          child: Column(children: [child]),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

StarFrameDecoration? _frameOf(WidgetTester tester, Finder of) {
  final boxes = find.ancestor(of: of, matching: find.byType(DecoratedBox));
  for (final element in boxes.evaluate()) {
    final decoration = (element.widget as DecoratedBox).decoration;
    if (decoration is StarFrameDecoration) {
      return decoration;
    }
  }
  return null;
}

Widget _rows(List<Widget> rows) => Column(
  children: [
    for (final (index, row) in rows.indexed)
      ItemPositionProvider(
        position: ItemPosition.get(index, rows.length),
        child: row,
      ),
  ],
);

void main() {
  testWidgets('a card is framed, in gilt once chosen', (tester) async {
    await _pump(
      tester,
      Column(
        children: [
          Card(onPressed: () {}, child: const Text('plain')),
          Card(isSelected: true, onPressed: () {}, child: const Text('chosen')),
          Card(frameInner: false, onPressed: () {}, child: const Text('tile')),
        ],
      ),
    );
    const brightness = Brightness.dark;
    final plain = _frameOf(tester, find.text('plain'))!;
    expect(plain.color, StarChartColors.hairlineOf(brightness));
    expect(plain.inner, isTrue);
    expect(
      _frameOf(tester, find.text('chosen'))!.color,
      StarChartColors.chosenHairlineOf(brightness),
    );
    expect(_frameOf(tester, find.text('tile'))!.inner, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pill frames to its shape and a filled pick keeps one line', (
    tester,
  ) async {
    await _pump(
      tester,
      Card(
        isSelected: true,
        fillsSelection: true,
        shape: AppShape.full,
        onPressed: () {},
        child: const Text('tab'),
      ),
      brightness: Brightness.light,
    );
    final frame = _frameOf(tester, find.text('tab'))!;
    expect(frame.radius, AppRadius.full);
    expect(frame.inner, isFalse);
    expect(frame.color, StarChartColors.hairlineOf(Brightness.light));
  });

  testWidgets('an error card, a nested card and the classic look stay '
      'unframed', (tester) async {
    await _pump(
      tester,
      Column(
        children: [
          Card(isError: true, onPressed: () {}, child: const Text('error')),
          Card(framed: false, onPressed: () {}, child: const Text('nested')),
        ],
      ),
    );
    expect(_frameOf(tester, find.text('error')), isNull);
    expect(_frameOf(tester, find.text('nested')), isNull);

    await _pump(
      tester,
      Card(onPressed: () {}, child: const Text('classic')),
      enabled: false,
    );
    expect(_frameOf(tester, find.text('classic')), isNull);
    expect(find.byType(prism.Card), findsOneWidget);
    expect(
      Card.minimumOf(tester.element(find.text('classic'))),
      prism.Card.minimumOf(tester.element(find.text('classic'))),
    );
    expect(
      Card.paddingOf(
        tester.element(find.text('classic')),
        const EdgeInsets.all(8),
      ),
      const EdgeInsets.all(8),
    );
  });

  testWidgets('rows outside a framed group join into one frame by place', (
    tester,
  ) async {
    await _pump(
      tester,
      _rows([
        DecorationListItem(title: const Text('first'), onPressed: () {}),
        DecorationListItem(title: const Text('middle'), onPressed: () {}),
        SelectedDecorationListItem(
          isSelected: true,
          onSelected: () {},
          onPressed: () {},
          title: const Text('last'),
        ),
      ]),
    );
    final first = _frameOf(tester, find.text('first'))!;
    final middle = _frameOf(tester, find.text('middle'))!;
    final last = _frameOf(tester, find.text('last'))!;
    expect((first.openTop, first.openBottom), (false, true));
    expect((middle.openTop, middle.openBottom), (true, true));
    expect((last.openTop, last.openBottom), (true, false));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lone row is closed, and rows in a section leave the frame '
      'to it', (tester) async {
    await _pump(
      tester,
      Column(
        children: [
          _rows([const DecorationListItem(title: Text('lone'))]),
          generateSection(
            items: [const DecorationListItem(title: Text('grouped'))],
          ),
        ],
      ),
    );
    final lone = _frameOf(tester, find.text('lone'))!;
    expect((lone.openTop, lone.openBottom), (false, false));
    final grouped = find.ancestor(
      of: find.text('grouped'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox && widget.decoration is StarFrameDecoration,
      ),
    );
    expect(grouped, findsOneWidget);
  });

  testWidgets('a hand-made surface takes the frame only under the look', (
    tester,
  ) async {
    Widget framed() => const StarFramed(
      radius: AppRadius.xl,
      chosen: true,
      openTop: true,
      child: SizedBox(width: 100, height: 40, child: Text('box')),
    );
    await _pump(tester, framed());
    final frame = _frameOf(tester, find.text('box'))!;
    expect(frame.openTop, isTrue);
    expect(frame.color, StarChartColors.chosenHairlineOf(Brightness.dark));

    await _pump(tester, framed(), enabled: false);
    expect(_frameOf(tester, find.text('box')), isNull);
  });

  test('frames compare by every field', () {
    StarFrameDecoration frame({
      bool openTop = false,
      bool openBottom = false,
      bool inner = true,
    }) => StarFrameDecoration(
      radius: AppRadius.xl,
      color: StarChartColors.gold,
      openTop: openTop,
      openBottom: openBottom,
      inner: inner,
    );
    expect(frame(), frame());
    expect(frame().hashCode, frame().hashCode);
    expect(frame(openTop: true), isNot(frame()));
    expect(frame(openBottom: true), isNot(frame()));
    expect(frame(inner: false), isNot(frame()));
  });
}
