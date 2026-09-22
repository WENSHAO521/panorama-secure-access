import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/views.dart';
import 'package:flutter/material.dart';

class Navigation {
  static Navigation? _instance;

  List<NavigationItem> getItems({bool hasProxies = false}) {
    return [
      NavigationItem(
        icon: Icon(PanoramaIcons.navigation.home),
        label: PageLabel.home,
        builder: (_) => const HomeView(key: GlobalObjectKey(PageLabel.home)),
      ),
      NavigationItem(
        icon: Icon(PanoramaIcons.navigation.proxies),
        label: PageLabel.proxies,
        builder: (_) =>
            const ProxiesView(key: GlobalObjectKey(PageLabel.proxies)),
        modes: hasProxies
            ? [NavigationItemMode.mobile, NavigationItemMode.desktop]
            : [],
      ),
      NavigationItem(
        icon: Icon(PanoramaIcons.navigation.profiles),
        label: PageLabel.profiles,
        builder: (_) =>
            const ProfilesView(key: GlobalObjectKey(PageLabel.profiles)),
      ),
      NavigationItem(
        icon: Icon(PanoramaIcons.navigation.activity),
        label: PageLabel.activity,
        builder: (_) =>
            const ActivityView(key: GlobalObjectKey(PageLabel.activity)),
      ),
      NavigationItem(
        icon: Icon(PanoramaIcons.navigation.networkInsight),
        label: PageLabel.networkInsight,
        description: 'networkInsightDesc',
        builder: (_) => const NetworkInsightView(
          key: GlobalObjectKey(PageLabel.networkInsight),
        ),
        modes: [NavigationItemMode.desktop, NavigationItemMode.more],
      ),
      // The earlier customizable widget dashboard, kept reachable from
      // Settings > More so existing widget layouts aren't lost.
      NavigationItem(
        keep: false,
        icon: Icon(PanoramaIcons.navigation.dashboard),
        label: PageLabel.dashboard,
        description: 'dashboardDesc',
        builder: (_) =>
            const DashboardView(key: GlobalObjectKey(PageLabel.dashboard)),
        modes: [NavigationItemMode.more],
      ),
      NavigationItem(
        icon: Icon(PanoramaIcons.navigation.resources),
        label: PageLabel.resources,
        description: 'resourcesDesc',
        builder: (_) =>
            const ResourcesView(key: GlobalObjectKey(PageLabel.resources)),
        modes: [NavigationItemMode.more],
      ),
      NavigationItem(
        icon: Icon(PanoramaIcons.navigation.settings),
        label: PageLabel.settings,
        builder: (_) =>
            const SettingsView(key: GlobalObjectKey(PageLabel.settings)),
      ),
    ];
  }

  Navigation._internal();

  factory Navigation() {
    _instance ??= Navigation._internal();
    return _instance!;
  }
}

final navigation = Navigation();
