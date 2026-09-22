import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/views/connection/item.dart';
import 'package:fl_clash/views/connection/table.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 22, 12);

TrackerInfo _conn(
  String id, {
  String process = '',
  String host = '',
  String ip = '',
  String port = '443',
  int up = 0,
  int down = 0,
  Duration age = Duration.zero,
  List<String> chains = const ['JP-01', 'Auto', 'Proxy'],
  String rule = 'Match',
  String payload = '',
}) {
  return TrackerInfo(
    id: id,
    upload: up,
    download: down,
    start: _now.subtract(age),
    metadata: Metadata(
      network: 'tcp',
      process: process,
      sourceIP: '192.168.1.20',
      sourcePort: '51000',
      host: host,
      destinationIP: ip,
      destinationPort: port,
    ),
    chains: chains,
    rule: rule,
    rulePayload: payload,
  );
}

void main() {
  group('formatElapsed', () {
    test('seconds, minutes, hours, days', () {
      expect(formatElapsed(const Duration(seconds: 45)), '45s');
      expect(formatElapsed(const Duration(minutes: 3, seconds: 7)), '3m 07s');
      expect(formatElapsed(const Duration(hours: 2, minutes: 5)), '2h 05m');
      expect(formatElapsed(const Duration(days: 3, hours: 4)), '3d 4h');
    });

    test('a start slightly in the future reads 0s', () {
      expect(formatElapsed(const Duration(seconds: -2)), '0s');
    });
  });

  group('cell text', () {
    test('destination prefers the host, brackets IPv6', () {
      expect(
        _conn('1', host: 'a.com', ip: '1.2.3.4').destinationText,
        'a.com:443',
      );
      expect(_conn('2', ip: '1.2.3.4').destinationText, '1.2.3.4:443');
      expect(
        _conn('3', ip: '2606:4700::1').destinationText,
        '[2606:4700::1]:443',
      );
    });

    test('proxy is the node; the chain reads group to node', () {
      final c = _conn('1');
      expect(c.proxyText, 'JP-01');
      expect(c.chainText, 'Proxy → Auto → JP-01');
    });

    test('rule shows its payload', () {
      expect(
        _conn('1', rule: 'DomainSuffix', payload: 'google.com').ruleText,
        'DomainSuffix(google.com)',
      );
    });
  });

  group('sorting', () {
    test('header clicks cycle: natural order, reversed, core order', () {
      var sort = ConnectionSort.next(null, ConnectionColumn.process);
      expect(
        sort,
        const ConnectionSort(ConnectionColumn.process, ascending: true),
      );
      sort = ConnectionSort.next(sort, ConnectionColumn.process);
      expect(
        sort,
        const ConnectionSort(ConnectionColumn.process, ascending: false),
      );
      expect(ConnectionSort.next(sort, ConnectionColumn.process), isNull);

      // Traffic and duration start largest-first.
      sort = ConnectionSort.next(sort, ConnectionColumn.download);
      expect(
        sort,
        const ConnectionSort(ConnectionColumn.download, ascending: false),
      );
    });

    test('by download, largest first; ties keep the core order', () {
      final list = [
        _conn('a', down: 10),
        _conn('b', down: 30),
        _conn('c', down: 10),
      ];
      final sorted = sortConnections(
        list,
        const ConnectionSort(ConnectionColumn.download, ascending: false),
      );
      expect(sorted.map((c) => c.id), ['b', 'a', 'c']);
    });

    test('by duration, longest open first', () {
      final list = [
        _conn('new', age: const Duration(seconds: 5)),
        _conn('old', age: const Duration(hours: 1)),
      ];
      final sorted = sortConnections(
        list,
        const ConnectionSort(ConnectionColumn.duration, ascending: false),
      );
      expect(sorted.map((c) => c.id), ['old', 'new']);
    });

    test('no sort returns the core order untouched', () {
      final list = [_conn('x'), _conn('y')];
      expect(identical(sortConnections(list, null), list), isTrue);
    });
  });

  group('ConnectionsTable', () {
    Future<void> pumpTable(
      WidgetTester tester,
      List<TrackerInfo> connections, {
      void Function(TrackerInfo)? onOpen,
      void Function(TrackerInfo)? onClose,
      void Function(String)? onFilter,
    }) async {
      tester.view.physicalSize = const Size(1280, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _App(
          child: Scaffold(
            body: ConnectionsTable(
              connections: connections,
              now: () => _now,
              onOpen: onOpen ?? (_) {},
              onClose: onClose ?? (_) {},
              onFilter: onFilter ?? (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the eight §77 columns', (tester) async {
      await pumpTable(tester, [
        _conn(
          '1',
          process: 'Safari',
          host: 'claude.ai',
          up: 2048,
          down: 3 << 20,
          age: const Duration(minutes: 3, seconds: 7),
          rule: 'DomainSuffix',
          payload: 'claude.ai',
        ),
      ]);

      for (final header in [
        'Process',
        'Source',
        'Destination',
        'Rule',
        'Proxy',
        'Upload',
        'Download',
        'Duration',
      ]) {
        expect(find.text(header), findsOneWidget, reason: header);
      }
      expect(find.text('Safari'), findsOneWidget);
      expect(find.text('192.168.1.20:51000'), findsOneWidget);
      expect(find.text('claude.ai:443'), findsOneWidget);
      expect(find.text('DomainSuffix(claude.ai)'), findsOneWidget);
      expect(find.text('JP-01'), findsOneWidget);
      expect(find.text('2KB'), findsOneWidget);
      expect(find.text('3MB'), findsOneWidget);
      expect(find.text('3m 07s'), findsOneWidget);
    });

    testWidgets('clicking a header sorts', (tester) async {
      await pumpTable(tester, [
        _conn('1', host: 'small.example', down: 1),
        _conn('2', host: 'big.example', down: 100),
      ]);
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('small.example:443'), lessThan(y('big.example:443')));

      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(y('big.example:443'), lessThan(y('small.example:443')));
    });

    testWidgets('row click opens details; close button closes', (tester) async {
      TrackerInfo? opened;
      TrackerInfo? closed;
      await pumpTable(
        tester,
        [_conn('1', host: 'a.example')],
        onOpen: (c) => opened = c,
        onClose: (c) => closed = c,
      );

      await tester.tap(find.text('a.example:443'));
      expect(opened?.id, '1');

      await tester.tap(find.byTooltip('Close connection'));
      expect(closed?.id, '1');
    });

    testWidgets('right click offers filters by process and node', (
      tester,
    ) async {
      String? filtered;
      await pumpTable(tester, [
        _conn('1', process: 'Safari', host: 'a.example'),
      ], onFilter: (k) => filtered = k);

      await tester.tap(find.text('a.example:443'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      expect(find.text('Show only “Safari”'), findsOneWidget);
      expect(find.text('Show only “JP-01”'), findsOneWidget);
      expect(find.text('Copy destination'), findsOneWidget);

      await tester.tap(find.text('Show only “JP-01”'));
      await tester.pumpAndSettle();
      expect(filtered, 'JP-01');
    });
  });

  group('ConnectionsView layout', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      globalState.container = container;
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> pumpView(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _App(
            child: PageActivityScope(
              isActive: true,
              child: ConnectionsView(
                connectionsReader: () async => [_conn('1', host: 'a.example')],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('wide: table', (tester) async {
      await pumpView(tester, 1280);
      expect(find.byType(ConnectionsTable), findsOneWidget);
      expect(find.byType(TrackerInfoItem), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('narrow: rows, never a squeezed table (§78)', (tester) async {
      await pumpView(tester, 600);
      expect(find.byType(ConnectionsTable), findsNothing);
      expect(find.byType(TrackerInfoItem), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

class _App extends StatelessWidget {
  final Widget child;

  const _App({required this.child});

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
      home: child,
    );
  }
}
