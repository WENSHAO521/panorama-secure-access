import 'package:fl_clash/common/update.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';

const _asset = UpdateAsset(
  name: 'PanoramaSecureAccess-3.4.1-windows-amd64-setup.exe',
  url: 'https://example.test/setup.exe',
  size: 64 * 1024 * 1024,
);

UpdateState _state(
  UpdateStage stage, {
  int received = 0,
  bool cardVisible = true,
}) {
  return UpdateState(
    tag: 'v3.4.1',
    asset: _asset,
    stage: stage,
    received: received,
    cardVisible: cardVisible,
  );
}

Future<void> _pump(WidgetTester tester, UpdateState? state) async {
  await tester.pumpWidget(
    TestApp(
      wrapInProviderScope: true,
      overrides: [
        updateControllerProvider.overrideWithBuild((ref, _) => state),
      ],
      homeBuilder: (child) => Scaffold(body: Center(child: child)),
      child: const SizedBox(width: 380, child: UpdateCardHost()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('shows nothing without an update', (tester) async {
    await _pump(tester, null);
    expect(find.byType(UpdateCard), findsNothing);
  });

  testWidgets('hides the card but keeps the update when dismissed', (
    tester,
  ) async {
    await _pump(tester, _state(UpdateStage.downloading, cardVisible: false));
    expect(find.byType(UpdateCard), findsNothing);
  });

  testWidgets('reports download progress with a cancel action', (tester) async {
    await _pump(
      tester,
      _state(UpdateStage.downloading, received: 32 * 1024 * 1024),
    );
    expect(find.text('Downloading update'), findsOneWidget);
    expect(find.text('3.4.1 · 50%'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('offers install once the download is ready', (tester) async {
    await _pump(tester, _state(UpdateStage.ready));
    expect(find.text('Ready to install'), findsOneWidget);
    expect(find.text('Install now'), findsOneWidget);
    expect(find.byGlyph(AppGlyphs.check), findsWidgets);
  });

  testWidgets('offers a retry after a failure', (tester) async {
    await _pump(tester, _state(UpdateStage.failed));
    expect(find.text('Download failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('waits for a tap before downloading when only available', (
    tester,
  ) async {
    await _pump(tester, _state(UpdateStage.available));
    expect(find.text('Update now'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
