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

  /// A transient overlay that isn't modal but still floats above content.
  /// Currently unused — popup menus and toasts, its original occupants,
  /// were promoted to [crystal] (see that value's doc). Kept as a token
  /// for a future surface that wants floating-tier treatment without
  /// reaching all the way to crystal.
  floating,

  /// A surface that repeats many times in one scroll view (proxy cards,
  /// settings text chips). Always blur = 0 — stacking dozens of
  /// [BackdropFilter]s is a real scroll-jank risk — and a low, mostly-tint
  /// opacity so nesting one inside a panel/modal doesn't compound into a
  /// near-opaque block.
  repeated,

  /// The top of the glass hierarchy: Command Palette, Context Menu
  /// (`CommonPopupMenu`), Popover, Toast (`StatusManager`'s message
  /// surface), Color/Date Picker, Tooltip — surfaces that float highest
  /// and appear one at a time, never stacked or repeated. Highest
  /// blur/opacity of any role and the only type that paints a directional
  /// edge highlight ([GlassSurface] adds it automatically). Reserve this
  /// for the handful of components that are genuinely the top layer; using
  /// it everywhere defeats the hierarchy it exists to express.
  crystal,
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
  static const double blurCrystal = 36;

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

  static const double lightCrystalOpacity = 0.68;
  static const double darkCrystalOpacity = 0.74;

  // How much of the theme's ColorScheme.primary is mixed into a glass
  // surface's base colour before opacity is applied. This is what makes the
  // frosted panels read as *this app's* glass rather than generic
  // grey-tinted blur — the hue always follows the active primary color
  // (default brand violet, a user-picked accent, or Material You dynamic
  // color), so it stays consistent with whatever the rest of the UI is
  // themed with. Kept low: enough to tint, not enough to fight the content
  // drawn on top of the surface for attention.
  static const double lightTintChrome = 0.05;
  static const double darkTintChrome = 0.10;

  static const double lightTintPanel = 0.05;
  static const double darkTintPanel = 0.09;

  static const double lightTintModal = 0.07;
  static const double darkTintModal = 0.11;

  static const double lightTintFloating = 0.06;
  static const double darkTintFloating = 0.10;

  // Kept lowest: this type repeats dozens of times in one scroll view
  // (proxy cards), so a strong tint would compound into a muddy wash.
  static const double lightTintRepeated = 0.03;
  static const double darkTintRepeated = 0.05;

  static const double lightTintCrystal = 0.07;
  static const double darkTintCrystal = 0.12;

  // How much of primary is mixed into the neutral outlineVariant border —
  // a faint brand-coloured edge instead of a plain grey hairline.
  static const double borderTintStrength = 0.30;

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

  // Named scale for the components the "Soft Crystal Glass" spec covers
  // that don't yet have a dedicated radius token above. radiusSmall/
  // Medium/Large/Modal above are unchanged and still govern every call
  // site that already used them. radiusButton is wired into the app-wide
  // button theme (application.dart) and the nav indicator shape below;
  // radiusCard is wired into CommonCard's default and SettingsBlock
  // (widgets/card.dart); radiusInput/Panel/Sidebar/CommandPalette are not
  // yet consumed anywhere.
  static const double radiusButton = 10;
  static const double radiusInput = 10;
  static const double radiusCard = 16;
  static const double radiusPanel = 18;
  static const double radiusSidebar = 20;
  static const double radiusCommandPalette = 24;

  // Motion scale for the same spec. hoverDuration/modalMotionDuration are
  // new; panelMotionDuration intentionally matches the app's existing
  // `midDuration` (lib/common/constant.dart) rather than introducing a
  // second 200ms constant.
  static const Duration hoverDuration = Duration(milliseconds: 150);
  static const Duration panelMotionDuration = Duration(milliseconds: 200);
  static const Duration modalMotionDuration = Duration(milliseconds: 240);
  static const double maxHoverScale = 1.01;

  // Directional edge highlight for GlassSurfaceType.crystal — a 1px
  // gradient border weighted top/top-left/left, fading out by the
  // bottom-right corner, like light grazing across a glass edge rather
  // than a glowing outline. Only [GlassSurfaceType.crystal] paints this;
  // every other type keeps its plain [borderSideFor] hairline.
  static const double lightEdgeHighlightOpacity = 0.55;
  static const double darkEdgeHighlightOpacity = 0.16;

  static Color edgeHighlightColorFor(Brightness brightness) => Colors.white
      .withValues(
        alpha: brightness == Brightness.dark
            ? darkEdgeHighlightOpacity
            : lightEdgeHighlightOpacity,
      );

  // Selected-state fill for a nav item (sidebar rail destination, bottom
  // nav destination): a soft primary-tinted wash instead of a solid
  // ColorScheme.secondaryContainer pill, per the "don't mark active with a
  // large colour block" rule — inner highlight, not paint. Shared by
  // NavigationBar (mobile) and NavigationRail (desktop/laptop) so both
  // read as the same material.
  static const double lightNavIndicatorOpacity = 0.14;
  static const double darkNavIndicatorOpacity = 0.20;

  static Color navIndicatorColorFor(ColorScheme colorScheme) => colorScheme
      .primary
      .withValues(
        alpha: colorScheme.brightness == Brightness.dark
            ? darkNavIndicatorOpacity
            : lightNavIndicatorOpacity,
      );

  static ShapeBorder get navIndicatorShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton));

  // Ambient shadow for the modal (Dialog/BottomSheet/side sheet) and
  // crystal (Command Palette/Context Menu/Popover/Toast) tiers — large and
  // soft, never a tight Material elevation shadow. Deliberately not
  // wired into [GlassSurface]'s default rendering: chrome/panel/repeated
  // surfaces are flush with the shell or repeat dozens of times, and
  // don't want a shadow at all. Callers pass these explicitly via the
  // `boxShadow` parameter.
  static List<BoxShadow> modalShadowFor(Brightness brightness) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.38 : 0.10,
      ),
      blurRadius: 60,
      offset: const Offset(0, 22),
    ),
  ];

  static List<BoxShadow> crystalShadowFor(Brightness brightness) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.42 : 0.14,
      ),
      blurRadius: 70,
      offset: const Offset(0, 24),
    ),
  ];

  // "If the background is complex, automatically raise glass opacity" —
  // MediaQuery.highContrast (Increase Contrast on iOS/macOS, equivalent
  // accessibility settings elsewhere) means whatever is behind a glass
  // surface can't be trusted to give the content on top of it enough
  // contrast, so every [GlassSurface] pulls its opacity most of the way to
  // fully opaque rather than trying to individually verify contrast against
  // an arbitrary, possibly-busy background.
  static double boostOpacityForHighContrast(double opacity) =>
      (opacity + (1 - opacity) * 0.6).clamp(0.0, 1.0);

  static double blurFor(GlassSurfaceType type) => switch (type) {
    GlassSurfaceType.chrome => blurChrome,
    GlassSurfaceType.panel => blurPanel,
    GlassSurfaceType.modal => blurModal,
    GlassSurfaceType.floating => blurFloating,
    GlassSurfaceType.repeated => blurRepeated,
    GlassSurfaceType.crystal => blurCrystal,
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
      GlassSurfaceType.crystal =>
        isDark ? darkCrystalOpacity : lightCrystalOpacity,
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

  static double tintFor(GlassSurfaceType type, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (type) {
      GlassSurfaceType.chrome => isDark ? darkTintChrome : lightTintChrome,
      GlassSurfaceType.panel => isDark ? darkTintPanel : lightTintPanel,
      GlassSurfaceType.modal => isDark ? darkTintModal : lightTintModal,
      GlassSurfaceType.floating =>
        isDark ? darkTintFloating : lightTintFloating,
      GlassSurfaceType.repeated =>
        isDark ? darkTintRepeated : lightTintRepeated,
      GlassSurfaceType.crystal =>
        isDark ? darkTintCrystal : lightTintCrystal,
    };
  }

  /// Mixes [ColorScheme.primary] into [base] for the given [type]/brightness
  /// — the brand-tinted fill every glass surface uses instead of a flat
  /// neutral tone. Callers still apply their own opacity afterwards.
  static Color tint(
    Color base,
    ColorScheme colorScheme,
    GlassSurfaceType type,
  ) {
    return Color.lerp(
      base,
      colorScheme.primary,
      tintFor(type, colorScheme.brightness),
    )!;
  }

  /// The subtle brand-tinted stroke shared by every glass surface's default
  /// border and by [glassInputDecoration] — one formula, so the two can't
  /// drift out of sync.
  static BorderSide borderSideFor(ColorScheme colorScheme) => BorderSide(
    color: Color.lerp(
      colorScheme.outlineVariant,
      colorScheme.primary,
      borderTintStrength,
    )!.withValues(alpha: borderOpacityFor(colorScheme.brightness)),
  );
}

/// A translucent surface that optionally blurs whatever sits behind it.
///
/// [type] drives the default blur/opacity/border via [GlassTokens] — pass
/// `color`/`opacity`/`blurSigma` only to override a specific surface's look,
/// not as the normal way to configure one. Prefer the named constructors
/// ([GlassSurface.chrome], [.panel], [.modal], [.floating], [.repeated],
/// [.crystal]) over the generic constructor so the role is obvious at the
/// call site.
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

  /// Command Palette, Context Menu, Popover, Color/Date Picker, Tooltip —
  /// the top of the glass hierarchy. Also paints the directional edge
  /// highlight described on [GlassSurfaceType.crystal]; pass
  /// `showBorder: false` to suppress both the hairline and the highlight.
  const GlassSurface.crystal({
    super.key,
    required this.child,
    this.shape = const RoundedRectangleBorder(),
    this.color,
    this.opacity,
    this.blurSigma,
    this.borderSide,
    this.showBorder = true,
    this.boxShadow,
  }) : type = GlassSurfaceType.crystal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final brightness = colorScheme.brightness;
    final baseColor = color ?? colorScheme.surfaceContainer;
    final brandTintedColor = GlassTokens.tint(baseColor, colorScheme, type);
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final baseOpacity = opacity ?? GlassTokens.opacityFor(type, brightness);
    final resolvedOpacity = highContrast
        ? GlassTokens.boostOpacityForHighContrast(baseOpacity)
        : baseOpacity;
    final resolvedBlur = (type == GlassSurfaceType.repeated)
        ? 0.0
        : (blurSigma ?? GlassTokens.blurFor(type));
    final resolvedBorderSide =
        borderSide ??
        (showBorder ? GlassTokens.borderSideFor(colorScheme) : BorderSide.none);
    final tintedShape = shape.copyWith(side: resolvedBorderSide);
    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        shape: tintedShape,
        color: brandTintedColor.withValues(alpha: resolvedOpacity),
        shadows: boxShadow,
      ),
      child: child,
    );
    final clipped = resolvedBlur <= 0
        ? ClipPath(clipper: ShapeBorderClipper(shape: shape), child: surface)
        : ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: resolvedBlur,
                sigmaY: resolvedBlur,
              ),
              child: surface,
            ),
          );
    if (type != GlassSurfaceType.crystal || !showBorder) {
      return clipped;
    }
    return CustomPaint(
      foregroundPainter: _CrystalEdgePainter(
        shape: shape,
        color: GlassTokens.edgeHighlightColorFor(brightness),
      ),
      child: clipped,
    );
  }
}

/// Paints [GlassSurfaceType.crystal]'s directional edge highlight: a 1px
/// stroke along the surface's own shape, brightest at the top-left corner
/// and fading to nothing by the bottom-right — light grazing a glass edge,
/// not a glowing outline. Kept as a foreground painter (rather than a
/// second [BorderSide]) because [OutlinedBorder]/[ShapeDecoration] can't
/// express a gradient stroke on their own.
class _CrystalEdgePainter extends CustomPainter {
  final OutlinedBorder shape;
  final Color color;

  const _CrystalEdgePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 0.7],
          ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrystalEdgePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
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
    fillColor:
        GlassTokens.tint(
          colorScheme.surfaceContainer,
          colorScheme,
          GlassSurfaceType.panel,
        ).withValues(
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
