import 'package:fl_clash/design/icons/panorama_icon_resolver.dart';
import 'package:flutter/material.dart';

/// Panorama Design System — semantic icon system (docs/DESIGN-SYSTEM.md).
///
/// Call sites name what an icon means (`PanoramaIcons.actions.delete`), never
/// a glyph. Each meaning has exactly one glyph; where the app used several
/// variants for one meaning (filled and outlined delete, two sync glyphs),
/// the token picks one. `service` is left unpopulated until a real call site
/// needs it, rather than guessed.
abstract final class PanoramaIcons {
  static const navigation = _PanoramaNavigationIcons();
  static const connection = _PanoramaConnectionIcons();
  static const actions = _PanoramaActionIcons();
  static const network = _PanoramaNetworkIcons();
  static const routing = _PanoramaRoutingIcons();
  static const status = _PanoramaStatusIcons();
  static const window = _PanoramaWindowIcons();
  static const files = _PanoramaFileIcons();
  static const traffic = _PanoramaTrafficIcons();
  static const system = _PanoramaSystemIcons();
  static const appearance = _PanoramaAppearanceIcons();
  static const settings = _PanoramaSettingsIcons();
}

IconData _icon(IconData material, {IconData? apple}) =>
    PanoramaIconResolver.resolve(
      PanoramaIconToken(material: material, apple: apple),
    );

class _PanoramaNavigationIcons {
  const _PanoramaNavigationIcons();

  IconData get home => _icon(Icons.home_outlined);

  IconData get proxies => _icon(Icons.device_hub);

  IconData get profiles => _icon(Icons.folder_outlined);

  IconData get activity => _icon(Icons.swap_vert);

  IconData get networkInsight => _icon(Icons.public);

  IconData get settings => _icon(Icons.settings_outlined);

  /// The classic widget dashboard (Settings › More).
  IconData get dashboard => _icon(Icons.space_dashboard_outlined);

  IconData get resources => _icon(Icons.storage);

  /// Leave the current page or sheet. Apple platforms use the chevron.
  IconData get back =>
      _icon(Icons.arrow_back, apple: Icons.arrow_back_ios_new_rounded);

  /// Trailing "opens a sub-page" affordance on a row.
  IconData get disclosure => _icon(Icons.arrow_forward_ios);

  /// A collapsible section that is open.
  IconData get expand => _icon(Icons.expand_more_rounded);

  /// A collapsible section that is closed.
  IconData get collapsed => _icon(Icons.chevron_right_rounded);

  /// Shows or hides the labels of the navigation rail.
  IconData get railLabels => _icon(Icons.menu);
}

class _PanoramaConnectionIcons {
  const _PanoramaConnectionIcons();

  IconData get connected => _icon(Icons.check_circle_outline);

  IconData get connecting => _icon(Icons.sync);

  IconData get disconnected => _icon(Icons.radio_button_unchecked);

  IconData get error => _icon(Icons.error_outline);

  /// Connect / disconnect control.
  IconData get power => _icon(Icons.power_settings_new);

  /// Compact "is on" mark inside the round connect control.
  IconData get active => _icon(Icons.check_rounded);
}

class _PanoramaActionIcons {
  const _PanoramaActionIcons();

  IconData get refresh => _icon(Icons.refresh);

  /// Distinct from [_PanoramaConnectionIcons.connecting]: this is a "sync/
  /// update this data" action (e.g. update providers), not a connection
  /// status indicator, even though both currently use the same glyph.
  IconData get sync => _icon(Icons.sync);

  IconData get copy => _icon(Icons.content_copy);

  IconData get paste => _icon(Icons.content_paste);

  IconData get search => _icon(Icons.search);

  IconData get filter => _icon(Icons.filter_list);

  IconData get sort => _icon(Icons.sort);

  IconData get sortByName => _icon(Icons.sort_by_alpha);

  IconData get sortByTime => _icon(Icons.timeline);

  IconData get delete => _icon(Icons.delete_outline);

  /// Clear every item of a list at once.
  IconData get clearAll => _icon(Icons.delete_sweep_outlined);

  IconData get add => _icon(Icons.add);

  /// Add a widget or item into an editable layout.
  IconData get addItem => _icon(Icons.add_circle);

  /// Remove an entry from a list without deleting what it refers to.
  IconData get remove => _icon(Icons.remove);

  IconData get close => _icon(Icons.close);

  /// Accept the edits on this page.
  IconData get confirm => _icon(Icons.check);

  IconData get edit => _icon(Icons.edit_outlined);

  IconData get save => _icon(Icons.save);

  /// Save to a file of the user's choosing.
  IconData get saveAs => _icon(Icons.save_as_outlined);

  IconData get exportFile => _icon(Icons.file_copy_outlined);

  IconData get upload => _icon(Icons.upload);

  /// Fetch content from elsewhere (e.g. import from a URL).
  IconData get fetch => _icon(Icons.arrow_downward);

  IconData get openExternal => _icon(Icons.launch);

  /// Overflow menu.
  IconData get more => _icon(Icons.more_vert);

  /// Nested menu of further actions.
  IconData get moreActions => _icon(Icons.emergency_outlined);

  /// Options / preferences for the current page.
  IconData get options => _icon(Icons.tune);

  IconData get reset => _icon(Icons.replay);

  IconData get undo => _icon(Icons.undo);

  IconData get redo => _icon(Icons.redo);

  IconData get previous => _icon(Icons.arrow_upward);

  IconData get next => _icon(Icons.arrow_downward);

  IconData get dragHandle => _icon(Icons.drag_handle);

  IconData get selectAll => _icon(Icons.select_all);

  IconData get deselectAll => _icon(Icons.deselect);

  IconData get toggle => _icon(Icons.swap_horiz);

  /// Let the app pick a selection for the user.
  IconData get smartSelect => _icon(Icons.auto_awesome);

  /// Open read-only.
  IconData get view => _icon(Icons.visibility_outlined);

  /// Reveal an obscured value (password field).
  IconData get show => _icon(Icons.visibility);

  /// Obscure a revealed value (password field).
  IconData get hide => _icon(Icons.visibility_off);

  /// Scroll to the selected item.
  IconData get locate => _icon(Icons.adjust);

  /// Resume following new entries at the edge of a live list.
  IconData get follow => _icon(Icons.vertical_align_top);

  /// Stop following new entries in a live list.
  IconData get stopFollowing => _icon(Icons.block);

  /// Close a single live connection.
  IconData get closeConnection => _icon(Icons.block);

  IconData get pickColor => _icon(Icons.colorize);
}

class _PanoramaNetworkIcons {
  const _PanoramaNetworkIcons();

  /// Latency test of a group or node; also "sort by latency".
  IconData get ping => _icon(Icons.network_ping);

  /// One-tap latency test on a single node card.
  IconData get quickTest => _icon(Icons.bolt);

  /// Exit IP / connectivity check.
  IconData get check => _icon(Icons.network_check);

  /// Addresses of this device on the local network.
  IconData get localAddresses => _icon(Icons.devices);
}

class _PanoramaRoutingIcons {
  const _PanoramaRoutingIcons();

  /// Rule / global / direct outbound mode selector.
  IconData get mode => _icon(Icons.call_split_sharp);

  IconData get tun => _icon(Icons.stacked_line_chart);

  IconData get systemProxy => _icon(Icons.shuffle);

  /// Proxy providers of the current profile.
  IconData get providers => _icon(Icons.poll_outlined);

  /// Per-app access control: only the selected apps use the proxy.
  IconData get acceptSelected => _icon(Icons.adjust_outlined);

  /// Per-app access control: the selected apps bypass the proxy.
  IconData get rejectSelected => _icon(Icons.block_outlined);

  /// Profile override (standard, script or custom).
  IconData get override => _icon(Icons.extension_outlined);

  IconData get overrideStandard => _icon(Icons.stars);

  IconData get overrideScript => _icon(Icons.rocket);

  IconData get overrideCustom => _icon(Icons.dashboard_customize);
}

/// Result-state glyphs. Always shown next to a text label, never alone
/// (brief §100: status must not depend on colour or a single glyph).
class _PanoramaStatusIcons {
  const _PanoramaStatusIcons();

  IconData get ok => _icon(Icons.check_circle_outline);

  IconData get partial => _icon(Icons.remove_circle_outline);

  IconData get blocked => _icon(Icons.block);

  IconData get failed => _icon(Icons.error_outline);

  IconData get unknown => _icon(Icons.help_outline);

  IconData get notChecked => _icon(Icons.radio_button_unchecked);

  /// This item is the selected one.
  IconData get selected => _icon(Icons.check);

  IconData get info => _icon(Icons.info_outline);

  /// Attention needed on an item (drawn in the error colour).
  IconData get alert => _icon(Icons.info);

  IconData get error => _icon(Icons.error);

  /// Full-page error state.
  IconData get problem => _icon(Icons.report_problem);
}

/// Desktop window caption buttons.
class _PanoramaWindowIcons {
  const _PanoramaWindowIcons();

  IconData get pin => _icon(Icons.push_pin);

  IconData get unpin => _icon(Icons.push_pin_outlined);

  IconData get minimize => _icon(Icons.remove);

  IconData get maximize => _icon(Icons.crop_square);

  IconData get restore => _icon(Icons.filter_none);

  IconData get close => _icon(Icons.close);
}

class _PanoramaFileIcons {
  const _PanoramaFileIcons();

  IconData get qrCode => _icon(Icons.qr_code_sharp);

  IconData get importFile => _icon(Icons.upload_file_sharp);

  IconData get importUrl => _icon(Icons.cloud_download_sharp);

  /// Pick an image from the photo library.
  IconData get gallery => _icon(Icons.photo_camera_back);
}

class _PanoramaTrafficIcons {
  const _PanoramaTrafficIcons();

  IconData get upload => _icon(Icons.arrow_upward);

  IconData get download => _icon(Icons.arrow_downward);

  IconData get speed => _icon(Icons.speed_sharp);

  IconData get usage => _icon(Icons.data_saver_off);
}

class _PanoramaSystemIcons {
  const _PanoramaSystemIcons();

  IconData get memory => _icon(Icons.memory);

  IconData get torchOn => _icon(Icons.flash_on);

  IconData get torchOff => _icon(Icons.flash_off);

  IconData get torchAuto => _icon(Icons.flash_auto);
}

class _PanoramaAppearanceIcons {
  const _PanoramaAppearanceIcons();

  IconData get themeMode => _icon(Icons.brightness_high);

  IconData get followSystem => _icon(Icons.auto_mode);

  IconData get light => _icon(Icons.light_mode);

  IconData get dark => _icon(Icons.dark_mode);

  IconData get color => _icon(Icons.palette);

  IconData get pureBlack => _icon(Icons.contrast);

  IconData get textScale => _icon(Icons.text_fields);

  IconData get tabLayout => _icon(Icons.view_carousel);

  IconData get listLayout => _icon(Icons.view_list);
}

/// Leading icons of settings rows, named after the setting.
class _PanoramaSettingsIcons {
  const _PanoramaSettingsIcons();

  IconData get language => _icon(Icons.language_outlined);

  IconData get theme => _icon(Icons.style);

  IconData get backup => _icon(Icons.cloud_sync);

  IconData get hotkeys => _icon(Icons.keyboard);

  IconData get loopback => _icon(Icons.lock);

  IconData get accessControl => _icon(Icons.view_list);

  IconData get basicConfig => _icon(Icons.edit);

  IconData get advancedConfig => _icon(Icons.build);

  IconData get application => _icon(Icons.settings);

  IconData get disclaimer => _icon(Icons.gavel);

  IconData get about => _icon(Icons.info);

  IconData get developerMode => _icon(Icons.developer_board);

  IconData get logLevel => _icon(Icons.info_outline);

  IconData get userAgent => _icon(Icons.computer_outlined);

  IconData get keepAlive => _icon(Icons.timer_outlined);

  IconData get testUrl => _icon(Icons.timeline);

  IconData get port => _icon(Icons.adjust_outlined);

  IconData get hosts => _icon(Icons.view_list_outlined);

  IconData get ipv6 => _icon(Icons.water_outlined);

  IconData get systemDns => _icon(Icons.dns_outlined);

  IconData get allowLan => _icon(Icons.device_hub);

  IconData get unifiedDelay => _icon(Icons.compress_outlined);

  IconData get findProcess => _icon(Icons.polymer_outlined);

  IconData get tcpConcurrent => _icon(Icons.double_arrow_outlined);

  IconData get geodataLoader => _icon(Icons.memory);

  IconData get externalController => _icon(Icons.api_outlined);

  IconData get network => _icon(Icons.vpn_key);

  IconData get onDemand => _icon(Icons.ssid_chart);

  IconData get dns => _icon(Icons.dns);

  IconData get addedRules => _icon(Icons.library_books);

  IconData get scripts => _icon(Icons.rocket);

  IconData get webdavAccount => _icon(Icons.account_box);

  IconData get address => _icon(Icons.link);

  IconData get account => _icon(Icons.account_circle);

  IconData get password => _icon(Icons.password);
}
