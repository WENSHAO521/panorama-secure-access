import 'package:fl_clash/common/system.dart';

/// Panorama Design System — platform-aware font family resolution
/// (docs/DESIGN-SYSTEM.md §Typography).
///
/// - macOS (and future iOS): system font — Apple platforms carry a strong
///   expectation of native typography (San Francisco), so Panorama does
///   not force its bundled Inter face there.
/// - Windows / Linux / Android: Inter, the current bundled Panorama brand
///   face.
///
/// JetBrains Mono (logs/YAML/script/technical values) is unrelated to this
/// resolver and stays wired at its own call sites.
abstract final class PanoramaTypography {
  /// The system-font sentinel Flutter recognizes on Apple platforms to
  /// substitute the native UI font (San Francisco) instead of falling back
  /// to bundled Roboto. This is a widely used technique in Flutter macOS
  /// apps, but it has not been visually verified in this environment — no
  /// macOS runtime is available here. Confirm on a real macOS build before
  /// relying on it.
  static const String _appleSystemFontSentinel = '.AppleSystemUIFont';

  static const String _brandFontFamily = 'Inter';

  /// Font family for [ThemeData.fontFamily]. Returns the Apple system-font
  /// sentinel on macOS, otherwise the bundled brand font.
  static String get appFontFamily {
    if (system.isMacOS) {
      return _appleSystemFontSentinel;
    }
    return _brandFontFamily;
  }
}
