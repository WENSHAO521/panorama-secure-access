import 'package:flutter/widgets.dart';

/// Panorama Design System — adaptive layout classes.
///
/// The one place the compact/medium/expanded decision is made (brief
/// §90–94). `ViewMode` and the navigation mode derive from it; pages that
/// need a content-specific switch (the connections table, log lines) decide
/// on their own `LayoutBuilder` width, not on the window.
///
/// Navigation per class, used the same way everywhere:
/// - compact: bottom navigation bar;
/// - medium: navigation rail (icons, labels optional);
/// - expanded: sidebar (the rail extended, labels beside icons).
enum PanoramaLayoutClass {
  /// Phone-width layouts: bottom navigation, single-column content.
  compact,

  /// Tablets and small desktop windows: navigation rail.
  medium,

  /// Large windows: sidebar.
  expanded;

  /// Below this, an 80 px rail beside the narrowest page (the 520 px of a
  /// card column or a 560 px dialog) doesn't fit: use a bottom bar.
  static const double mediumMin = 600;

  /// From here the 200 px sidebar still leaves about 824 px of content,
  /// more than the 4-column dashboard got at its old threshold with the
  /// rail (761 px).
  static const double expandedMin = 1024;

  /// Thresholds follow content, not device models.
  static PanoramaLayoutClass fromWidth(double width) {
    if (width < mediumMin) {
      return PanoramaLayoutClass.compact;
    }
    if (width < expandedMin) {
      return PanoramaLayoutClass.medium;
    }
    return PanoramaLayoutClass.expanded;
  }

  static PanoramaLayoutClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }
}
