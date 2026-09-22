import 'package:fl_clash/common/navigation.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

List<PageLabel> _labelsFor(NavigationItemMode mode, {bool hasProxies = true}) {
  return navigation
      .getItems(hasProxies: hasProxies)
      .where((item) => item.modes.contains(mode))
      .map((item) => item.label)
      .toList();
}

void main() {
  group('Navigation', () {
    test(
      'mobile bottom bar is Home, Proxies, Profiles, Activity, Settings',
      () {
        expect(_labelsFor(NavigationItemMode.mobile), [
          PageLabel.dashboard,
          PageLabel.proxies,
          PageLabel.profiles,
          PageLabel.activity,
          PageLabel.settings,
        ]);
      },
    );

    test('desktop sidebar has the same primary destinations', () {
      expect(_labelsFor(NavigationItemMode.desktop), [
        PageLabel.dashboard,
        PageLabel.proxies,
        PageLabel.profiles,
        PageLabel.activity,
        PageLabel.settings,
      ]);
    });

    test('Resources is only reachable from Settings > More', () {
      expect(_labelsFor(NavigationItemMode.more), [PageLabel.resources]);
    });

    test('Proxies is hidden until there are proxies to show', () {
      expect(
        _labelsFor(NavigationItemMode.mobile, hasProxies: false),
        isNot(contains(PageLabel.proxies)),
      );
    });
  });
}
