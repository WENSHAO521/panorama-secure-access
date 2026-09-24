// ignore_for_file: constant_identifier_names

import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart';

const appName = 'Panorama Secure Access';
// TUN adapter friendly name. Using the full multi-word appName (with
// spaces) here has been observed to make wintun adapter creation fail on
// some Windows setups; keep this short and space-free, matching upstream's
// own move away from a full app-name-based device name.
const tunDeviceName = 'PanoramaTun';
const appHelperService = 'FlClashHelperService';
const coreName = 'clash.meta';
const browserUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
const packageName = 'com.follow.clash';
final unixSocketPath = '/tmp/FlClashSocket_${Random().nextInt(10000)}.sock';
final windowsPipeName = '\\\\.\\pipe\\FlClashCore_${Random().nextInt(10000)}';
const helperPort = 47890;
const maxTextScale = 1.4;
const minTextScale = 0.8;
final baseInfoEdgeInsets = EdgeInsets.symmetric(
  vertical: 16.mAp,
  horizontal: 16.mAp,
);
final listHeaderPadding = EdgeInsets.only(
  left: 16.mAp,
  right: 8.mAp,
  top: 24.mAp,
  bottom: 8.mAp,
);
// Must match _AdaptiveSheetScaffoldState._buildSheetHeader's actual
// rendered height (lib/widgets/sheet.dart): drag handle padding (6 top + 6
// bottom) + handle (4) + title row (48) + trailing gap (6) = 70. Used as
// sheetTopPadding for SheetType.bottomSheet so scrollable content under a
// floating (sheetTransparentToolBar: true) header starts clear of it.
const sheetAppBarHeight = 70.0;

/// Height of HomePage's mobile bottom NavigationBar (see
/// `_NavigationBarDefaultsM3` in lib/pages/home.dart).
const kHomeNavigationBarHeight = 80.0;

const watchExecution = false;

final defaultTextScaleFactor =
    WidgetsBinding.instance.platformDispatcher.textScaleFactor;
const httpTimeoutDuration = Duration(milliseconds: 5000);

/// Keep at or below the Core's delay-test concurrency (`mBatch` in
/// core/common.go). Surplus requests queue inside the Core behind a full wave
/// of 5s timeouts, which no RPC timeout can cover.
const maxConcurrentDelayTests = 50;
const moreDuration = Duration(milliseconds: 100);
const animateDuration = Duration(milliseconds: 100);
const midDuration = Duration(milliseconds: 200);
const commonDuration = Duration(milliseconds: 300);
const defaultUpdateDuration = Duration(days: 1);
const MMDB = 'GEOIP.metadb';
const ASN = 'ASN.mmdb';
const GEOIP = 'GEOIP.dat';
const GEOSITE = 'GEOSITE.dat';
final double kHeaderHeight = system.isDesktop
    ? !system.isMacOS
          ? 40
          : 28
    : 0;
const profilesDirectoryName = 'profiles';
const localhost = '127.0.0.1';
const clashConfigKey = 'clash_config';
const configKey = 'config';
const double dialogCommonWidth = 300;
const repository = 'WENSHAO521/panorama-secure-access';
const defaultExternalController = '127.0.0.1:9090';
const defaultTestUrl = 'https://www.gstatic.com/generate_204';
final commonFilter = ImageFilter.blur(
  sigmaX: 5,
  sigmaY: 5,
  tileMode: TileMode.clamp,
);

const listEquality = ListEquality();
const navigationItemListEquality = ListEquality<NavigationItem>();
const trackerInfoListEquality = ListEquality<TrackerInfo>();
const stringListEquality = ListEquality<String>();
const intListEquality = ListEquality<int>();
const logListEquality = ListEquality<Log>();
const groupListEquality = ListEquality<Group>();
const ruleListEquality = ListEquality<Rule>();
const scriptListEquality = ListEquality<Script>();
const externalProviderListEquality = ListEquality<ExternalProvider>();
const packageListEquality = ListEquality<Package>();
const profileListEquality = ListEquality<Profile>();
const proxyGroupsEquality = ListEquality<ProxyGroup>();
const hotKeyActionListEquality = ListEquality<HotKeyAction>();
const stringAndStringMapEquality = MapEquality<String, String>();
const stringAndStringMapEntryListEquality =
    ListEquality<MapEntry<String, String>>();
const stringAndStringMapEntryIterableEquality =
    IterableEquality<MapEntry<String, String>>();
const stringAndObjectMapEntryIterableEquality =
    IterableEquality<MapEntry<String, Object?>>();
const delayMapEquality = MapEquality<String, Map<String, int?>>();
const stringSetEquality = SetEquality<String>();
const keyboardModifierListEquality = SetEquality<KeyboardModifier>();

const viewModeColumnsMap = {
  ViewMode.mobile: [2, 1],
  ViewMode.laptop: [3, 2],
  ViewMode.desktop: [4, 3],
};

const proxiesListStoreKey = PageStorageKey<String>('proxies_list');
const toolsStoreKey = PageStorageKey<String>('tools');
const profilesStoreKey = PageStorageKey<String>('profiles');

// PSG brand violet.
const defaultPrimaryColor = 0xFF6D5EF7;

double getWidgetHeight(num lines) {
  final space = 14.mAp;
  return max(lines * (80.ap + space) - space, 0);
}

const maxLength = 1000;

const mainIsolate = 'FlClashMainIsolate';

const serviceIsolate = 'FlClashServiceIsolate';

const defaultPrimaryColors = [
  defaultPrimaryColor,
  0xFF4F46E5,
  0xFF14162B,
  0xFF6B6E85,
  0xFF03A9F4,
  0XFFABD397,
  0xFF795548,
  0xFF5688F7, // Midnight Blue accent
  0xFF46C9D5, // Aurora teal accent
];

const scriptTemplate = '''
const main = (config) => {
  return config;
}''';

const backupDatabaseName = 'database.sqlite';
const configJsonName = 'config.json';
