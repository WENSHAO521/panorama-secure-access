import 'package:fl_clash/common/system.dart';
import 'package:flutter/widgets.dart';

/// A semantic icon request: what the icon *means*, not which glyph to draw.
/// The platform resolver below picks the actual [IconData].
class PanoramaIconToken {
  final IconData material;

  const PanoramaIconToken({required this.material});
}

/// Semantic icon → platform glyph resolver (docs/DESIGN-SYSTEM.md §Icons).
///
/// Apple platforms are meant to eventually resolve to native symbol
/// glyphs (SF Symbols-equivalent); no such glyph set is bundled yet, so
/// [resolve] currently returns the same Material glyph on every platform.
/// This is the seam where that gets wired in, not a claim it already
/// exists.
abstract final class PanoramaIconResolver {
  static IconData resolve(PanoramaIconToken token) {
    if (system.isMacOS) {
      // TODO(icons): resolve to a native Apple symbol set once bundled.
      return token.material;
    }
    return token.material;
  }
}
