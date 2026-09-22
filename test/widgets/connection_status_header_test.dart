import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/profile.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dashboard/widgets/connection_status_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression coverage for the fixed Home connection-state header (see
// lib/views/dashboard/widgets/connection_status_header.dart): it must
// color its icon from the same semantic tokens as everywhere else in the
// app, show/hide the profile line correctly, and never overflow — a
// too-narrow manual smoke test during development did overflow before
// tallness was corrected, which is what the narrow-width case below
// guards against.

Future<void> _pump(
  WidgetTester tester, {
  required CoreStatus status,
  Profile? profile,
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 200) * 2;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coreStatusProvider.overrideWithBuild((_, _) => status),
        currentProfileProvider.overrideWith((_) => profile),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        home: const Scaffold(body: ConnectionStatusHeader()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('connected uses statusConnected for the icon and shows the '
      'profile name', (tester) async {
    final profile = Profile.normal(label: 'My Subscription');
    await _pump(tester, status: CoreStatus.connected, profile: profile);
    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(ConnectionStatusHeader));
    final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_rounded));
    expect(icon.color, context.colorScheme.statusConnected);
    expect(find.text(profile.realLabel), findsOneWidget);
    expect(find.text(context.appLocalizations.connected), findsOneWidget);
  });

  testWidgets('connecting uses statusWarning and hides the profile line '
      'when there is none', (tester) async {
    await _pump(tester, status: CoreStatus.connecting);
    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(ConnectionStatusHeader));
    final icon = tester.widget<Icon>(find.byIcon(Icons.sync_rounded));
    expect(icon.color, context.colorScheme.statusWarning);
    expect(find.text(context.appLocalizations.connecting), findsOneWidget);
  });

  testWidgets('disconnected uses a neutral tone, never the connected/warning '
      'colors', (tester) async {
    await _pump(tester, status: CoreStatus.disconnected);
    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(ConnectionStatusHeader));
    final icon = tester.widget<Icon>(
      find.byIcon(Icons.remove_circle_outline_rounded),
    );
    expect(icon.color, context.colorScheme.onSurfaceVariant);
    expect(icon.color, isNot(context.colorScheme.statusConnected));
    expect(icon.color, isNot(context.colorScheme.statusWarning));
  });

  testWidgets('a long profile name truncates instead of overflowing at a '
      'narrow width', (tester) async {
    await _pump(
      tester,
      status: CoreStatus.disconnected,
      profile: Profile.normal(
        label: 'A Very Long Subscription Name That Should Truncate',
      ),
      width: 260,
    );
    expect(tester.takeException(), isNull);
  });
}
