import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

/// The star-chart look (星官箋): ink-indigo night and rice paper, gilt (泥金)
/// for the accent, malachite (石綠) for health, cinnabar (朱砂) for errors.
abstract final class StarChartColors {
  static const gold = Color(0xFFD8B66C);
  static const goldBright = Color(0xFFF2DCA0);
  static const goldInk = Color(0xFF9C7420);
  static const violet = Color(0xFFB3A0EC);
  static const violetInk = Color(0xFF5B3FB8);

  static Color giltOf(Brightness brightness) =>
      brightness == Brightness.dark ? gold : goldInk;

  static Color hairlineOf(Brightness brightness) =>
      giltOf(brightness).withValues(alpha: 0.24);

  /// The frame of a selected box, which the gilt marks as chosen.
  static Color chosenHairlineOf(Brightness brightness) =>
      giltOf(brightness).withValues(alpha: 0.72);

  static Color starOf(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFFF3E6C0)
      : const Color(0xFF6B5A3A);

  /// Near, middle and far mountains, nearest last.
  static List<Color> mountainsOf(Brightness brightness) =>
      brightness == Brightness.dark
      ? const [Color(0xFF262A3A), Color(0xFF1D2030), Color(0xFF151824)]
      : const [Color(0xFFD6CFBF), Color(0xFFC2B9A6), Color(0xFFA89F8B)];
}

extension StarChartScheme on ColorScheme {
  ColorScheme toStarChart() => brightness == Brightness.dark
      ? copyWith(
          primary: StarChartColors.gold,
          onPrimary: const Color(0xFF2A2110),
          primaryContainer: const Color(0xFF4A3C1F),
          onPrimaryContainer: StarChartColors.goldBright,
          secondary: StarChartColors.violet,
          onSecondary: const Color(0xFF231A45),
          tertiary: const Color(0xFF7FB69A),
          onTertiary: const Color(0xFF0F2A1E),
          error: const Color(0xFFE07A62),
          onError: const Color(0xFF3A0E06),
          errorContainer: const Color(0xFF5A2218),
          onErrorContainer: const Color(0xFFFFD9CF),
          surface: const Color(0xFF0F1118),
          onSurface: const Color(0xFFEEE8DA),
          surfaceDim: const Color(0xFF0F1118),
          surfaceBright: const Color(0xFF2B2F3E),
          surfaceContainerLowest: const Color(0xFF0B0C12),
          surfaceContainerLow: const Color(0xFF13151E),
          surfaceContainer: const Color(0xFF181B26),
          surfaceContainerHigh: const Color(0xFF212534),
          surfaceContainerHighest: const Color(0xFF2A2E3D),
          onSurfaceVariant: const Color(0xFFA7A193),
          outline: const Color(0xFF746F63),
          outlineVariant: const Color(0xFF3A3B44),
          inverseSurface: const Color(0xFFEEE8DA),
          onInverseSurface: const Color(0xFF181B26),
          inversePrimary: StarChartColors.goldInk,
          surfaceTint: StarChartColors.gold,
        )
      : copyWith(
          primary: StarChartColors.goldInk,
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFFF0E2BE),
          onPrimaryContainer: const Color(0xFF4A3608),
          secondary: StarChartColors.violetInk,
          onSecondary: const Color(0xFFFFFFFF),
          tertiary: const Color(0xFF3D7A5D),
          onTertiary: const Color(0xFFFFFFFF),
          error: const Color(0xFFB2402C),
          onError: const Color(0xFFFFFFFF),
          errorContainer: const Color(0xFFF8DCD3),
          onErrorContainer: const Color(0xFF5A1A0E),
          surface: const Color(0xFFF6F1E6),
          onSurface: const Color(0xFF24201A),
          surfaceDim: const Color(0xFFE1D9C8),
          surfaceBright: const Color(0xFFFBF8F1),
          surfaceContainerLowest: const Color(0xFFFFFDF8),
          surfaceContainerLow: const Color(0xFFF4EFE4),
          surfaceContainer: const Color(0xFFEFE9DC),
          surfaceContainerHigh: const Color(0xFFE8E1D2),
          surfaceContainerHighest: const Color(0xFFE1D9C8),
          onSurfaceVariant: const Color(0xFF6F6656),
          outline: const Color(0xFF8F8574),
          outlineVariant: const Color(0xFFD6CDBB),
          inverseSurface: const Color(0xFF2A251D),
          onInverseSurface: const Color(0xFFF6F1E6),
          inversePrimary: StarChartColors.gold,
          surfaceTint: StarChartColors.goldInk,
        );
}

/// Serif faces, Traditional Chinese first, for titles under the star-chart
/// look. None is bundled: each platform ships one of these.
const starChartSerifFamilies = [
  'Noto Serif CJK TC',
  'Noto Serif TC',
  'Source Han Serif TC',
  'Songti TC',
  'STSong',
  'PMingLiU',
  'MingLiU',
  'Noto Serif CJK SC',
  'Noto Serif',
  'serif',
];

enum StarChartAspect { enabled, lit }

class StarChartScope extends InheritedModel<StarChartAspect> {
  const StarChartScope({
    super.key,
    required this.enabled,
    this.lit = false,
    required super.child,
  });

  final bool enabled;

  /// Whether the core is running, which brightens the backdrop.
  final bool lit;

  static bool of(BuildContext context) =>
      InheritedModel.inheritFrom<StarChartScope>(
        context,
        aspect: StarChartAspect.enabled,
      )?.enabled ??
      false;

  static bool litOf(BuildContext context) =>
      InheritedModel.inheritFrom<StarChartScope>(
        context,
        aspect: StarChartAspect.lit,
      )?.lit ??
      false;

  static TextStyle titleOf(BuildContext context, TextStyle style) => of(context)
      ? style.copyWith(
          fontFamily: starChartSerifFamilies.first,
          fontFamilyFallback: [
            ...starChartSerifFamilies.skip(1),
            ...?style.fontFamilyFallback,
          ],
          letterSpacing: (style.fontSize ?? 14) * 0.06,
        )
      : style;

  @override
  bool updateShouldNotify(StarChartScope oldWidget) =>
      oldWidget.enabled != enabled || oldWidget.lit != lit;

  @override
  bool updateShouldNotifyDependent(
    StarChartScope oldWidget,
    Set<StarChartAspect> dependencies,
  ) =>
      (dependencies.contains(StarChartAspect.enabled) &&
          oldWidget.enabled != enabled) ||
      (dependencies.contains(StarChartAspect.lit) && oldWidget.lit != lit);
}

/// The star-chart frame (文武邊): a firm line at the edge and a fine one
/// inside it. An open side leaves its edge undrawn, so two boxes stacked on
/// it read as one frame.
class StarFrameDecoration extends Decoration {
  const StarFrameDecoration({
    required this.radius,
    required this.color,
    this.openTop = false,
    this.openBottom = false,
    this.inner = true,
  });

  static const inset = 4.0;

  final BorderRadius radius;
  final Color color;
  final bool openTop;
  final bool openBottom;

  /// Whether the fine inner line is drawn; a box too small to hold two lines
  /// keeps the edge only.
  final bool inner;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _StarFramePainter(this);

  @override
  bool operator ==(Object other) =>
      other is StarFrameDecoration &&
      other.radius == radius &&
      other.color == color &&
      other.openTop == openTop &&
      other.openBottom == openBottom &&
      other.inner == inner;

  @override
  int get hashCode => Object.hash(radius, color, openTop, openBottom, inner);
}

class _StarFramePainter extends BoxPainter {
  _StarFramePainter(this.decoration);

  final StarFrameDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) {
      return;
    }
    const inset = StarFrameDecoration.inset;
    final decoration = this.decoration;
    final rect = offset & size;
    final radius = decoration.radius;
    final open = decoration.openTop || decoration.openBottom;
    final overhang = open ? radius.topLeft.y + radius.bottomLeft.y + 8 : 0.0;
    final path = Rect.fromLTRB(
      rect.left,
      rect.top - (decoration.openTop ? overhang : 0),
      rect.right,
      rect.bottom + (decoration.openBottom ? overhang : 0),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = decoration.color;
    if (open) {
      canvas
        ..save()
        ..clipRect(rect);
    }
    canvas.drawPath(
      AppShape.of(radius).getOuterPath(path.deflate(0.6)),
      paint..strokeWidth = 1.2,
    );
    if (decoration.inner) {
      final inner = BorderRadius.only(
        topLeft: _shrink(radius.topLeft),
        topRight: _shrink(radius.topRight),
        bottomLeft: _shrink(radius.bottomLeft),
        bottomRight: _shrink(radius.bottomRight),
      );
      canvas.drawPath(
        AppShape.of(inner).getOuterPath(path.deflate(inset)),
        paint
          ..strokeWidth = 0.7
          ..color = decoration.color.withValues(
            alpha: decoration.color.a * 0.7,
          ),
      );
    }
    if (open) {
      canvas.restore();
    }
  }

  static Radius _shrink(Radius radius) => Radius.elliptical(
    math.max(radius.x - StarFrameDecoration.inset, 0),
    math.max(radius.y - StarFrameDecoration.inset, 0),
  );
}
