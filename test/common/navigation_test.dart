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

    test('desktop sidebar adds Network Insight after Activity', () {
      expect(_labelsFor(NavigationItemMode.desktop), [
        PageLabel.dashboard,
        PageLabel.proxies,
        PageLabel.profiles,
        PageLabel.activity,
        PageLabel.networkInsight,
        PageLabel.settings,
      ]);
    });

    test('Settings > More holds Network Insight (mobile) and Resources', () {
      expect(_labelsFor(NavigationItemMode.more), [
        PageLabel.networkInsight,
        PageLabel.resources,
      ]);
    });

    test('Proxies is hidden until there are proxies to show', () {
      expect(
        _labelsFor(NavigationItemMode.mobile, hasProxies: false),
        isNot(contains(PageLabel.proxies)),
      );
    });
  });
}
