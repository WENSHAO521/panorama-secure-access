import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_clash/common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Panorama Liquid Glass Material System.
///
/// The app shell paints one [AmbientBackground] behind everything; chrome
/// surfaces (top bar, nav rail/bar, dialogs, settings groups) then sit on
/// top of it as translucent [GlassSurface]s instead of opaque Material
/// colors, so the ambient field reads through the whole app.
///
/// A physical surface is more than a blurred, tinted rectangle: it's a
/// stack of optical layers —
///
///   background content → backdrop blur → environmental tint →
///   translucent material body → internal illumination → edge refraction →
///   directional rim light → specular highlight → (crystal-tier only)
///   micro-lensing → foreground content → ambient shadow
///
/// [GlassSurfaceType] classifies a physical surface by the role it plays
/// (not how it happens to look), and [GlassTokens] holds every calibrated
/// value — blur, opacity, tint, refraction, specular, edge, motion — per
/// role/brightness so no call site hardcodes a magic number. [GlassSurface]
/// composites those tokens into the actual layer stack; everything else in
/// this file (inputs, ambient background, chrome bars, selected-nav
/// treatment) is built from the same token set so the whole app reads as
/// one material.

/// The role a physical glass surface plays. Pick the one that matches what
/// the surface *is*, not how it happens to look — the tokens (and how many
/// optical layers get composited) follow from the role.
enum GlassSurfaceType {
  /// App-level structural chrome that's on screen exactly once at a time:
  /// AppBar, NavigationBar/NavigationRail, title bar. Low-to-medium liquid
  /// glass: light refraction, weak specular, quiet — it must never compete
  /// with content for attention.
  chrome,

  /// A non-modal content group sitting on the ambient background: a
  /// settings block, a low-count card group. Rows inside stay transparent
  /// — this is the one physical surface, not a stack of nested panels.
  panel,

  /// A modal surface that must read as clearly in front of — and must
  /// meaningfully obscure — whatever is behind it: Dialog, BottomSheet,
  /// side sheet. Highest structural density short of crystal: strong
  /// separation, thicker edge, soft ambient shadow, but the body stays
  /// readable.
  modal,

  /// A transient overlay that isn't modal but still floats above content.
  /// Currently unused at a call site — popup menus and toasts, its
  /// original occupants, were promoted to [crystal] (see that value's
  /// doc). Kept as a token, fully tokenized like every other tier, for a
  /// future surface that wants floating-tier treatment without reaching
  /// all the way to crystal.
  floating,

  /// A surface that repeats many times in one scroll view (proxy cards,
  /// settings text chips). Always blur = 0 and never gets the dynamic
  /// optical layers (illumination/specular/edge refraction/micro-lensing)
  /// — stacking dozens of [BackdropFilter]s or per-item gradients/painters
  /// is a real scroll-jank risk. A low, mostly-tint opacity plus a plain
  /// hairline border is enough to read as "the same glass material" at a
  /// fraction of the cost; hover/press/selected feedback comes from
  /// ordinary Material state layers, not from this file.
  repeated,

  /// The top of the glass hierarchy: Command Palette, Context Menu
  /// (`CommonPopupMenu`), Popover, Toast (`StatusManager`'s message
  /// surface), Color/Date Picker, Tooltip — surfaces that float highest
  /// and appear one at a time, never stacked or repeated. Highest
  /// blur/opacity/refraction of any role, the richest specular response,
  /// and the only tier that gets micro-lensing + a faint static surface
  /// texture. Reserve this for the handful of components that are
  /// genuinely the top layer; using it everywhere defeats the hierarchy it
  /// exists to express.
  crystal,
}

/// Calibrated glass values per [GlassSurfaceType] and [Brightness]. Read
/// through the `*For(type, brightness)` resolvers rather than the raw
/// fields when resolving a surface's look — [GlassSurface] and every
/// helper in this file do the same.
abstract final class GlassTokens {
  // ---------------------------------------------------------------------
  // Paperline surface tokens. The named GlassSurface APIs remain in place
  // because they are shared by sheets, popovers, cards, and settings, but
  // the active visual language is opaque paper with hairline rules instead
  // of translucent blur.
  // ---------------------------------------------------------------------
  static const double blurChrome = 0;
  static const double blurPanel = 0;
  static const double blurModal = 0;
  static const double blurFloating = 0;
  static const double blurRepeated = 0;
  static const double blurCrystal = 0;

  static const double lightChromeOpacity = 1;
  static const double darkChromeOpacity = 1;

  static const double lightPanelOpacity = 1;
  static const double darkPanelOpacity = 1;

  static const double lightModalOpacity = 1;
  static const double darkModalOpacity = 1;

  static const double lightFloatingOpacity = 1;
  static const double darkFloatingOpacity = 1;

  static const double lightRepeatedOpacity = 1;
  static const double darkRepeatedOpacity = 1;

  static const double lightCrystalOpacity = 1;
  static const double darkCrystalOpacity = 1;

  // How much of the theme's ColorScheme.primary is mixed into a glass
  // surface's base colour before opacity is applied. This is what makes the
  // frosted panels read as *this app's* glass rather than generic
  // grey-tinted blur — the hue always follows the active primary color
  // (default brand violet, a user-picked accent, or Material You dynamic
  // color), so it stays consistent with whatever the rest of the UI is
  // themed with. Kept low: enough to tint, not enough to fight the content
  // drawn on top of the surface for attention.
  static const double lightTintChrome = 0;
  static const double darkTintChrome = 0;

  static const double lightTintPanel = 0;
  static const double darkTintPanel = 0;

  static const double lightTintModal = 0;
  static const double darkTintModal = 0;

  static const double lightTintFloating = 0;
  static const double darkTintFloating = 0;

  // Kept lowest: this type repeats dozens of times in one scroll view
  // (proxy cards), so a strong tint would compound into a muddy wash.
  static const double lightTintRepeated = 0;
  static const double darkTintRepeated = 0;

  static const double lightTintCrystal = 0;
  static const double darkTintCrystal = 0;

  // How much of primary is mixed into the neutral outlineVariant border —
  // a faint brand-coloured edge instead of a plain grey hairline.
  static const double borderTintStrength = 0.30;

  static const double lightBorderOpacity = 0.85;
  static const double darkBorderOpacity = 0.65;

  static const double lightDividerOpacity = 0.90;
  static const double darkDividerOpacity = 0.70;

  /// Scrim behind a modal (BottomSheet/side sheet) barrier — kept low so
  /// the page behind stays recognizable instead of going grey/dark.
  static const double lightModalBarrierOpacity = 0.16;
  static const double darkModalBarrierOpacity = 0.28;

  static const double radiusSmall = 4;
  static const double radiusMedium = 6;
  static const double radiusLarge = 10;
  static const double radiusModal = 12;

  // Named scale for components that don't have a dedicated radius token
  // above. radiusButton is wired into the app-wide button theme
  // (application.dart) and the nav indicator shape below; radiusCard is
  // wired into CommonCard's default and SettingsBlock (widgets/card.dart);
  // radiusInput is wired into glassInputDecoration below.
  // Panel/Sidebar/CommandPalette are not yet consumed anywhere — reserved
  // for future call sites that want a distinct radius from radiusCard.
  static const double radiusButton = 6;
  static const double radiusInput = 6;
  static const double radiusCard = 8;
  static const double radiusPanel = 8;
  static const double radiusSidebar = 0;
  static const double radiusCommandPalette = 12;

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

  // ---------------------------------------------------------------------
  // Liquid Glass optical layer tokens — refraction, specular, edge, depth,
  // interaction, motion. Every value here is per-[GlassSurfaceType]
  // (and, where the concept is a colour/opacity rather than a pure
  // geometry ratio, per [Brightness] too) so [GlassSurface] never has to
  // guess. [GlassSurfaceType.repeated] intentionally has no entry in most
  // of these switches — it never gets the dynamic layers, see the enum
  // value's doc — and resolvers return 0 for it.
  // ---------------------------------------------------------------------

  /// How strongly the internal-illumination gradient (the soft top-down
  /// "light entering the material" wash painted inside the body, before
  /// content) reads. Distinct from [innerHighlightOpacityFor] below in
  /// that this scales the overall richness of the body's tint blend, not
  /// just the highlight layer's own alpha.
  static const double lightRefractionChrome = 0.10;
  static const double darkRefractionChrome = 0.14;
  static const double lightRefractionPanel = 0.14;
  static const double darkRefractionPanel = 0.18;
  static const double lightRefractionModal = 0.20;
  static const double darkRefractionModal = 0.24;
  static const double lightRefractionFloating = 0.16;
  static const double darkRefractionFloating = 0.20;
  static const double lightRefractionCrystal = 0.28;
  static const double darkRefractionCrystal = 0.32;

  static double refractionStrengthFor(GlassSurfaceType type, Brightness b) {
    final isDark = b == Brightness.dark;
    return switch (type) {
      GlassSurfaceType.chrome =>
        isDark ? darkRefractionChrome : lightRefractionChrome,
      GlassSurfaceType.panel =>
        isDark ? darkRefractionPanel : lightRefractionPanel,
      GlassSurfaceType.modal =>
        isDark ? darkRefractionModal : lightRefractionModal,
      GlassSurfaceType.floating =>
        isDark ? darkRefractionFloating : lightRefractionFloating,
      GlassSurfaceType.repeated => 0,
      GlassSurfaceType.crystal =>
        isDark ? darkRefractionCrystal : lightRefractionCrystal,
    };
  }

  /// The bright directional stroke along the surface's own edge — "light
  /// grazing a glass edge", painted top-left-heavy fading toward the
  /// bottom-right. Crystal's value (0.55/0.16) is unchanged from the
  /// original "Soft Crystal Glass" edge so that tier's already-tuned look
  /// doesn't regress; every other tier now gets a scaled-down version of
  /// the same treatment instead of a flat hairline.
  static const double lightEdgeRefractionChrome = 0.16;
  static const double darkEdgeRefractionChrome = 0.07;
  static const double lightEdgeRefractionPanel = 0.20;
  static const double darkEdgeRefractionPanel = 0.08;
  static const double lightEdgeRefractionModal = 0.34;
  static const double darkEdgeRefractionModal = 0.12;
  static const double lightEdgeRefractionFloating = 0.28;
  static const double darkEdgeRefractionFloating = 0.10;
  static const double lightEdgeRefractionCrystal = 0.55;
  static const double darkEdgeRefractionCrystal = 0.16;

  static double edgeRefractionStrengthFor(GlassSurfaceType type, Brightness b) {
    final isDark = b == Brightness.dark;
    return switch (type) {
      GlassSurfaceType.chrome =>
        isDark ? darkEdgeRefractionChrome : lightEdgeRefractionChrome,
      GlassSurfaceType.panel =>
        isDark ? darkEdgeRefractionPanel : lightEdgeRefractionPanel,
      GlassSurfaceType.modal =>
        isDark ? darkEdgeRefractionModal : lightEdgeRefractionModal,
      GlassSurfaceType.floating =>
        isDark ? darkEdgeRefractionFloating : lightEdgeRefractionFloating,
      GlassSurfaceType.repeated => 0,
      GlassSurfaceType.crystal =>
        isDark ? darkEdgeRefractionCrystal : lightEdgeRefractionCrystal,
    };
  }

  /// The dimmer counter-stroke on the opposite (bottom-right) edge —
  /// "optical thickness" needs a surface to look darker/denser on its far
  /// side, not just brighter on its near side, or it reads as a glow
  /// rather than a material with depth.
  static const double lightRimLightChrome = 0.10;
  static const double darkRimLightChrome = 0.16;
  static const double lightRimLightPanel = 0.12;
  static const double darkRimLightPanel = 0.18;
  static const double lightRimLightModal = 0.16;
  static const double darkRimLightModal = 0.22;
  static const double lightRimLightFloating = 0.14;
  static const double darkRimLightFloating = 0.20;
  static const double lightRimLightCrystal = 0.20;
  static const double darkRimLightCrystal = 0.26;

  static double rimLightOpacityFor(GlassSurfaceType type, Brightness b) {
    final isDark = b == Brightness.dark;
    return switch (type) {
      GlassSurfaceType.chrome =>
        isDark ? darkRimLightChrome : lightRimLightChrome,
      GlassSurfaceType.panel => isDark ? darkRimLightPanel : lightRimLightPanel,
      GlassSurfaceType.modal => isDark ? darkRimLightModal : lightRimLightModal,
      GlassSurfaceType.floating =>
        isDark ? darkRimLightFloating : lightRimLightFloating,
      GlassSurfaceType.repeated => 0,
      GlassSurfaceType.crystal =>
        isDark ? darkRimLightCrystal : lightRimLightCrystal,
    };
  }

  /// Broad, soft, low-opacity directional specular highlight. Kept far
  /// below anything that would read as a "glowing" surface — see
  /// [GlassSurfaceType.chrome]'s doc: this must never compete with content.
  static const double lightSpecularChrome = 0.05;
  static const double darkSpecularChrome = 0.06;
  static const double lightSpecularPanel = 0.06;
  static const double darkSpecularPanel = 0.07;
  static const double lightSpecularModal = 0.09;
  static const double darkSpecularModal = 0.10;
  static const double lightSpecularFloating = 0.08;
  static const double darkSpecularFloating = 0.09;
  static const double lightSpecularCrystal = 0.14;
  static const double darkSpecularCrystal = 0.16;

  static double specularOpacityFor(GlassSurfaceType type, Brightness b) {
    final isDark = b == Brightness.dark;
    return switch (type) {
      GlassSurfaceType.chrome =>
        isDark ? darkSpecularChrome : lightSpecularChrome,
      GlassSurfaceType.panel => isDark ? darkSpecularPanel : lightSpecularPanel,
      GlassSurfaceType.modal => isDark ? darkSpecularModal : lightSpecularModal,
      GlassSurfaceType.floating =>
        isDark ? darkSpecularFloating : lightSpecularFloating,
      GlassSurfaceType.repeated => 0,
      GlassSurfaceType.crystal =>
        isDark ? darkSpecularCrystal : lightSpecularCrystal,
    };
  }

  /// Radial-gradient radius of the specular highlight, as a fraction of
  /// the surface's own size — deliberately large/"broad" per tier rather
  /// than a tight spot, so it reads as ambient light response, not a
  /// highlight decal. Geometry only, so it doesn't need a light/dark
  /// split the way a colour/opacity token does.
  static double specularWidthFor(GlassSurfaceType type) => switch (type) {
    GlassSurfaceType.crystal => 1.05,
    GlassSurfaceType.modal => 1.15,
    GlassSurfaceType.floating => 1.1,
    _ => 1.2,
  };

  /// Gradient stop (0..1) where the specular highlight fades to nothing —
  /// lower means a more contained, defined highlight; higher means a
  /// slower, softer falloff.
  static double specularFalloffFor(GlassSurfaceType type) => switch (type) {
    GlassSurfaceType.crystal => 0.78,
    GlassSurfaceType.modal => 0.82,
    GlassSurfaceType.floating => 0.85,
    _ => 0.9,
  };

  /// The soft top-down "light entering the material" wash painted just
  /// inside the body, beneath content.
  static const double lightInnerHighlightChrome = 0.05;
  static const double darkInnerHighlightChrome = 0.05;
  static const double lightInnerHighlightPanel = 0.06;
  static const double darkInnerHighlightPanel = 0.06;
  static const double lightInnerHighlightModal = 0.08;
  static const double darkInnerHighlightModal = 0.08;
  static const double lightInnerHighlightFloating = 0.07;
  static const double darkInnerHighlightFloating = 0.07;
  static const double lightInnerHighlightCrystal = 0.10;
  static const double darkInnerHighlightCrystal = 0.11;

  static double innerHighlightOpacityFor(GlassSurfaceType type, Brightness b) {
    final isDark = b == Brightness.dark;
    return switch (type) {
      GlassSurfaceType.chrome =>
        isDark ? darkInnerHighlightChrome : lightInnerHighlightChrome,
      GlassSurfaceType.panel =>
        isDark ? darkInnerHighlightPanel : lightInnerHighlightPanel,
      GlassSurfaceType.modal =>
        isDark ? darkInnerHighlightModal : lightInnerHighlightModal,
      GlassSurfaceType.floating =>
        isDark ? darkInnerHighlightFloating : lightInnerHighlightFloating,
      GlassSurfaceType.repeated => 0,
      GlassSurfaceType.crystal =>
        isDark ? darkInnerHighlightCrystal : lightInnerHighlightCrystal,
    };
  }

  /// Extra secondary/tertiary bleed mixed into the base tint on top of the
  /// primary tint every surface already gets — "the environment's colour
  /// can enter the material", kept small so it reads as ambient response
  /// rather than a second brand colour.
  static double environmentTintStrengthFor(GlassSurfaceType type) =>
      switch (type) {
        GlassSurfaceType.chrome => 0.02,
        GlassSurfaceType.panel => 0.03,
        GlassSurfaceType.modal => 0.02,
        GlassSurfaceType.floating => 0.03,
        GlassSurfaceType.repeated => 0,
        GlassSurfaceType.crystal => 0.04,
      };

  /// Perceived material thickness (0..1) — feeds shadow strength and the
  /// specular/edge contrast multiplier. Chrome is nearly flush with the
  /// shell; crystal floats furthest above the content behind it.
  static double materialDepthFor(GlassSurfaceType type) => switch (type) {
    GlassSurfaceType.chrome => 0.25,
    GlassSurfaceType.panel => 0.35,
    GlassSurfaceType.modal => 0.70,
    GlassSurfaceType.floating => 0.55,
    GlassSurfaceType.repeated => 0.10,
    GlassSurfaceType.crystal => 0.85,
  };

  /// How far the specular focal point is allowed to drift toward the
  /// pointer on desktop hover, and how much brighter it's allowed to get
  /// — small on purpose. See [LiquidGlassPerformancePolicy] for when this
  /// is actually applied.
  static double interactionLightStrengthFor(GlassSurfaceType type) =>
      switch (type) {
        GlassSurfaceType.chrome => 0.15,
        GlassSurfaceType.panel => 0.20,
        GlassSurfaceType.modal => 0.18,
        GlassSurfaceType.floating => 0.20,
        GlassSurfaceType.repeated => 0,
        GlassSurfaceType.crystal => 0.30,
      };

  /// Uniform scale applied on press — material compression, not a bouncy
  /// button. Kept inside the 0.985–0.995 band the spec calls for
  /// regardless of tier, so nothing ever reads as a "jelly" press.
  static const double pressedScale = 0.99;

  /// Fractional shadow-blur/opacity lift on hover (desktop only) — a
  /// small increase in apparent elevation, not a scale change.
  static double hoverDepthFor(GlassSurfaceType type) => switch (type) {
    GlassSurfaceType.modal => 0.12,
    GlassSurfaceType.crystal => 0.16,
    GlassSurfaceType.floating => 0.10,
    _ => 0.08,
  };

  /// Very low-opacity static grain, crystal-tier only (see
  /// [GlassSurfaceType.crystal]'s doc) — a deterministic, non-animated
  /// [CustomPainter] so it costs one paint, not one per frame, and crystal
  /// surfaces never repeat the way [GlassSurfaceType.repeated] ones do.
  static const double lightSurfaceNoiseCrystal = 0.020;
  static const double darkSurfaceNoiseCrystal = 0.025;

  static double surfaceNoiseOpacityFor(GlassSurfaceType type, Brightness b) {
    if (type != GlassSurfaceType.crystal) return 0;
    return b == Brightness.dark
        ? darkSurfaceNoiseCrystal
        : lightSurfaceNoiseCrystal;
  }

  /// Motion — hover/press/transition durations per the spec's ranges
  /// (hover 140–180ms, press 100–160ms, small-surface transition
  /// 180–220ms, popover 180–240ms, modal 220–280ms) plus one shared
  /// curve. Physical and settled: no bounce/elastic overshoot anywhere in
  /// this file.
  static const Duration hoverDuration = Duration(milliseconds: 160);
  static const Duration pressDuration = Duration(milliseconds: 130);
  static const Duration panelMotionDuration = Duration(milliseconds: 200);
  static const Duration modalMotionDuration = Duration(milliseconds: 240);
  static const Curve materialTransitionCurve = Curves.easeOutCubic;

  static Duration animationDurationFor(GlassSurfaceType type) => switch (type) {
    GlassSurfaceType.modal => modalMotionDuration,
    GlassSurfaceType.crystal => const Duration(milliseconds: 220),
    GlassSurfaceType.floating => const Duration(milliseconds: 200),
    GlassSurfaceType.repeated => const Duration(milliseconds: 160),
    _ => panelMotionDuration,
  };

  // ---------------------------------------------------------------------
  // Border / divider / accessibility / shadow (unchanged surface, some
  // now expressed in terms of the tokens above).
  // ---------------------------------------------------------------------

  static Color edgeHighlightColorFor(Brightness brightness) =>
      Colors.white.withValues(
        alpha: brightness == Brightness.dark
            ? darkEdgeRefractionCrystal
            : lightEdgeRefractionCrystal,
      );

  // Selected-state fill for a nav item (sidebar rail destination, bottom
  // nav destination): a soft primary-tinted wash instead of a solid
  // ColorScheme.secondaryContainer pill, per the "don't mark active with a
  // large colour block" rule — inner highlight, not paint. Shared by
  // NavigationBar (mobile) and NavigationRail (desktop/laptop) so both
  // read as the same material. [LiquidGlassSelectedIcon] below layers a
  // small glass-within-glass treatment on top of this wash for the
  // selected icon itself.
  static const double lightNavIndicatorOpacity = 0.14;
  static const double darkNavIndicatorOpacity = 0.20;

  static Color navIndicatorColorFor(ColorScheme colorScheme) =>
      colorScheme.primary.withValues(
        alpha: colorScheme.brightness == Brightness.dark
            ? darkNavIndicatorOpacity
            : lightNavIndicatorOpacity,
      );

  static ShapeBorder get navIndicatorShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton));

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
      GlassSurfaceType.crystal => isDark ? darkTintCrystal : lightTintCrystal,
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

  /// Mixes a touch of secondary/tertiary on top of [tint]'s primary blend
  /// — [environmentTintStrengthFor]'s "the environment can bleed into the
  /// material" effect. Kept as a separate step so the primary brand tint
  /// (which every surface must carry) and the much smaller environmental
  /// bleed (which only some tiers carry, at very low strength) can't be
  /// conflated into one magic-number blend.
  static Color environmentTint(
    Color tinted,
    ColorScheme colorScheme,
    GlassSurfaceType type,
  ) {
    final strength = environmentTintStrengthFor(type);
    if (strength <= 0) return tinted;
    final environmentColor = Color.lerp(
      colorScheme.secondary,
      colorScheme.tertiary,
      0.5,
    )!;
    return Color.lerp(tinted, environmentColor, strength)!;
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

  // Ambient shadow. Deliberately not wired into [GlassSurface]'s default
  // rendering: chrome/panel/repeated surfaces are flush with the shell or
  // repeat dozens of times, and don't want a shadow at all. Callers pass
  // these explicitly via the `boxShadow` parameter. Built from
  // [materialDepthFor] so a tier's shadow strength tracks its declared
  // depth instead of being calibrated a second time by hand.
  static List<BoxShadow> _shadowFor(
    GlassSurfaceType type,
    Brightness brightness,
  ) {
    final depth = materialDepthFor(type);
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: (isDark ? 0.46 : 0.16) * depth),
        blurRadius: 40 + 40 * depth,
        offset: Offset(0, 14 + 12 * depth),
      ),
    ];
  }

  static List<BoxShadow> modalShadowFor(Brightness brightness) =>
      _shadowFor(GlassSurfaceType.modal, brightness);

  static List<BoxShadow> crystalShadowFor(Brightness brightness) =>
      _shadowFor(GlassSurfaceType.crystal, brightness);

  static List<BoxShadow> floatingShadowFor(Brightness brightness) =>
      _shadowFor(GlassSurfaceType.floating, brightness);

  // "If the background is complex, automatically raise glass opacity" —
  // MediaQuery.highContrast (Increase Contrast on iOS/macOS, equivalent
  // accessibility settings elsewhere) means whatever is behind a glass
  // surface can't be trusted to give the content on top of it enough
  // contrast, so every [GlassSurface] pulls its opacity most of the way to
  // fully opaque rather than trying to individually verify contrast against
  // an arbitrary, possibly-busy background. The same accessibility signal
  // also dims/removes the specular and micro-lensing layers — see
  // [LiquidGlassPerformancePolicy] — trading optical richness for the
  // foreground/background separation high-contrast mode is asking for.
  static double boostOpacityForHighContrast(double opacity) =>
      (opacity + (1 - opacity) * 0.6).clamp(0.0, 1.0);
}

/// Marks "a real, blurred glass surface already sits above this point in
/// the tree" — Apple's Liquid Glass HIG is explicit that two translucent
/// panes must never stack (a popover opened from inside a modal sheet,
/// say): the top one would sample an already-blurred backdrop and blur it
/// a second time, softening it past the point either surface was actually
/// tuned for. [GlassSurface] and [LiquidGlassChrome] both check this on
/// build and fall back to a flat tint instead of their own [BackdropFilter]
/// when it reports true, then re-publish `blurred: true` for whatever they
/// render underneath — so the flattening holds no matter how deep the
/// nesting goes, without every call site having to know its own ancestry.
class _GlassDepthScope extends InheritedWidget {
  const _GlassDepthScope({required this.blurred, required super.child});

  final bool blurred;

  static bool hasBlurredAncestor(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_GlassDepthScope>();
    return (element?.widget as _GlassDepthScope?)?.blurred ?? false;
  }

  @override
  bool updateShouldNotify(_GlassDepthScope oldWidget) =>
      blurred != oldWidget.blurred;
}

/// Centralises the "should this surface actually run its dynamic/expensive
/// optical layers right now" decision, so [GlassSurface] and every other
/// widget in this file ask one place instead of re-deriving the same
/// three checks. Kept intentionally conservative — performance is a
/// release gate for this app, not a nice-to-have (a proxy/provider/log
/// list can hold hundreds of rows on a low-end phone).
abstract final class LiquidGlassPerformancePolicy {
  /// Paperline surfaces rely on typography, spacing, and rules for hierarchy.
  /// Keep the optical layers disabled so legacy GlassSurface call sites do
  /// not reintroduce gradients or decorative highlights into the new shell.
  static bool allowOpticalLayers(GlassSurfaceType type) => false;

  /// Specular highlight + (crystal-only) micro-lensing/noise: skipped
  /// entirely under high contrast (item 31 — "减少复杂 refraction"), since
  /// unlike illumination/edge they're a legibility-neutral decorative
  /// layer, not something that helps foreground/background separation.
  static bool allowSpecular(BuildContext context, GlassSurfaceType type) {
    if (!allowOpticalLayers(type)) return false;
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    return !highContrast;
  }

  /// Pointer-tracked specular movement (desktop hover): a static specular
  /// still renders under reduced motion, this only gates the *animation*.
  /// [MouseRegion] itself is inert on touch-only platforms, so this
  /// doesn't need a separate desktop/mobile branch — mobile simply never
  /// receives hover events.
  static bool allowInteractiveSpecular(
    BuildContext context,
    GlassSurfaceType type,
  ) {
    if (!allowSpecular(context, type)) return false;
    // Desktop only: touch platforms never emit hover, so the
    // MouseRegion/LayoutBuilder/ValueListenableBuilder tracking apparatus
    // this gates would only ever sit idle there — real widget/layout cost
    // for zero visual benefit, paid on every non-repeated glass surface
    // (every dialog, every settings panel, every popup) on every mobile
    // screen. A static specular (still rendered — see allowSpecular) costs
    // nothing extra to keep.
    if (!system.isDesktop) return false;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return !reducedMotion;
  }

  /// Micro-lensing and the static noise texture: crystal-tier only, see
  /// [GlassSurfaceType.crystal]'s doc.
  static bool allowMicroDetail(BuildContext context, GlassSurfaceType type) =>
      type == GlassSurfaceType.crystal && allowSpecular(context, type);
}

/// A translucent, layered-optical-material surface that optionally blurs
/// whatever sits behind it.
///
/// [type] drives every visual token via [GlassTokens] — pass
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
///
/// Every non-repeated surface composites, in order: the tinted/opacity body
/// → a soft top-down internal-illumination wash → a broad, low-opacity
/// specular highlight (pointer-responsive on desktop, static everywhere
/// else) → crystal-only micro-lensing + a faint static noise texture →
/// [child] → a directional edge-refraction stroke on top. See
/// [LiquidGlassPerformancePolicy] for exactly when each layer is skipped.
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
    final mediaQuery = MediaQuery.maybeOf(context);
    final highContrast = mediaQuery?.highContrast ?? false;
    final hasGlassAncestor = _GlassDepthScope.hasBlurredAncestor(context);
    // A blurred ancestor means this surface would otherwise be a second
    // BackdropFilter stacked on an already-blurred backdrop — see
    // _GlassDepthScope's doc. Treat it like the `repeated` tier's own
    // no-blur case rather than skip it silently.
    final forcedFlat = hasGlassAncestor && type != GlassSurfaceType.repeated;

    final baseColor = color ?? colorScheme.surfaceContainer;
    // refractionStrengthFor: a small, tier-scaled lift toward a neutral
    // highlight on top of the brand + environment tint — "light is passing
    // through this material", distinct from the inner-illumination/edge
    // layers below in that it shifts the body's own base colour rather
    // than painting an extra layer on top of it.
    final refraction = GlassTokens.refractionStrengthFor(type, brightness);
    final brandTintedColor = Color.lerp(
      GlassTokens.environmentTint(
        GlassTokens.tint(baseColor, colorScheme, type),
        colorScheme,
        type,
      ),
      brightness == Brightness.dark ? const Color(0xFFDCE6FF) : Colors.white,
      refraction * 0.15,
    )!;
    final baseOpacity = opacity ?? GlassTokens.opacityFor(type, brightness);
    // Reuses the high-contrast curve for the same reason it exists there:
    // pull opacity most of the way to opaque to compensate for the body
    // losing the legibility a real blur would have given it, whether
    // that's because the background is busy (high contrast) or because
    // blur itself got skipped to avoid double-blurring (forcedFlat).
    final resolvedOpacity = (highContrast || forcedFlat)
        ? GlassTokens.boostOpacityForHighContrast(baseOpacity)
        : baseOpacity;
    final resolvedBlur = (type == GlassSurfaceType.repeated || forcedFlat)
        ? 0.0
        : (blurSigma ?? GlassTokens.blurFor(type));
    final resolvedBorderSide =
        borderSide ??
        (showBorder ? GlassTokens.borderSideFor(colorScheme) : BorderSide.none);
    final tintedShape = shape.copyWith(side: resolvedBorderSide);

    final allowOptical = LiquidGlassPerformancePolicy.allowOpticalLayers(type);
    final allowSpecular = LiquidGlassPerformancePolicy.allowSpecular(
      context,
      type,
    );
    final allowInteractive =
        LiquidGlassPerformancePolicy.allowInteractiveSpecular(context, type);
    final allowMicroDetail = LiquidGlassPerformancePolicy.allowMicroDetail(
      context,
      type,
    );
    // High contrast keeps illumination/edge (they help legibility) but
    // dampens their intensity rather than removing them outright — see
    // GlassTokens.boostOpacityForHighContrast's doc for the same principle
    // applied to body opacity.
    final opticalIntensity = highContrast ? 0.5 : 1.0;

    // Builds the whole composited surface for a given pointer source.
    // [pointer] is only non-null when a _LiquidPointerTracker wraps the
    // result (see below) — passing it through a closure rather than
    // reaching for ambient state keeps the specular layer's hover math a
    // pure function of "where is the pointer right now", regardless of
    // where in the tree that answer comes from.
    Widget composeSurface(ValueListenable<Offset?>? pointer) {
      final surfaceStack = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: tintedShape,
                color: brandTintedColor.withValues(alpha: resolvedOpacity),
                shadows: boxShadow,
              ),
            ),
          ),
          if (allowOptical)
            Positioned.fill(
              child: _LiquidInnerIllumination(
                type: type,
                brightness: brightness,
                intensity: opticalIntensity,
              ),
            ),
          if (allowSpecular)
            Positioned.fill(
              child: RepaintBoundary(
                child: _LiquidSpecularHighlight(
                  type: type,
                  brightness: brightness,
                  pointer: pointer,
                ),
              ),
            ),
          if (allowMicroDetail)
            Positioned.fill(child: _LiquidMicroLensing(brightness: brightness)),
          if (allowMicroDetail)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _LiquidNoisePainter(
                    opacity: GlassTokens.surfaceNoiseOpacityFor(
                      type,
                      brightness,
                    ),
                    color: brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
          child,
        ],
      );

      final clipped = resolvedBlur <= 0
          ? ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: surfaceStack,
            )
          : ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: resolvedBlur,
                  sigmaY: resolvedBlur,
                ),
                child: surfaceStack,
              ),
            );

      if (!showBorder || !allowOptical) {
        return clipped;
      }
      final edgeIntensity =
          GlassTokens.edgeRefractionStrengthFor(type, brightness) *
          opticalIntensity;
      if (edgeIntensity <= 0) {
        return clipped;
      }
      return CustomPaint(
        foregroundPainter: _LiquidEdgePainter(
          shape: shape,
          brightness: brightness,
          highlightIntensity: edgeIntensity,
          rimIntensity:
              GlassTokens.rimLightOpacityFor(type, brightness) *
              opticalIntensity,
          // Modal/floating/crystal are thick enough surfaces to show a
          // second, inset stroke (the actual "optical thickness" cue);
          // chrome/panel stay a single stroke so a settings block or the
          // nav rail doesn't pick up a busy double outline.
          richEdge:
              type == GlassSurfaceType.modal ||
              type == GlassSurfaceType.floating ||
              type == GlassSurfaceType.crystal,
        ),
        child: clipped,
      );
    }

    // The pointer tracker wraps the *entire* composed surface (content
    // included), not just the specular layer, and on purpose: Stack hit
    // testing stops at the first child that reports a hit (front to back),
    // so a MouseRegion sitting only behind interactive content — like the
    // card/button `child` usually painted on top — would rarely see hover
    // at all once the pointer is over anything clickable. Wrapping the
    // whole surface makes it an ancestor of that content instead, which
    // Flutter's hit-test path always includes once any descendant hits,
    // and updating a ValueNotifier from onHover (verified rather than
    // setState) means only the specular layer's own ValueListenableBuilder
    // — already isolated behind its own RepaintBoundary — repaints on
    // pointer move, not this wrapper or the content beside it.
    final composed = allowInteractive
        ? _LiquidPointerTracker(
            builder: (context, pointer) => composeSurface(pointer),
          )
        : composeSurface(null);
    // Re-publish for whatever this surface's own child tree builds below
    // it (see _GlassDepthScope) — true once either this surface or an
    // ancestor actually blurred, so a real GlassSurface/LiquidGlassChrome
    // nested arbitrarily deep inside this one's `child` still flattens.
    return _GlassDepthScope(
      blurred: hasGlassAncestor || resolvedBlur > 0,
      child: composed,
    );
  }
}

/// Soft top-down "light entering the material" wash painted just inside a
/// glass body, beneath content — part of every non-repeated surface's
/// internal-illumination layer. A single gradient, no painter, so it costs
/// nothing beyond one more composited layer.
class _LiquidInnerIllumination extends StatelessWidget {
  final GlassSurfaceType type;
  final Brightness brightness;
  final double intensity;

  const _LiquidInnerIllumination({
    required this.type,
    required this.brightness,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final opacity =
        GlassTokens.innerHighlightOpacityFor(type, brightness) * intensity;
    if (opacity <= 0) return const SizedBox.shrink();
    final highlightColor = brightness == Brightness.dark
        ? const Color(0xFFBFD4FF)
        : Colors.white;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              highlightColor.withValues(alpha: opacity),
              highlightColor.withValues(alpha: 0),
            ],
            stops: const [0, 0.55],
          ),
        ),
      ),
    );
  }
}

/// Tracks the pointer's local position over [child] and exposes it as a
/// [ValueListenable] rather than calling `setState` — [_LiquidSpecularHighlight]
/// listens directly via [ValueListenableBuilder], so a pointer move only
/// rebuilds that one, already-[RepaintBoundary]-isolated layer, never this
/// wrapper or the content beside it.
///
/// Wraps the *entire* composed glass surface (see [GlassSurface.build]'s
/// `composeSurface`), not just the specular layer, specifically because
/// [Stack] hit-testing stops at the first child that reports a hit, front
/// to back: a [MouseRegion] sitting only behind interactive content would
/// rarely see hover once the pointer is over anything clickable. As an
/// ancestor of that content instead, it's always included in the hit-test
/// path once any descendant hits, so hover tracking works across the whole
/// surface, not just the gaps between buttons.
class _LiquidPointerTracker extends StatefulWidget {
  final Widget Function(BuildContext context, ValueListenable<Offset?> pointer)
  builder;

  const _LiquidPointerTracker({required this.builder});

  @override
  State<_LiquidPointerTracker> createState() => _LiquidPointerTrackerState();
}

class _LiquidPointerTrackerState extends State<_LiquidPointerTracker> {
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (event) => _pointer.value = event.localPosition,
      onExit: (_) => _pointer.value = null,
      child: widget.builder(context, _pointer),
    );
  }
}

/// A broad, soft, low-opacity radial specular highlight, weighted toward
/// the top-left by default (the app's one virtual light source, per the
/// spec). When [pointer] is non-null (desktop, see
/// [LiquidGlassPerformancePolicy.allowInteractiveSpecular]), its focal
/// point drifts a small amount toward the pointer on hover and its
/// intensity ticks up slightly — "the material responds", not "a light
/// follows the cursor". [GlassTokens.interactionLightStrengthFor] caps how
/// far it's allowed to move. Implicitly animated via [AnimatedContainer]
/// (which lerps [RadialGradient.center] for free) rather than a custom
/// [AnimationController], so there's no ticker running while idle.
class _LiquidSpecularHighlight extends StatelessWidget {
  static const Alignment _restFocus = Alignment(-0.55, -0.85);

  final GlassSurfaceType type;
  final Brightness brightness;
  final ValueListenable<Offset?>? pointer;

  const _LiquidSpecularHighlight({
    required this.type,
    required this.brightness,
    required this.pointer,
  });

  Alignment _focusFor(Offset? local, Size size) {
    if (local == null || size.isEmpty) return _restFocus;
    final strength = GlassTokens.interactionLightStrengthFor(type);
    if (strength <= 0) return _restFocus;
    final dx = (local.dx / size.width) * 2 - 1;
    final dy = (local.dy / size.height) * 2 - 1;
    return Alignment(
      (_restFocus.x + (dx - _restFocus.x) * strength).clamp(-1.0, 1.0),
      (_restFocus.y + (dy - _restFocus.y) * strength).clamp(-1.0, 1.0),
    );
  }

  Widget _buildGradient(Alignment focus, double boost, double baseOpacity) {
    final highlightColor = brightness == Brightness.dark
        ? const Color(0xFFD8E6FF)
        : Colors.white;
    final falloff = GlassTokens.specularFalloffFor(type);
    final radius = GlassTokens.specularWidthFor(type);
    // A small, capped boost on hover — "responds", never "glows".
    final effectiveOpacity = (baseOpacity * (1 + boost * 0.6)).clamp(0.0, 1.0);
    return IgnorePointer(
      child: AnimatedContainer(
        duration: GlassTokens.hoverDuration,
        curve: GlassTokens.materialTransitionCurve,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: focus,
            radius: radius,
            colors: [
              highlightColor.withValues(alpha: effectiveOpacity),
              highlightColor.withValues(alpha: 0),
            ],
            stops: [0, falloff],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseOpacity = GlassTokens.specularOpacityFor(type, brightness);
    if (baseOpacity <= 0) return const SizedBox.shrink();
    if (pointer == null) {
      return _buildGradient(_restFocus, 0, baseOpacity);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return ValueListenableBuilder<Offset?>(
          valueListenable: pointer!,
          builder: (context, local, _) {
            final strength = local == null
                ? 0.0
                : GlassTokens.interactionLightStrengthFor(type);
            return _buildGradient(
              _focusFor(local, size),
              strength,
              baseOpacity,
            );
          },
        );
      },
    );
  }
}

/// Crystal-tier-only extra highlight near the material's optical "sweet
/// spot" — a faint, static, off-centre radial bloom on top of the main
/// specular layer, reading as a very subtle lens effect without ever
/// approaching content (text/icons paint above every layer in this file).
class _LiquidMicroLensing extends StatelessWidget {
  final Brightness brightness;

  const _LiquidMicroLensing({required this.brightness});

  @override
  Widget build(BuildContext context) {
    final color = brightness == Brightness.dark
        ? const Color(0xFFE3ECFF)
        : Colors.white;
    final opacity = brightness == Brightness.dark ? 0.05 : 0.07;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.15, -0.35),
            radius: 0.55,
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

/// A deterministic, non-animated sparse-dot texture — [shouldRepaint] only
/// flips when the theme-derived opacity/colour actually changes, so this
/// paints once per surface instance rather than every frame. Crystal-tier
/// only, and crystal surfaces never repeat the way
/// [GlassSurfaceType.repeated] ones do, so the one-time cost is
/// negligible.
class _LiquidNoisePainter extends CustomPainter {
  final double opacity;
  final Color color;

  const _LiquidNoisePainter({required this.opacity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    final random = math.Random(7);
    final paint = Paint()..color = color.withValues(alpha: opacity);
    final count = (size.width * size.height / 900).clamp(12, 90).toInt();
    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidNoisePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}

/// Paints a glass surface's directional edge as optical thickness rather
/// than a flat outline: a bright top-left rim (light grazing the near
/// edge), a dim bottom-right counter-rim (the far edge reads darker/denser
/// — without it the near rim looks like a glow, not a material), and for
/// [richEdge] tiers (modal/floating/crystal) a second, inset stroke that
/// reads as the material actually having depth. Kept as a foreground
/// painter (rather than a second [BorderSide]) because [OutlinedBorder]/
/// [ShapeDecoration] can't express a gradient stroke on their own.
///
/// Strictly forbidden by the spec regardless of intensity: a uniform
/// glowing white outline, a neon edge, or any rainbow/holographic stroke —
/// every colour here comes from [brightness] (white/near-white highlight,
/// black counter-rim), never a hardcoded saturated hue.
class _LiquidEdgePainter extends CustomPainter {
  final OutlinedBorder shape;
  final Brightness brightness;
  final double highlightIntensity;
  final double rimIntensity;
  final bool richEdge;

  const _LiquidEdgePainter({
    required this.shape,
    required this.brightness,
    required this.highlightIntensity,
    required this.rimIntensity,
    required this.richEdge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightIntensity <= 0 && rimIntensity <= 0) return;
    final rect = Offset.zero & size;
    final outerPath = shape.getOuterPath(rect);
    const highlightColor = Colors.white;
    final rimColor = brightness == Brightness.dark
        ? Colors.black
        : Colors.black.withValues(alpha: 0.7);

    if (rimIntensity > 0) {
      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            rimColor.withValues(alpha: rimIntensity),
            rimColor.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.65],
        ).createShader(rect);
      canvas.drawPath(outerPath, rimPaint);
    }

    if (highlightIntensity > 0) {
      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlightColor.withValues(alpha: highlightIntensity),
            highlightColor.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.7],
        ).createShader(rect);
      canvas.drawPath(outerPath, highlightPaint);
    }

    if (!richEdge || highlightIntensity <= 0) return;
    final innerRect = rect.deflate(2.5);
    if (innerRect.isEmpty || innerRect.width <= 0 || innerRect.height <= 0) {
      return;
    }
    final innerPath = shape.getOuterPath(innerRect);
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.center,
        colors: [
          highlightColor.withValues(alpha: highlightIntensity * 0.45),
          highlightColor.withValues(alpha: 0),
        ],
      ).createShader(innerRect);
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidEdgePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.brightness != brightness ||
      oldDelegate.highlightIntensity != highlightIntensity ||
      oldDelegate.rimIntensity != rimIntensity ||
      oldDelegate.richEdge != richEdge;
}

/// Which physical edge [LiquidGlassChrome] paints its directional rim
/// highlight along — the strip of window/nav chrome that borders content
/// (a top bar's bottom edge, a sidebar's right edge, a bottom nav's top
/// edge), not a shape outline the way [GlassSurface]'s edge painter is.
enum LiquidGlassChromeEdge { none, top, bottom, left, right }

/// The chrome-tier compositor used for full-bleed bars that don't have
/// their own rounded [OutlinedBorder] — the desktop window title bar, the
/// AppBar's flexibleSpace, the mobile bottom NavigationBar, the desktop
/// sidebar background. These used to each hand-roll their own
/// `BackdropFilter` + tinted `DecoratedBox`; this widget is the one place
/// that composition happens now, so every chrome bar in the app is
/// visually the same material (blur, tint, internal illumination, and a
/// directional rim along the edge that borders content) instead of four
/// slightly different copies of the same math.
///
/// Deliberately skips the specular/micro-lensing layers [GlassSurface]
/// uses for panel/modal/crystal tiers — a radial highlight in the middle
/// of a full-width nav bar would read as a stray light, not material
/// response, so chrome bars stay to illumination + edge only, matching
/// [GlassSurfaceType.chrome]'s "must not steal attention" brief.
class LiquidGlassChrome extends StatelessWidget {
  final Widget? child;
  final Color? color;
  final LiquidGlassChromeEdge edge;

  const LiquidGlassChrome({
    super.key,
    this.child,
    this.color,
    this.edge = LiquidGlassChromeEdge.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final borderColor = colorScheme.outlineVariant.withValues(
      alpha: GlassTokens.dividerOpacityFor(colorScheme.brightness),
    );
    final border = switch (edge) {
      LiquidGlassChromeEdge.top => Border(top: BorderSide(color: borderColor)),
      LiquidGlassChromeEdge.bottom => Border(
        bottom: BorderSide(color: borderColor),
      ),
      LiquidGlassChromeEdge.left => Border(
        left: BorderSide(color: borderColor),
      ),
      LiquidGlassChromeEdge.right => Border(
        right: BorderSide(color: borderColor),
      ),
      LiquidGlassChromeEdge.none => null,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        border: border,
      ),
      child: child,
    );
  }
}

/// A small "glass-within-glass" treatment for the selected item in a
/// [NavigationBar]/[NavigationRail]: a soft off-centre radial wash plus a
/// faint rim behind the icon, layered inside the existing primary-tinted
/// indicator wash ([GlassTokens.navIndicatorColorFor]) so the selected
/// destination reads as sitting inside another, denser layer of material
/// rather than being painted with a flat colour block. Pass as
/// `selectedIcon:` — Flutter swaps to it automatically for whichever
/// destination is currently selected, so no per-destination state
/// tracking is needed here.
class LiquidGlassSelectedIcon extends StatelessWidget {
  final Widget icon;

  const LiquidGlassSelectedIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    if (highContrast) return icon;
    final lift = Color.lerp(
      colorScheme.primary,
      Colors.white,
      isDark ? 0.12 : 0.35,
    )!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.6),
          colors: [
            lift.withValues(alpha: isDark ? 0.22 : 0.16),
            colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.30),
          width: 0.6,
        ),
      ),
      child: icon,
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
  final borderRadius = BorderRadius.circular(GlassTokens.radiusInput);
  final borderSide = GlassTokens.borderSideFor(colorScheme);
  // A touch of the same edge-refraction white blended into the focused
  // colour instead of a flat, bold primary outline — "soft rim", not "bold
  // blue outline" (spec item 24).
  final focusedColor = Color.lerp(
    colorScheme.primary,
    Colors.white,
    brightness == Brightness.dark ? 0.06 : 0.12,
  )!;
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
      borderSide: BorderSide(color: focusedColor, width: 1.2),
    ),
  );
}

/// The ambient optical field painted once behind the whole app shell (top
/// bar, sidebar, page content all sit above it, translucent). Derives from
/// the active [ColorScheme] so it follows both dynamic color and the
/// user's chosen primary color automatically.
///
/// This exists to feed the glass surfaces something to refract/tint from
/// — a flat paper-like backdrop gives the dashboard and navigation a quiet
/// surface, with hierarchy coming from typography and hairline dividers
/// instead of decorative gradients or floating colour fields.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.colorScheme.brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF171A18) : const Color(0xFFF8F7F3),
      child: const SizedBox.expand(),
    );
  }
}
