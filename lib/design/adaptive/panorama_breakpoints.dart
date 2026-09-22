import 'package:flutter/widgets.dart';

/// Panorama Design System — adaptive layout classes.
///
/// Centralizes the compact/medium/expanded layout decision so it isn't
/// repeated as ad hoc `width > n` checks across the app. See
/// docs/DESIGN-SYSTEM.md for the audit that motivated this.
enum PanoramaLayoutClass {
  /// Phone-width layouts: bottom navigation, single-column content.
  compact,

  /// Tablet / small-window desktop: compact sidebar or rail.
  medium,

  /// Full desktop: sidebar navigation, multi-pane content.
  expanded;

  /// Thresholds are placeholders tuned against content needs, not device
  /// models, per the brief's own guidance — expected to move as pages
  /// adopt this resolver.
  static PanoramaLayoutClass fromWidth(double width) {
    if (width < 600) {
      return PanoramaLayoutClass.compact;
    }
    if (width < 1024) {
      return PanoramaLayoutClass.medium;
    }
    return PanoramaLayoutClass.expanded;
  }

  static PanoramaLayoutClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }
}
