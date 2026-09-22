import 'package:flutter/material.dart';

/// Panorama Design System — semantic color tokens.
///
/// Resolves against the app's existing [ColorScheme] rather than a second,
/// hardcoded palette, so light/dark calibration inherits current theming.
/// See docs/DESIGN-SYSTEM.md. Brand color is exposed only as [accent] —
/// never a full-screen wash.
extension PanoramaColorsExt on ColorScheme {
  Color get backgroundPrimary => surface;

  Color get backgroundSecondary => surfaceContainerLow;

  Color get surfacePlain => surfaceContainer;

  Color get surfaceElevated => surfaceContainerHigh;

  /// Reserved for glass/chrome surfaces (navigation, toolbars, popovers).
  /// Content layers should prefer [surfacePlain] / [surfaceElevated].
  Color get surfaceGlass => surfaceContainerHighest.withValues(alpha: 0.72);

  Color get labelPrimary => onSurface;

  Color get labelSecondary => onSurfaceVariant;

  Color get labelTertiary => onSurfaceVariant.withValues(alpha: 0.64);

  Color get separator => outlineVariant;

  Color get accent => primary;

  Color get success => const Color(0xFF34C759);

  Color get warning => const Color(0xFFFF9F0A);

  Color get danger => error;

  Color get latencyGood => success;

  Color get latencyMedium => warning;

  Color get latencyPoor => danger;
}
