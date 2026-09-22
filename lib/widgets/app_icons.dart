import 'package:flutter/material.dart';

/// Semantic icon vocabulary, not a raw `Icons.*` grab-bag: pick the name
/// that matches what a control *means* (connected, delete, window-close),
/// and let this file own which literal glyph that maps to.
///
/// One rule holds across every entry here: **the "rounded" Material Icons
/// family**, never mixed with "sharp"/"outlined"/regular within the same
/// semantic role. Flutter has no SF Symbols binding, so this is the
/// project's stand-in for that weight-consistency requirement — mixing
/// weights (a thin outlined icon next to a bold filled one) is exactly the
/// "不同粗细图标混用" the design spec calls out. The one sanctioned
/// exception is a genuine two-state filled/outlined pair (see
/// [windowPinned]/[windowUnpinned]) — Material Icons doesn't ship an
/// "outlined-rounded" combination family, and filled-vs-outlined for an
/// active/inactive toggle is itself a standard, intentional convention
/// (compare `Icons.favorite`/`favorite_border`), not an accidental mix.
///
/// Not every icon in the app goes through this file yet — this covers the
/// call sites already migrated to it (connection state, window chrome, the
/// handful of shared action buttons below). Extend it as more call sites
/// move over; don't reach past it back to a raw `Icons.*` literal for a
/// concept already named here.
abstract final class AppIcons {
  // Connection state — see lib/views/dashboard/widgets/connection_status_header.dart
  // and lib/views/dashboard/widgets/start_button.dart.
  static const IconData connected = Icons.check_circle_rounded;
  static const IconData connecting = Icons.sync_rounded;
  static const IconData disconnected = Icons.remove_circle_outline_rounded;

  // Window chrome — see lib/manager/window_manager.dart.
  static const IconData windowMinimize = Icons.minimize_rounded;
  static const IconData windowMaximize = Icons.crop_square_rounded;
  static const IconData windowRestore = Icons.filter_none_rounded;
  static const IconData windowClose = Icons.close_rounded;

  /// Active/inactive "always on top" toggle. See the file doc: this is
  /// the one sanctioned filled/outlined pair, not a weight mix.
  static const IconData windowPinned = Icons.push_pin;
  static const IconData windowUnpinned = Icons.push_pin_outlined;

  // Shared actions used across several screens' overflow menus and
  // settings rows.
  static const IconData more = Icons.more_vert_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData reset = Icons.replay_rounded;
}
