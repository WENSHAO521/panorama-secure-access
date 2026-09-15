import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/widgets/glass.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// GlassScrollPerformance regression coverage (see widgets/glass.dart /
// widgets/scaffold.dart): a panel-tier GlassSurface inside a
// CommonScaffold's body must drop its BackdropFilter blur while a scroll
// gesture is actively in flight, then restore it once the gesture settles
// past the debounce window — not immediately on lift-off, and not ever for
// chrome (the AppBar), which stays blurred throughout.

void main() {
  Finder panelBlurFinder() => find.descendant(
    of: find.byType(GlassSurface),
    matching: find.byType(BackdropFilter),
  );

  Finder chromeBlurFinder() => find.descendant(
    of: find.byType(LiquidGlassChrome),
    matching: find.byType(BackdropFilter),
  );

  Future<void> pumpScrollableScaffold(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          home: const CommonScaffold(
            title: 'Scroll test',
            body: SingleChildScrollView(
              child: Column(
                children: [
                  GlassSurface.panel(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: SizedBox(
                      height: 2000,
                      child: Text('panel content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('panel blur is present at rest', (tester) async {
    await pumpScrollableScaffold(tester);
    expect(tester.takeException(), isNull);
    expect(panelBlurFinder(), findsOneWidget);
    expect(chromeBlurFinder(), findsOneWidget);
  });

  testWidgets(
    'panel blur is suppressed by a scroll gesture and restored after the debounce window, '
    'while chrome stays blurred throughout',
    (tester) async {
      await pumpScrollableScaffold(tester);

      // tester.drag runs an atomic down+move+up gesture, so by the time it
      // returns the scroll has already ended — this exercises "still
      // suppressed immediately after lift-off, inside the debounce window",
      // not "mid-drag" (Scrollable's own ScrollUpdateNotification firing
      // during the move covers the mid-drag case identically, since the
      // suppression flag goes up on the very first update).
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, 200.0);
      await tester.pump();

      expect(panelBlurFinder(), findsNothing);
      // Chrome (the AppBar) is unaffected — it's pinned, not part of the
      // scrolling body, and GlassScrollPerformance only gates panel/floating.
      expect(chromeBlurFinder(), findsOneWidget);

      // Still within the 150ms debounce window: stays suppressed.
      await tester.pump(const Duration(milliseconds: 50));
      expect(panelBlurFinder(), findsNothing);

      // Past the debounce window: scroll has settled, blur is back.
      await tester.pump(const Duration(milliseconds: 150));
      expect(panelBlurFinder(), findsOneWidget);
    },
  );
}
