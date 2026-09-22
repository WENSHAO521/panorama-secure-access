import 'package:fl_clash/design/icons/panorama_icon_resolver.dart';
import 'package:flutter/material.dart';

/// Panorama Design System — semantic icon system (docs/DESIGN-SYSTEM.md).
///
/// First slice only: `navigation`, `connection`, `actions`. Other
/// categories from the brief (`network`, `service`, `window`, `files`,
/// `system`, `developer`, `routing`, `traffic`) are intentionally left
/// unpopulated rather than guessed — see docs/DESIGN-SYSTEM.md for why.
/// Existing `Icons.*` call sites are not migrated yet; this only adds the
/// destination for that migration.
///
/// Glyph choices below are deliberately restricted to long-established
/// classic Material glyphs (no ambiguous `_outlined` variants) because
/// this environment has no Flutter/Dart SDK to run `flutter analyze`
/// against — see docs/UI-MODERNIZATION-REPORT.md.
abstract final class PanoramaIcons {
  static const navigation = _PanoramaNavigationIcons();
  static const connection = _PanoramaConnectionIcons();
  static const actions = _PanoramaActionIcons();
}

class _PanoramaNavigationIcons {
  const _PanoramaNavigationIcons();

  IconData get home =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.home_outlined));

  IconData get proxies =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.device_hub));

  IconData get profiles =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.folder_outlined));

  IconData get activity =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.swap_vert));

  IconData get networkInsight =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.public));

  IconData get settings =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.settings_outlined));
}

class _PanoramaConnectionIcons {
  const _PanoramaConnectionIcons();

  IconData get connected =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.check_circle_outline));

  IconData get connecting =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.sync));

  IconData get disconnected => PanoramaIconResolver.resolve(
    const PanoramaIconToken(material: Icons.radio_button_unchecked),
  );

  IconData get error =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.error_outline));
}

class _PanoramaActionIcons {
  const _PanoramaActionIcons();

  IconData get refresh =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.refresh));

  IconData get copy =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.content_copy));

  IconData get search =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.search));

  IconData get filter =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.filter_list));

  IconData get sort =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.sort));

  IconData get delete =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.delete_outline));

  IconData get add =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.add));
}
