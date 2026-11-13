import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:prism_ui/hct/hct.dart';
import 'package:prism_ui/prism_ui.dart';

import 'star_chart.dart';

/// The color styles the theme settings offer: prism's four, which leave the
/// page near gray, and the Taoist ones, which each lay one fixed paper and ink
/// under the picked accent.
///
/// The Taoist styles keep prism's tones for every level, so the steps in
/// `.agents/surfaces.md` hold, and only move the surfaces' hue and chroma.
enum AppColorStyle {
  vivid(ColorStyle.vivid),
  tinted(ColorStyle.tinted),
  soft(ColorStyle.soft),
  monochrome(ColorStyle.monochrome),

  /// 星官箋: 玄青 night sky, 宣紙 rice paper, gilt hairlines.
  xingGuan(ColorStyle.vivid, paper: _starChartPaper),

  /// 紫府: the violet of the 紫微垣 enclosure at dusk.
  ziFu(ColorStyle.vivid, paper: _ziFuPaper),

  /// 青綠: the azurite and malachite of a blue-green landscape scroll.
  qingLu(ColorStyle.vivid, paper: _qingLuPaper),

  /// 水墨: ink on paper; the accent is ground down like a wash.
  shuiMo(ColorStyle.vivid, paper: _shuiMoPaper, maxAccentChroma: 30);

  const AppColorStyle(this.base, {this.paper, this.maxAccentChroma});

  final ColorStyle base;
  final TaoistPaper? paper;
  final double? maxAccentChroma;

  bool get isTaoist => paper != null;

  static const classic = [vivid, tinted, soft, monochrome];

  static const taoist = [xingGuan, ziFu, qingLu, shuiMo];
}

/// The hue and chroma a Taoist style gives each surface in either mode.
class TaoistPaper {
  const TaoistPaper({
    required this.lightHue,
    required this.lightChroma,
    required this.darkHue,
    required this.darkChroma,
    required this.hairlineHue,
    required this.hairlineChroma,
  });

  final double lightHue;
  final double lightChroma;
  final double darkHue;
  final double darkChroma;

  /// `outlineVariant`, the hairline round cards and between rows.
  final double hairlineHue;
  final double hairlineChroma;
}

// 宣紙 #F2EDE2 by day, 玄青 #0F1118 by night, 泥金 hairlines.
const _starChartPaper = TaoistPaper(
  lightHue: 104,
  lightChroma: 5,
  darkHue: 273,
  darkChroma: 10,
  hairlineHue: 82,
  hairlineChroma: 16,
);

const _ziFuPaper = TaoistPaper(
  lightHue: 300,
  lightChroma: 6,
  darkHue: 292,
  darkChroma: 13,
  hairlineHue: 295,
  hairlineChroma: 12,
);

const _qingLuPaper = TaoistPaper(
  lightHue: 160,
  lightChroma: 6,
  darkHue: 195,
  darkChroma: 9,
  hairlineHue: 160,
  hairlineChroma: 10,
);

const _shuiMoPaper = TaoistPaper(
  lightHue: 75,
  lightChroma: 3,
  darkHue: 75,
  darkChroma: 1.5,
  hairlineHue: 75,
  hairlineChroma: 4,
);

ColorScheme appColorScheme({
  required Color seedColor,
  required Brightness brightness,
  AppColorStyle style = AppColorStyle.vivid,
}) {
  final maxChroma = style.maxAccentChroma;
  final seed = maxChroma == null ? seedColor : _capChroma(seedColor, maxChroma);
  final scheme = seededColorScheme(
    seedColor: seed,
    brightness: brightness,
    style: style.base,
  );
  final paper = style.paper;
  if (paper == null) {
    return scheme;
  }
  final onPaper = scheme._onPaper(paper);
  if (style != AppColorStyle.xingGuan) {
    return onPaper;
  }
  // 星官箋 is the hand-tuned palette of the star-chart look; a seed other than
  // its 泥金 only takes over the accent.
  final starChart = scheme.toStarChart();
  if (seedColor.toARGB32() == StarChartColors.goldInk.toARGB32()) {
    return starChart;
  }
  return starChart.copyWith(
    primary: onPaper.primary,
    onPrimary: onPaper.onPrimary,
    primaryContainer: onPaper.primaryContainer,
    onPrimaryContainer: onPaper.onPrimaryContainer,
    inversePrimary: onPaper.inversePrimary,
    surfaceTint: onPaper.surfaceTint,
  );
}

Color _capChroma(Color color, double maxChroma) {
  final hct = Hct.fromInt(color.toARGB32());
  if (hct.chroma <= maxChroma) {
    return color;
  }
  return Color(Hct.from(hct.hue, maxChroma, hct.tone).toInt());
}

// The night the Taoist styles share is deeper than prism's dark: 玄 is the
// black of a sky with stars on it, so the page sits at tone 5 and a card at 10,
// as the 星官箋 mockup the user approved does, and each level still steps 4-5
// tones from the one under it.
const _darkTones = (
  dim: 5.0,
  surface: 5.0,
  lowest: 3.0,
  low: 7.0,
  container: 10.0,
  high: 14.0,
  highest: 19.0,
  bright: 22.0,
);

// A star reads on 玄 only when it is light: the accent climbs to tone 72 in
// dark, where 泥金 becomes the 星官箋 gilt and 紫微 its violet, under dark text.
const _darkAccentTone = 72.0;

extension on ColorScheme {
  ColorScheme _onPaper(TaoistPaper paper) {
    final dark = brightness == Brightness.dark;
    final hue = dark ? paper.darkHue : paper.lightHue;
    final chroma = dark ? paper.darkChroma : paper.lightChroma;
    Color tone(Color color, {double? maxChroma, double? darkTone}) {
      final hct = Hct.fromInt(color.toARGB32());
      return Color(
        Hct.from(
          hue,
          min(chroma, maxChroma ?? chroma),
          (dark ? darkTone : null) ?? hct.tone,
        ).toInt(),
      );
    }

    final hairline = Hct.fromInt(outlineVariant.toARGB32());
    final accent = Hct.fromInt(primary.toARGB32());
    final darkAccent = dark && accent.tone < _darkAccentTone;
    final scheme = copyWith(
      surface: tone(surface, darkTone: _darkTones.surface),
      surfaceBright: tone(surfaceBright, darkTone: _darkTones.bright),
      surfaceDim: tone(surfaceDim, darkTone: _darkTones.dim),
      surfaceContainerLowest: tone(
        surfaceContainerLowest,
        darkTone: _darkTones.lowest,
      ),
      surfaceContainerLow: tone(surfaceContainerLow, darkTone: _darkTones.low),
      surfaceContainer: tone(surfaceContainer, darkTone: _darkTones.container),
      surfaceContainerHigh: tone(
        surfaceContainerHigh,
        darkTone: _darkTones.high,
      ),
      surfaceContainerHighest: tone(
        surfaceContainerHighest,
        darkTone: _darkTones.highest,
      ),
      onSurface: tone(onSurface, maxChroma: 4),
      onSurfaceVariant: tone(onSurfaceVariant, maxChroma: 6),
      outline: tone(outline, maxChroma: 6),
      outlineVariant: Color(
        Hct.from(
          paper.hairlineHue,
          paper.hairlineChroma,
          dark ? 24 : hairline.tone,
        ).toInt(),
      ),
      inverseSurface: tone(inverseSurface),
      onInverseSurface: tone(onInverseSurface),
    );
    if (!darkAccent) {
      return scheme;
    }
    final lifted = Color(
      Hct.from(accent.hue, accent.chroma, _darkAccentTone).toInt(),
    );
    return scheme.copyWith(
      primary: lifted,
      surfaceTint: lifted,
      onPrimary: Color(
        Hct.from(accent.hue, min(accent.chroma, 24), 12).toInt(),
      ),
    );
  }
}
