import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/pages/home.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('only the current navigation page is active', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final seen = <PageLabel, bool>{};

    Widget page(PageLabel label) => HomePageActivity(
      label: label,
      child: Builder(
        builder: (context) {
          seen[label] = PageActivityScope.isActiveOf(context);
          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Column(
          children: [page(PageLabel.home), page(PageLabel.activity)],
        ),
      ),
    );
    expect(seen, {PageLabel.home: true, PageLabel.activity: false});

    container
        .read(currentPageLabelProvider.notifier)
        .toPage(PageLabel.activity);
    await tester.pump();
    expect(seen, {PageLabel.home: false, PageLabel.activity: true});
  });
}
