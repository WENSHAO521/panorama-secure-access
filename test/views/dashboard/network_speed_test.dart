import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/dipper_gauge.dart';
import 'package:fl_clash/views/dashboard/widgets/traffic.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/host_scaffold.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_profiles.dart';

class _MockCore extends Mock implements CoreHandlerInterface {}

const _size = Size(400, 800);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockCore core;
  late ProviderContainer container;

  setUp(() {
    core = _MockCore();
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(TestProfiles.new),
        coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
        coreStatusProvider.overrideWithBuild((_, _) => CoreStatus.connected),
      ],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    container.read(viewSizeProvider.notifier).value = _size;
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: HostScaffold(body: ListView(children: [card])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> teardownCard(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  void addTraffic(Traffic traffic) =>
      container.read(trafficsProvider.notifier).addTraffic(traffic);

  Rect figureIn(WidgetTester tester, Finder card) => tester.getRect(
    find.descendant(
      of: card,
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_Figure',
      ),
    ),
  );

  Finder tileOf(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_SpeedTile',
    ),
  );

  testWidgets('reads each direction\'s speed and session total', (
    tester,
  ) async {
    addTraffic(const Traffic(up: 2048, down: 4096));
    addTraffic(const Traffic(up: 1024, down: 3072));
    container.read(totalTrafficProvider.notifier).value = const Traffic(
      up: 5120,
      down: 6144,
    );

    await pumpCard(tester, const NetworkSpeedCard());

    final upload = tileOf('Upload');
    final download = tileOf('Download');
    Finder inTile(Finder tile, String text) =>
        find.descendant(of: tile, matching: find.textContaining(text));
    expect(inTile(upload, '${_traffic(1024)}/s'), findsOneWidget);
    expect(inTile(upload, 'Total ${_traffic(5120)}'), findsOneWidget);
    expect(inTile(download, '${_traffic(3072)}/s'), findsOneWidget);
    expect(inTile(download, 'Total ${_traffic(6144)}'), findsOneWidget);
    expect(find.textContaining(_traffic(4096)), findsNothing);

    await teardownCard(tester);
  });

  testWidgets(
    'a phone tile keeps its ratio and arches its stars under its title',
    (tester) async {
      await pumpCard(tester, const NetworkSpeedCard());

      for (final label in ['Upload', 'Download']) {
        final tile = tileOf(label);
        final rect = tester.getRect(tile);
        expect(rect.height, closeTo(rect.width / 1.2, 0.5));

        final chart = tester.getRect(
          find.descendant(of: tile, matching: find.byType(DipperGauge)),
        );
        final title = tester.getRect(
          find.descendant(of: tile, matching: find.text(label)),
        );
        expect(chart.top, greaterThanOrEqualTo(title.bottom));
        expect(chart.bottom, lessThanOrEqualTo(figureIn(tester, tile).top));
      }

      await teardownCard(tester);
    },
  );

  testWidgets('a phone tile grows rather than clip a scaled up total', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpCard(tester, const NetworkSpeedCard());

    final rect = tester.getRect(tileOf('Upload'));
    expect(rect.height, greaterThan(rect.width / 1.2 + 1));
    final total = tester.getRect(find.textContaining('Total').first);
    expect(total.bottom, lessThanOrEqualTo(rect.bottom));
    expect(tester.takeException(), isNull);

    await teardownCard(tester);
  });

  test('the dipper climbs by doublings from idle to full', () {
    expect(dipperLevel(0), 0);
    expect(dipperLevel(512), 0);
    final kilo = dipperLevel(16 * 1024);
    final mega = dipperLevel(4 * 1024 * 1024);
    expect(kilo, greaterThan(0));
    expect(mega, greaterThan(kilo));
    expect(dipperLevel(64 * 1024 * 1024), 1);
    expect(dipperLevel(1 << 40), 1);
  });

  testWidgets('a desktop card keeps its peak to the window it samples', (
    tester,
  ) async {
    addTraffic(const Traffic(up: 1 << 20));
    for (var i = 0; i < trafficSampleLength; i++) {
      addTraffic(const Traffic(up: 2048));
    }

    await pumpCard(
      tester,
      const SizedBox(
        height: 208,
        child: SpeedCard(direction: TrafficDirection.upload),
      ),
    );

    expect(find.textContaining(_traffic(1 << 20)), findsNothing);
    expect(find.textContaining('${_traffic(2048)}/s'), findsWidgets);

    await teardownCard(tester);
  });
  testWidgets('a desktop card arches its stars between its title and figure', (
    tester,
  ) async {
    addTraffic(const Traffic(down: 1 << 20));

    await pumpCard(
      tester,
      const SizedBox(
        height: 208,
        child: SpeedCard(direction: TrafficDirection.download),
      ),
    );

    final card = tester.getRect(find.byType(SpeedCard));
    final gauge = tester.getRect(find.byType(DipperGauge));
    final title = tester.getRect(find.text('Download'));
    expect(gauge.top, greaterThanOrEqualTo(title.bottom));
    expect(
      gauge.bottom,
      lessThanOrEqualTo(figureIn(tester, find.byType(SpeedCard)).top),
    );
    expect(
      figureIn(tester, find.byType(SpeedCard)).bottom,
      lessThanOrEqualTo(card.bottom),
    );
    expect(find.textContaining('${_traffic(1 << 20)}/s'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await teardownCard(tester);
  });
}

String _traffic(num bytes) {
  final show = bytes.traffic;
  return '${show.value} ${show.unit}';
}
