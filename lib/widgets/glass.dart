import 'dart:ui';

import 'package:fl_clash/common/common.dart';
import 'package:flutter/material.dart';

/// Shared frosted-glass tokens.
///
/// The app shell paints one [AmbientBackground] behind everything; chrome
/// surfaces (top bar, nav rail/bar, dialogs, settings groups) then sit on
/// top of it as translucent, blurred [GlassSurface]s instead of opaque
/// Material colors, so the gradient reads through the whole app.
///
/// Not every glass surface wants the same opacity or blur: a modal that
/// must obscure the page behind it needs to read very differently from a
/// settings panel, which in turn needs to differ from a proxy card that
/// repeats a hundred times down a list. [GlassSurfaceType] classifies a
/// physical surface by that role, and [GlassTokens] holds the calibrated
/// values per role/brightness so nobody has to guess a number by hand.

/// The role a physical glass surface plays. Pick the one that matches what
/// the surface *is*, not how it happens to look — the tokens follow from
/// the role.
enum GlassSurfaceType {
  /// App-level structural chrome that's on screen exactly once at a time:
  /// AppBar, NavigationBar/NavigationRail, title bar.
  chrome,

  /// A non-modal content group sitting on the ambient background: a
  /// settings block, a low-count card group. Rows inside stay transparent.
  panel,

  /// A modal surface that must read as clearly in front of — and must
  /// meaningfully obscure — whatever is behind it: Dialog, BottomSheet,
  /// side sheet.
  modal,

  /// A transient overlay that isn't modal but still floats above content:
  /// popup menus, toasts.
  floating,

  /// A surface that repeats many times in one scroll view (proxy cards,
  /// settings text chips). Always blur = 0 — stacking dozens of
  /// [BackdropFilter]s is a real scroll-jank risk — and a low, mostly-tint
  /// opacity so nesting one inside a panel/modal doesn't compound into a
  /// near-opaque block.
  repeated,
}

/// Calibrated glass values per [GlassSurfaceType] and [Brightness]. Read
/// through [GlassTokens.blurFor]/[GlassTokens.opacityFor] rather than the
/// raw fields when resolving a surface's look.
abstract final class GlassTokens {
  static const double blurChrome = 20;
  static const double blurPanel = 20;
  static const double blurModal = 24;
  static const double blurFloating = 22;
  static const double blurRepeated = 0;

  static const double lightChromeOpacity = 0.38;
  static const double darkChromeOpacity = 0.52;

  static const double lightPanelOpacity = 0.36;
  static const double darkPanelOpacity = 0.50;

  static const double lightModalOpacity = 0.66;
  static const double darkModalOpacity = 0.58;

  static const double lightFloatingOpacity = 0.52;
  static const double darkFloatingOpacity = 0.54;

  static const double lightRepeatedOpacity = 0.18;
  static const double darkRepeatedOpacity = 0.14;

  static const double lightBorderOpacity = 0.28;
  static const double darkBorderOpacity = 0.12;

  static const double lightDividerOpacity = 0.30;
  static const double darkDividerOpacity = 0.22;

  /// Scrim behind a modal (BottomSheet/side sheet) barrier — kept low so
  /// the page behind stays recognizable instead of going grey/dark.
  static const double lightModalBarrierOpacity = 0.16;
  static const double darkModalBarrierOpacity = 0.28;

  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 22;
  static const double radiusModal = 26;

  static double blurFor(GlassSurfaceType type) => switch (type) {
    GlassSurfaceType.chrome => blurChrome,
    GlassSurfaceType.panel => blurPanel,
    GlassSurfaceType.modal => blurModal,
    GlassSurfaceType.floating => blurFloating,
    GlassSurfaceType.repeated => blurRepeated,
  };

  static double opacityFor(GlassSurfaceType type, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (type) {
      GlassSurfaceType.chrome =>
        isDark ? darkChromeOpacity : lightChromeOpacity,
      GlassSurfaceType.panel => isDark ? darkPanelOpacity : lightPanelOpacity,
      GlassSurfaceType.modal => isDark ? darkModalOpacity : lightModalOpacity,
      GlassSurfaceType.floating =>
        isDark ? darkFloatingOpacity : lightFloatingOpacity,
      GlassSurfaceType.repeated =>
        isDark ? darkRepeatedOpacity : lightRepeatedOpacity,
    };
  }

  static double borderOpacityFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorderOpacity : lightBorderOpacity;

  static double dividerOpacityFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkDividerOpacity : lightDividerOpacity;

  static double modalBarrierOpacityFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? darkModalBarrierOpacity
      : lightModalBarrierOpacity;

  /// The subtle outlineVariant stroke shared by every glass surface's
  /// default border and by [glassInputDecoration] — one formula, so the two
  /// can't drift out of sync.
  static BorderSide borderSideFor(ColorScheme colorScheme) => BorderSide(
    color: colorScheme.outlineVariant.withValues(
      alpha: borderOpacityFor(colorScheme.brightness),
    ),
  );
}

/// A translucent surface that optionally blurs whatever sits behind it.
///
/// [type] drives the default blur/opacity/border via [GlassTokens] — pass
/// `color`/`opacity`/`blurSigma` only to override a specific surface's look,
/// not as the normal way to configure one. Prefer the named constructors
/// ([GlassSurface.chrome], [.panel], [.modal], [.floating], [.repeated])
/// over the generic constructor so the role is obvious at the call site.
///
/// Blur is real (a [BackdropFilter]) for surfaces that only ever appear once
/// on screen at a time — the top bar, the nav rail/bar, dialogs, settings
/// groups. It's deliberately skipped (`blurSigma: 0`, [GlassSurfaceType.repeated])
/// for anything that can appear dozens of times at once, like proxy cards in
/// a list — stacking that many backdrop filters is a real scroll-jank risk,
/// and a flat tint over the ambient gradient still reads as "glass" there.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final OutlinedBorder shape;
  final GlassSurfaceType type;
  final Color? color;
  final double? opacity;
  final double? blurSigma;
  final BorderSide? borderSide;
  final bool showBorder;
  final List<BoxShadow>? boxShadow;

  const GlassSurface({
    super.key,
    required this.child,
    this.type = GlassSurfaceType.panel,
    this.shape = const RoundedRectangleBorder(),
    this.color,
    this.opacity,
    this.blurSigma,
    this.borderSide,
    this.showBorder = true,
    this.boxShadow,
  });

  const GlassSurface.chrome({
    super.key,
    required this.child,
    this.shape = const RoundedRectangleBorder(),
    this.color,
    this.opacity,
    this.blurSigma,
    this.borderSide,
    this.showBorder = true,
    this.boxShadow,
  }) : type = GlassSurfaceType.chrome;

  const GlassSurface.panel({
    super.key,
    required this.child,
    this.shape = const RoundedRectangleBorder(),
    this.color,
    this.opacity,
    this.blurSigma,
    this.borderSide,
    this.showBorder = true,
    this.boxShadow,
  }) : type = GlassSurfaceType.panel;

  const GlassSurface.modal({
    super.key,
    required this.child,
    this.shape = const RoundedRectangleBorder(),
    this.color,
    this.opacity,
    this.blurSigma,
    this.borderSide,
    this.showBorder = true,
    this.boxShadow,
  }) : type = GlassSurfaceType.modal;

  const GlassSurface.floating({
    super.key,
    required this.child,
    this.shape = const RoundedRectangleBorder(),
    this.color,
    this.opacity,
    this.blurSigma,
    this.borderSide,
    this.showBorder = true,
    this.boxShadow,
  }) : type = GlassSurfaceType.floating;

  /// Always blur = 0 regardless of [blurSigma] — see the class doc.
  const GlassSurface.repeated({
    super.key,
    required this.child,
    this.shape = const RoundedRectangleBorder(),
    this.color,
    this.opacity,
    this.borderSide,
    this.showBorder = true,
    this.boxShadow,
  }) : type = GlassSurfaceType.repeated,
       blurSigma = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final brightness = colorScheme.brightness;
    final baseColor = color ?? colorScheme.surfaceContainer;
    final resolvedOpacity = opacity ?? GlassTokens.opacityFor(type, brightness);
    final resolvedBlur = (type == GlassSurfaceType.repeated)
        ? 0.0
        : (blurSigma ?? GlassTokens.blurFor(type));
    final resolvedBorderSide =
        borderSide ??
        (showBorder ? GlassTokens.borderSideFor(colorScheme) : BorderSide.none);
    final tintedShape = shape.copyWith(side: resolvedBorderSide);
    final content = DecoratedBox(
      decoration: ShapeDecoration(
        shape: tintedShape,
        color: baseColor.withValues(alpha: resolvedOpacity),
        shadows: boxShadow,
      ),
      child: child,
    );
    // Every glass surface but `repeated` carries a top-edge sheen — the
    // light-catching highlight "Liquid Glass" surfaces always have. Skipped
    // for `repeated` per the class doc: it's meant to read as a lightweight
    // control repeated dozens of times, not a mini glass panel competing
    // for attention.
    final surface = type == GlassSurfaceType.repeated
        ? content
        : Stack(
            children: [
              content,
              const Positioned.fill(child: IgnorePointer(child: GlassSheen())),
            ],
          );
    if (resolvedBlur <= 0) {
      return ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: surface,
      );
    }
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: resolvedBlur, sigmaY: resolvedBlur),
        child: surface,
      ),
    );
  }
}

/// The soft top-edge highlight every non-[GlassSurfaceType.repeated]
/// [GlassSurface] carries — light catching a curved glass surface, the way
/// Apple's "Liquid Glass" material always does. Cheap: one gradient, no
/// extra [BackdropFilter], painted above [GlassSurface]'s own tint and
/// clipped by the same shape.
///
/// Public because the app's two hand-rolled chrome surfaces — the AppBar
/// and the bottom [NavigationBar] (both blur manually instead of going
/// through [GlassSurface], since neither is a clipped/shaped panel) — apply
/// this same highlight themselves for a consistent look across every glass
/// surface in the app.
class GlassSheen extends StatelessWidget {
  const GlassSheen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.colorScheme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5],
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.10 : 0.22),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Opt-in glass styling for a [TextField]/[TextFormField] that's meant to
/// float directly on AmbientBackground/GlassSurface. Most inputs in this
/// app already define their own [InputDecoration] (border, fill, padding)
/// and must NOT pick this up implicitly — apply it explicitly per field,
/// never through a global [InputDecorationTheme].
InputDecoration glassInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? helperText,
  String? suffixText,
  Widget? suffixIcon,
  Widget? prefixIcon,
  EdgeInsetsGeometry? contentPadding,
  bool alignLabelWithHint = false,
}) {
  final colorScheme = context.colorScheme;
  final brightness = colorScheme.brightness;
  final borderRadius = BorderRadius.circular(GlassTokens.radiusMedium);
  final borderSide = GlassTokens.borderSideFor(colorScheme);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
    contentPadding: contentPadding,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: colorScheme.surfaceContainer.withValues(
      alpha: GlassTokens.opacityFor(GlassSurfaceType.panel, brightness),
    ),
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: borderSide,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: borderSide,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
    ),
  );
}

/// The ambient gradient + soft color blobs painted once behind the whole app
/// shell (top bar, sidebar, page content all sit above it, translucent).
/// Derives from the active [ColorScheme] so it follows both dynamic color
/// and the user's chosen primary color automatically.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    // A flat white/black backdrop leaves nothing for the glass surfaces to
    // pick up, so the base itself carries a subtle gradient plus dynamic
    // color glows derived from the active ColorScheme (Material You/HCT).
    final baseColors = isDark
        ? const [Color(0xFF0F1118), Color(0xFF151824), Color(0xFF191B2A)]
        : const [Color(0xFFF7F9FD), Color(0xFFF0F3FA), Color(0xFFE8EDF7)];
    final primaryGlow = isDark ? 0.23 : 0.16;
    final secondaryGlow = isDark ? 0.13 : 0.10;
    final tertiaryGlow = isDark ? 0.19 : 0.12;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: baseColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -100,
            child: _GlassBlob(color: colorScheme.primary, opacity: primaryGlow),
          ),
          Positioned(
            bottom: -180,
            left: -120,
            child: _GlassBlob(
              color: colorScheme.tertiary,
              opacity: tertiaryGlow,
              size: 460,
            ),
          ),
          Positioned(
            top: 160,
            left: -80,
            child: _GlassBlob(
              color: colorScheme.secondary,
              opacity: secondaryGlow,
              size: 320,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBlob extends StatelessWidget {
  final Color color;
  final double opacity;
  final double size;

  const _GlassBlob({
    required this.color,
    required this.opacity,
    this.size = 380,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
