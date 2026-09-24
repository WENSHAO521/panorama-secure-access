import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/widgets/dialog.dart';
import 'package:fl_clash/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Desktop dialog width regression coverage (post AlertDialog -> Dialog +
// GlassSurface migration): a wide GlassSurface with narrow, left-aligned,
// non-stretching content inside it. See lib/widgets/dialog.dart.

void main() {
  Future<double> pumpAndGetDialogWidth(
    WidgetTester tester, {
    required Size viewSize,
    bool isLarge = false,
    Widget? child,
    List<Widget>? actions,
    String title = 'Title',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [viewSizeProvider.overrideWithBuild((_, _) => viewSize)],
        child: MaterialApp(
          home: CommonDialog(
            title: title,
            isLarge: isLarge,
            actions: actions,
            child:
                child ??
                const TextField(decoration: InputDecoration(labelText: 'x')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return tester.getSize(find.byType(GlassSurface)).width;
  }

  group('CommonDialog responsive width', () {
    testWidgets('caps at ~560 on a normal desktop window', (tester) async {
      final width = await pumpAndGetDialogWidth(
        tester,
        viewSize: const Size(1280, 800),
      );
      expect(width, 560);
    });

    testWidgets('caps at ~640 for isLarge dialogs', (tester) async {
      final width = await pumpAndGetDialogWidth(
        tester,
        viewSize: const Size(1280, 800),
        isLarge: true,
      );
      expect(width, 640);
    });

    testWidgets('shrinks below the cap on a small desktop window', (
      tester,
    ) async {
      // The compact breakpoint (600) plus the 40px margin already lands exactly on
      // the 560 default cap, so a window has to opt into the wider isLarge
      // (640) cap to actually observe the margin winning over the cap
      // while still staying in desktop (> 600px) mode: 650 - 40 = 610,
      // under 640.
      final width = await pumpAndGetDialogWidth(
        tester,
        viewSize: const Size(650, 500),
        isLarge: true,
      );
      expect(width, 610);
    });

    testWidgets('is screen width minus safe inset on mobile', (tester) async {
      // Below the compact breakpoint (600) isMobileViewProvider is mobile.
      final width = await pumpAndGetDialogWidth(
        tester,
        viewSize: const Size(400, 800),
      );
      expect(width, 360);
    });

    testWidgets(
      'title, content, and actions all share the dialog width (stretch)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              viewSizeProvider.overrideWithBuild(
                (_, _) => const Size(1280, 800),
              ),
            ],
            child: const MaterialApp(
              home: CommonDialog(
                title: 'Title',
                actions: [TextButton(onPressed: null, child: Text('OK'))],
                child: TextField(decoration: InputDecoration(labelText: 'URL')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final dialogWidth = tester.getSize(find.byType(GlassSurface)).width;
        final titleWidth = tester.getSize(find.text('Title')).width;
        final fieldWidth = tester.getSize(find.byType(TextField)).width;
        final actionsRowWidth = tester.getSize(find.byType(Row)).width;

        // The title/field/actions row don't need to equal the glass
        // surface's width themselves (they sit inside padding), but they
        // must all be driven by the same stretched cross axis rather than
        // each shrink-wrapping independently — regressing to the old bug
        // would leave the field pinned near a ~300px intrinsic width
        // while the surface (pushed wide by, e.g., a long title) grew
        // past it.
        expect(fieldWidth, greaterThan(500));
        expect(fieldWidth, dialogWidth - 48);
        expect(titleWidth, lessThanOrEqualTo(dialogWidth - 48));
        expect(actionsRowWidth, dialogWidth - 48);
      },
    );

    testWidgets('a long title does not widen the surface past the cap', (
      tester,
    ) async {
      final width = await pumpAndGetDialogWidth(
        tester,
        viewSize: const Size(1280, 800),
        title:
            'A very long dialog title that would previously have '
            'stretched the glass surface wider than the capped content '
            'area, leaving it narrow and left-aligned inside the extra '
            'space',
      );
      expect(width, 560);
    });

    testWidgets('long agreement text scrolls within a capped height', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewSizeProvider.overrideWithBuild(
              (_, _) => const Size(1280, 2000),
            ),
          ],
          child: MaterialApp(
            home: CommonDialog(
              title: 'Disclaimer',
              child: Text('legal text\n' * 200),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final dialogHeight = tester.getSize(find.byType(GlassSurface)).height;
      // maxHeight: min(size.height - 40, 500) -> capped at 500 for the
      // content area even on a very tall window; the dialog as a whole
      // stays well under the simulated 2000px window height.
      expect(dialogHeight, lessThan(700));
    });

    for (final dpr in [1.0, 1.5, 2.0, 2.5, 3.0]) {
      testWidgets('renders without overflow at devicePixelRatio $dpr', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1280, 800) * dpr;
        tester.view.devicePixelRatio = dpr;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final width = await pumpAndGetDialogWidth(
          tester,
          viewSize: const Size(1280, 800),
          child: Column(
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  decoration: InputDecoration(labelText: 'Field $i'),
                ),
              ),
            ),
          ),
        );
        expect(width, 560);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
