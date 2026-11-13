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

  Finder figuresOf(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_SpeedFigures',
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

    final upload = figuresOf('Upload');
    final download = figuresOf('Download');
    Finder inTile(Finder tile, String text) =>
        find.descendant(of: tile, matching: find.textContaining(text));
    expect(inTile(upload, '${_traffic(1024)}/s'), findsOneWidget);
    expect(inTile(upload, 'Total ${_traffic(5120)}'), findsOneWidget);
    expect(inTile(download, '${_traffic(3072)}/s'), findsOneWidget);
    expect(inTile(download, 'Total ${_traffic(6144)}'), findsOneWidget);
    expect(find.textContaining(_traffic(4096)), findsNothing);

    await teardownCard(tester);
  });

  testWidgets('one dipper spans the phone card, the upload over its handle '
      'and the download under its bowl', (tester) async {
    addTraffic(const Traffic(up: 1 << 16, down: 1 << 22));
    await pumpCard(tester, const NetworkSpeedCard());

    final card = tester.getRect(find.byType(NetworkSpeedCard));
    final gauge = tester.getRect(find.byType(DipperGauge));
    final upload = tester.getRect(figuresOf('Upload'));
    final download = tester.getRect(figuresOf('Download'));
    final title = tester.getRect(find.text('Network speed'));

    expect(find.byType(DipperGauge), findsOneWidget);
    expect(gauge.top, greaterThanOrEqualTo(title.bottom));
    expect(gauge.width, greaterThan(card.width * 0.7));
    expect(upload.left, closeTo(gauge.left, 0.5));
    expect(upload.top, lessThan(gauge.top + gauge.height / 2));
    expect(download.right, closeTo(gauge.right, 0.5));
    expect(download.top, greaterThanOrEqualTo(upload.bottom));
    expect(download.bottom, lessThanOrEqualTo(card.bottom));
    expect(tester.takeException(), isNull);

    await teardownCard(tester);
  });

  testWidgets('the phone card grows rather than clip scaled up text', (
    tester,
  ) async {
    await pumpCard(tester, const NetworkSpeedCard());
    final before = tester.getRect(find.byType(NetworkSpeedCard)).height;
    await teardownCard(tester);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpCard(tester, const NetworkSpeedCard());

    final card = tester.getRect(find.byType(NetworkSpeedCard));
    expect(card.height, greaterThan(before + 1));
    final upload = tester.getRect(figuresOf('Upload'));
    final download = tester.getRect(figuresOf('Download'));
    expect(download.top, greaterThanOrEqualTo(upload.bottom));
    expect(download.bottom, lessThanOrEqualTo(card.bottom));
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

  testWidgets('a desktop card fills its height and narrows the dipper to '
      'fit', (tester) async {
    addTraffic(const Traffic(down: 1 << 20));

    await pumpCard(
      tester,
      const SizedBox(height: 208, child: NetworkSpeedCard(fill: true)),
    );

    final card = tester.getRect(find.byType(NetworkSpeedCard));
    final gauge = tester.getRect(find.byType(DipperGauge));
    final title = tester.getRect(find.text('Network speed'));
    final download = tester.getRect(figuresOf('Download'));
    expect(card.height, 208);
    expect(gauge.top, greaterThanOrEqualTo(title.bottom));
    expect(download.bottom, lessThanOrEqualTo(card.bottom));
    expect(find.textContaining('${_traffic(1 << 20)}/s'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await teardownCard(tester);
  });
}

String _traffic(num bytes) {
  final show = bytes.traffic;
  return '${show.value} ${show.unit}';
}
