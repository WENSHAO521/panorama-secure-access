import 'package:fl_clash/common/system.dart';
import 'package:flutter/widgets.dart';

/// A semantic icon request: what the icon *means*, not which glyph to draw.
/// The platform resolver below picks the actual [IconData].
class PanoramaIconToken {
  final IconData material;

  /// Glyph for Apple platforms, when the platform convention differs from
  /// Material (e.g. the back chevron). Null means "same as [material]".
  final IconData? apple;

  const PanoramaIconToken({required this.material, this.apple});
}

/// Semantic icon → platform glyph resolver (docs/DESIGN-SYSTEM.md §Icons).
///
/// On macOS a token's [PanoramaIconToken.apple] glyph wins when it has one.
/// No SF Symbols-equivalent glyph set is bundled, so Apple variants are
/// limited to Material glyphs that follow the Apple convention; this is
/// the seam where a native set would be wired in.
abstract final class PanoramaIconResolver {
  static IconData resolve(PanoramaIconToken token, {bool? apple}) {
    if (apple ?? system.isMacOS) {
      return token.apple ?? token.material;
    }
    return token.material;
  }
}
