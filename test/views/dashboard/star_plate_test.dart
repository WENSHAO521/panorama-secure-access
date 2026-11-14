import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/ip_quality.dart';
import 'package:fl_clash/providers/outbound_ip.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/providers/routed_probe.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/views/dashboard/widgets/current_outbound.dart';
import 'package:fl_clash/views/dashboard/widgets/star_plate.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/host_scaffold.dart';
import '../../helpers/test_app.dart';

const _profile = Profile(id: 1, autoUpdateDuration: Duration.zero);

/// Holds each request until the test answers it, and starts the core only
/// when told the start went through.
class _HeldSetupAction extends SetupAction {
  final requests = <bool>[];
  final pending = <Completer<bool>>[];

  @override
  Future<bool> setRunning(bool running, {bool initialize = false}) async {
    requests.add(running);
    final answer = Completer<bool>();
    pending.add(answer);
    final applied = await answer.future;
    if (applied) {
      ref.read(runTimeProvider.notifier).value = running ? 1 : null;
    }
    return applied;
  }
}

class _Ips extends OutboundIpProbe {
  @override
  RoutedProbeState<String, IpInfo> build() => const RoutedProbeState({});

  @override
  void watch(String target) {}

  @override
  void unwatch(String target) {}
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        profilesProvider.overrideWithValue(const [_profile]),
        outboundIpProbeProvider.overrideWith(_Ips.new),
        ipQualityProvider.overrideWith((_, _) => Completer<IpQuality>().future),
        setupActionProvider.overrideWith(_HeldSetupAction.new),
        suspendProvider.overrideWithValue(false),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpCard(WidgetTester tester) async {
    globalState.container = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(
          child: StarChartScope(
            enabled: true,
            child: HostScaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 600,
                  height: 220,
                  child: DashboardDensityScope(
                    density: DashboardDensity.standard,
                    scale: 1,
                    child: CurrentOutboundCard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  _HeldSetupAction action() =>
      container.read(setupActionProvider.notifier) as _HeldSetupAction;

  Finder plate() => find.byType(StarPlateToggle);

  // The exit row keeps a spinner going with no address, so nothing settles.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('holds starting until the core answers, ignoring taps', (
    tester,
  ) async {
    await pumpCard(tester);
    final context = tester.element(plate());
    expect(find.byTooltip(context.appLocalizations.start), findsOneWidget);

    await tester.tap(plate());
    await tester.pump();
    expect(
      find.byTooltip(context.appLocalizations.coreStarting),
      findsOneWidget,
    );

    await tester.tap(plate());
    await tester.pump();
    expect(action().requests, [true]);

    action().pending.single.complete(true);
    await settle(tester);
    expect(find.byTooltip(context.appLocalizations.stop), findsOneWidget);
  });

  testWidgets('a start that leaves the core down shows a retry', (
    tester,
  ) async {
    await pumpCard(tester);
    final context = tester.element(plate());

    await tester.tap(plate());
    await tester.pump();
    action().pending.single.complete(false);
    await settle(tester);
    expect(
      find.byTooltip(context.appLocalizations.startFailedRetry),
      findsOneWidget,
    );

    await tester.tap(plate());
    await tester.pump();
    expect(action().requests, [true, true]);
    action().pending.last.complete(true);
    await settle(tester);
    expect(find.byTooltip(context.appLocalizations.stop), findsOneWidget);
  });

  testWidgets('stopping holds until the core has stopped', (tester) async {
    container.read(runTimeProvider.notifier).value = 1;
    await pumpCard(tester);
    final context = tester.element(plate());

    await tester.tap(plate());
    await tester.pump();
    expect(
      find.byTooltip(context.appLocalizations.coreStopping),
      findsOneWidget,
    );
    action().pending.single.complete(true);
    await settle(tester);
    expect(find.byTooltip(context.appLocalizations.start), findsOneWidget);
  });
}
