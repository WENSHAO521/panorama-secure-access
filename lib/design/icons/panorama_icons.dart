import 'package:fl_clash/design/icons/panorama_icon_resolver.dart';
import 'package:flutter/material.dart';

/// Panorama Design System — semantic icon system (docs/DESIGN-SYSTEM.md).
///
/// `navigation`, `connection`, `actions`, `network`, `routing` are
/// populated. `service`, `window`, `files`, `system`, `developer`,
/// `traffic` are intentionally left unpopulated rather than guessed — see
/// docs/DESIGN-SYSTEM.md for why.
///
/// Glyph choices are restricted to two safe sources, since this
/// environment has no Flutter/Dart SDK to run `flutter analyze` against
/// (see docs/UI-MODERNIZATION-REPORT.md): long-established classic
/// Material glyph names, or glyphs copied verbatim from an existing
/// `Icons.*` call site already compiling elsewhere in this repo (each such
/// glyph is annotated with its source file below).
abstract final class PanoramaIcons {
  static const navigation = _PanoramaNavigationIcons();
  static const connection = _PanoramaConnectionIcons();
  static const actions = _PanoramaActionIcons();
  static const network = _PanoramaNetworkIcons();
  static const routing = _PanoramaRoutingIcons();
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

class _PanoramaNetworkIcons {
  const _PanoramaNetworkIcons();

  /// Source: lib/views/proxies/tab.dart (node latency test action).
  IconData get ping =>
      PanoramaIconResolver.resolve(const PanoramaIconToken(material: Icons.network_ping));
}

class _PanoramaRoutingIcons {
  const _PanoramaRoutingIcons();

  /// Source: lib/views/dashboard/widgets/outbound_mode.dart (rule/global/
  /// direct outbound mode selector).
  IconData get mode => PanoramaIconResolver.resolve(
    const PanoramaIconToken(material: Icons.call_split_sharp),
  );
}
