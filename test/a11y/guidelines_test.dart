// Accessibility regression checks for the screens this modernization
// rebuilt (brief §99): each at phone width, in light theme at 100 % text and
// in dark theme at 200 % text (which also fails on any layout overflow).
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/backup_and_restore.dart';
import 'package:fl_clash/views/connection/table.dart';
import 'package:fl_clash/views/home.dart';
import 'package:fl_clash/views/logs.dart';
import 'package:fl_clash/views/profiles/profiles.dart';
import 'package:fl_clash/views/proxies/card.dart';
import 'package:fl_clash/views/proxies/common.dart';
import 'package:fl_clash/views/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _profile = Profile(
  id: 1,
  label: 'Work',
  autoUpdateDuration: Duration(hours: 12),
  url: 'https://sub.example.com/x',
);
final _groups = [
  const Group(
    type: GroupType.Selector,
    name: 'Proxy',
    hidden: false,
    all: [Proxy(name: 'JP-01', type: 'Hysteria2')],
  ),
];

/// Pumps [child] and checks Flutter's accessibility guidelines: 48 px tap
/// targets, a label on every tap target, and text contrast.
Future<void> audit(
  WidgetTester tester,
  String name,
  Widget child, {
  List<Override> overrides = const [],
  Brightness b = Brightness.light,
  double width = 390,
  double scale = 1,
}) async {
  final c = ProviderContainer(
    overrides: [
      profilesProvider.overrideWithBuild((_, _) => const [_profile]),
      currentProfileProvider.overrideWithValue(_profile),
      groupsProvider.overrideWithBuild((_, _) => _groups),
      selectedMapProvider.overrideWithValue(const {'Proxy': 'JP-01'}),
      serviceRouteKeyProvider.overrideWithValue('1|rule|Proxy=JP-01'),
      moreToolsSelectorStateProvider.overrideWithValue(
        const MoreToolsSelectorState(navigationItems: []),
      ),
      ...overrides,
    ],
  );
  globalState.container = c;
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: globalState.navigatorKey,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(defaultPrimaryColor),
            brightness: b,
            dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          ),
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        builder: (context, child) {
          globalState.measure = Measure.of(context, scale);
          globalState.theme = CommonTheme.of(context, scale);
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
        },
        // Padded like the app's lists: the tap-target check skips targets that
        // touch the screen edge, which would hide a too-small button.
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
  debouncer.cancel(FunctionTag.updateStatus);
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  final now = DateTime.now();
  final conns = [
    TrackerInfo(
      id: '1',
      start: now,
      metadata: const Metadata(
        network: 'tcp',
        process: 'Safari',
        host: 'a.example',
        destinationPort: '443',
        sourceIP: '192.168.1.2',
        sourcePort: '5000',
      ),
      chains: const ['JP-01', 'Proxy'],
      rule: 'Match',
      rulePayload: '',
    ),
  ];
  for (final b in Brightness.values) {
    // Dark runs at 200 % text: dynamic type must not overflow.
    final scale = b == Brightness.dark ? 2.0 : 1.0;
    testWidgets(
      'home $b',
      (t) => audit(
        t,
        'home',
        const HomeView(),
        b: b,
        scale: scale,
        overrides: [
          isStartProvider.overrideWith((ref) => false),
          suspendProvider.overrideWith((ref) => false),
        ],
      ),
    );
    testWidgets(
      'settings $b',
      (t) => audit(t, 'settings', const SettingsView(), b: b, scale: scale),
    );
    testWidgets(
      'profile $b',
      (t) => audit(
        t,
        'profile',
        ProfileItem(profile: _profile, groupValue: 1, onChanged: (_) {}),
        b: b,
        scale: scale,
      ),
    );
    testWidgets(
      'row $b',
      (t) => audit(
        t,
        'proxyrow',
        Builder(
          builder: (_) => SizedBox(
            height: getItemHeight(ProxyCardType.row),
            child: const ProxyCard(
              groupName: 'Proxy',
              testUrl: null,
              proxy: Proxy(name: 'JP-01', type: 'Hysteria2'),
              groupType: GroupType.Selector,
              type: ProxyCardType.row,
            ),
          ),
        ),
        b: b,
        scale: scale,
      ),
    );
    testWidgets(
      'table $b',
      (t) => audit(
        t,
        'conntable',
        ConnectionsTable(
          connections: conns,
          onOpen: (_) {},
          onClose: (_) {},
          onFilter: (_) {},
        ),
        b: b,
        scale: scale,
        width: 1100,
      ),
    );
    testWidgets('logs $b', (t) async {
      await audit(
        t,
        'logs',
        const LogsView(),
        b: b,
        scale: scale,
        overrides: [
          logsProvider.overrideWithBuild(
            (_, _) => FixedList(
              10,
              list: [
                const Log(
                  payload: '[TCP] a.example:443',
                  dateTime: '2026-09-23 10:00:00',
                ),
                const Log(
                  payload: 'warn',
                  logLevel: LogLevel.warning,
                  dateTime: '2026-09-23 10:00:01',
                ),
                const Log(
                  payload: 'err',
                  logLevel: LogLevel.error,
                  dateTime: '2026-09-23 10:00:02',
                ),
              ],
            ),
          ),
        ],
      );
    });
    testWidgets(
      'backup $b',
      (t) => audit(t, 'backup', const BackupAndRestore(), b: b, scale: scale),
    );
  }
}
