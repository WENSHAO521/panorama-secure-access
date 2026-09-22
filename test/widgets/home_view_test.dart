import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = Profile(
  id: 1,
  label: 'Work',
  autoUpdateDuration: Duration(hours: 12),
);

final _groups = [
  const Group(
    type: GroupType.Selector,
    name: 'Proxy',
    hidden: false,
    all: [
      Proxy(name: 'Auto', type: 'URLTest'),
      Proxy(name: 'JP-01', type: 'Hysteria2'),
    ],
  ),
  const Group(
    type: GroupType.URLTest,
    name: 'Auto',
    hidden: false,
    now: 'JP-01',
    all: [Proxy(name: 'JP-01', type: 'Hysteria2')],
  ),
];

void main() {
  late ProviderContainer container;

  ProviderContainer build({
    bool isStart = false,
    List<Profile> profiles = const [_profile],
  }) {
    return ProviderContainer(
      overrides: [
        profilesProvider.overrideWithBuild((_, _) => profiles),
        currentProfileProvider.overrideWithValue(
          profiles.isEmpty ? null : profiles.first,
        ),
        groupsProvider.overrideWithBuild((_, _) => _groups),
        selectedMapProvider.overrideWithValue(const {'Proxy': 'Auto'}),
        serviceRouteKeyProvider.overrideWithValue('1|rule|Proxy=Auto'),
        isStartProvider.overrideWith((ref) => isStart),
        suspendProvider.overrideWith((ref) => false),
      ],
    );
  }

  tearDown(() {
    debouncer.cancel(FunctionTag.updateStatus);
    container.dispose();
  });

  Future<void> pumpHome(WidgetTester tester, ProviderContainer c) async {
    container = c;
    globalState.container = c;
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
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
          home: const HomeView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('without a profile it points to adding one', (tester) async {
    await pumpHome(tester, build(profiles: const []));

    expect(find.text('No profile, Please add a profile'), findsOneWidget);
    expect(find.text('Add Profile'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);
  });

  testWidgets('disconnected: status, one Connect control, route', (
    tester,
  ) async {
    await pumpHome(tester, build());

    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    // The Proxy group selects Auto, a url-test group currently on JP-01.
    expect(find.text('JP-01  ·  Proxy', findRichText: true), findsOneWidget);
    expect(find.text('Not checked'), findsOneWidget);
  });

  testWidgets('tapping Connect shows a pending state until the core answers', (
    tester,
  ) async {
    await pumpHome(tester, build());

    await tester.tap(find.text('Connect'));
    await tester.pump();

    expect(find.text('Connecting…'), findsNWidgets(2));
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(button.onPressed, isNull);
    // Don't let the debounced status change reach the (absent) core.
    debouncer.cancel(FunctionTag.updateStatus);
  });

  testWidgets('connected: stable state with Disconnect', (tester) async {
    await pumpHome(tester, build(isStart: true));

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
    expect(find.textContaining('Connected for'), findsOneWidget);
    // Nothing keeps animating once connected (brief §25).
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
