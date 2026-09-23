import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

TrayState _trayState({
  ConnectionPhase phase = ConnectionPhase.notConnected,
  String? profileName,
  String? nodeName,
  bool isStart = false,
}) => TrayState(
  mode: Mode.rule,
  port: 7890,
  autoLaunch: false,
  systemProxy: true,
  tunEnable: false,
  isStart: isStart,
  locale: null,
  brightness: null,
  groups: const [],
  selectedMap: const {},
  showTrayTitle: false,
  phase: phase,
  profileName: profileName,
  nodeName: nodeName,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('connectionPhaseOf', () {
    ConnectionPhase phase({
      bool isStart = false,
      bool suspend = false,
      bool? requested,
      bool coreDown = false,
    }) => connectionPhaseOf(
      isStart: isStart,
      suspend: suspend,
      requested: requested,
      coreDown: coreDown,
    );

    test('steady states follow the core', () {
      expect(phase(), ConnectionPhase.notConnected);
      expect(phase(isStart: true), ConnectionPhase.connected);
      expect(phase(isStart: true, suspend: true), ConnectionPhase.suspended);
    });

    test('a request the core has not reached yet is pending', () {
      expect(phase(requested: true), ConnectionPhase.connecting);
      expect(
        phase(isStart: true, requested: false),
        ConnectionPhase.disconnecting,
      );
      // Reached: no longer pending.
      expect(phase(isStart: true, requested: true), ConnectionPhase.connected);
    });

    test('a stopped core wins over everything', () {
      expect(
        phase(isStart: true, requested: true, coreDown: true),
        ConnectionPhase.error,
      );
    });
  });

  group('ConnectionRequest', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      globalState.container = container;
    });

    tearDown(() {
      debouncer.cancel(FunctionTag.updateStatus);
      container.dispose();
    });

    test('pending until the core reports the requested state', () {
      container.listen(connectionPhaseProvider, (_, _) {});
      expect(
        container.read(connectionPhaseProvider),
        ConnectionPhase.notConnected,
      );

      container.read(connectionRequestProvider.notifier).request(true);
      debouncer.cancel(FunctionTag.updateStatus);
      expect(
        container.read(connectionPhaseProvider),
        ConnectionPhase.connecting,
      );

      container.read(runTimeProvider.notifier).value = 1;
      expect(container.read(connectionRequestProvider), isNull);
      expect(
        container.read(connectionPhaseProvider),
        ConnectionPhase.connected,
      );
    });

    test('the tray and hotkey toggle go through the same request', () {
      container.read(commonActionProvider.notifier).updateStart();
      debouncer.cancel(FunctionTag.updateStatus);
      expect(container.read(connectionRequestProvider), isTrue);
      expect(
        container.read(connectionPhaseProvider),
        ConnectionPhase.connecting,
      );
    });

    test('after start-up, a disconnected core is an error', () {
      container.read(initProvider.notifier).value = true;
      container.read(coreStatusProvider.notifier).value =
          CoreStatus.disconnected;
      expect(container.read(connectionPhaseProvider), ConnectionPhase.error);

      container.read(coreStatusProvider.notifier).value = CoreStatus.connected;
      expect(
        container.read(connectionPhaseProvider),
        ConnectionPhase.notConnected,
      );
    });
  });

  group('tray (§84-85)', () {
    late ProviderContainer container;

    setUpAll(() async {
      await AppLocalizations.load(const Locale('en'));
    });

    late List<Map<Object?, Object?>> menus;

    setUp(() {
      container = ProviderContainer();
      globalState.container = container;
      menus = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('tray_manager'), (
            call,
          ) async {
            if (call.method == 'setContextMenu') {
              final args = call.arguments as Map<Object?, Object?>;
              menus.add(args['menu'] as Map<Object?, Object?>);
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('tray_manager'), null);
      container.dispose();
    });

    List<(String, bool)> items(Map<Object?, Object?> menu) => [
      for (final item in (menu['items'] as List).cast<Map<Object?, Object?>>())
        if (item['type'] != 'separator')
          (item['label'] as String, item['disabled'] == true),
    ];

    test('connected: state, profile, node, then Disconnect', () async {
      await Tray().update(
        trayState: _trayState(
          phase: ConnectionPhase.connected,
          profileName: 'Work',
          nodeName: 'JP-01',
          isStart: true,
        ),
        traffic: const Traffic(),
      );
      final labels = items(menus.last);
      expect(labels.take(4).toList(), [
        ('Connected', true),
        ('Profile: Work', true),
        ('Node: JP-01', true),
        ('Disconnect', false),
      ]);
      final all = labels.map((e) => e.$1).toList();
      expect(all, containsAll(['Show', 'TUN', 'System proxy', 'Exit']));
    });

    test('connecting: the action waits, like Home', () async {
      await Tray().update(
        trayState: _trayState(phase: ConnectionPhase.connecting),
        traffic: const Traffic(),
      );
      final labels = items(menus.last);
      expect(labels[0], ('Connecting…', true));
      expect(labels[1], ('Connecting…', true));
      expect(labels.map((e) => e.$1), isNot(contains('Connect')));
    });

    test('core stopped: offers Restart', () async {
      await Tray().update(
        trayState: _trayState(phase: ConnectionPhase.error),
        traffic: const Traffic(),
      );
      final labels = items(menus.last);
      expect(labels[0], ('Core stopped', true));
      expect(labels[1], ('Restart', false));
    });

    test('tooltip names the state, and the node once connected', () {
      expect(
        Tray.tooltipOf(
          _trayState(phase: ConnectionPhase.connected, nodeName: 'JP-01'),
        ),
        '$appName · Connected · JP-01',
      );
      expect(
        Tray.tooltipOf(
          _trayState(phase: ConnectionPhase.connecting, nodeName: 'JP-01'),
        ),
        '$appName · Connecting…',
      );
    });
  });
}
