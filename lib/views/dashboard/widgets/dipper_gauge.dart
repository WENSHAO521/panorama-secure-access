import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'star_badge.dart';

/// The speed at which the first star starts to light, and the one at which
/// all seven are lit, in bytes a second.
const _floorSpeed = 512.0;
const _ceilingSpeed = 64.0 * 1024 * 1024;

/// How full the gauge stands at [bytesPerSecond], from 0 to 1. Speeds span
/// many orders of magnitude, so the gauge climbs by doublings: each star
/// stands for a little over two of them.
double dipperLevel(num bytesPerSecond) {
  if (bytesPerSecond <= _floorSpeed) {
    return 0;
  }
  final doublings = math.log(bytesPerSecond / _floorSpeed) / math.ln2;
  final span = math.log(_ceilingSpeed / _floorSpeed) / math.ln2;
  return (doublings / span).clamp(0.0, 1.0);
}

/// The seven stars of the Northern Dipper (北斗七星) as they stand in the
/// northern sky, handle to the left and bowl to the right, in the order the
/// gauge lights them: from Alkaid (搖光) at the tip of the handle, along it
/// and round the bowl, to Dubhe (天樞) at its lip. Each is where it sits,
/// projected from its true position and scaled so the asterism is one unit
/// wide with y growing down, and how bright it is as its visual magnitude.
const _stars = [
  (Offset(0.0, 0.4803), 1.86), // Alkaid 搖光
  (Offset(0.2042, 0.2957), 2.04), // Mizar 開陽
  (Offset(0.3798, 0.2822), 1.77), // Alioth 玉衡
  (Offset(0.5938, 0.2478), 3.31), // Megrez 天權
  (Offset(0.7254, 0.3722), 2.44), // Phecda 天璣
  (Offset(1.0, 0.2062), 2.37), // Merak 天璇
  (Offset(0.9266, 0.0), 1.79), // Dubhe 天樞
];

/// How tall the asterism stands as a share of its width.
const _depth = 0.4803;

/// The bowl's fourth side, from Megrez back to Dubhe: drawn, but not on the
/// path the gauge climbs.
const _bowlStart = 3;
const _bowlEnd = 6;

/// Alcor (輔), the faint companion up and to the left of Mizar, set a little
/// further from it than it really is so it reads at a glance, and how far its
/// point of light reaches as a share of the asterism's width.
const _companionOf = 1;
const _companionOffset = Offset(-0.03, -0.055);
const _companionReach = 0.011;

/// How far a star reaches as a share of the asterism's width, at rest and at
/// its brightest, for the brightest star: fainter ones are smaller.
const _restReach = 0.038;
const _litReach = 0.06;

/// How much room a star's glow takes beyond its reach.
const _glowReach = 1.7;

/// How big a star of [magnitude] is next to the brightest of the seven. Each
/// magnitude is about two and a half times fainter; the size follows that
/// gently so the faintest, Megrez, is still plainly a star.
double _sizeOf(double magnitude) =>
    math.pow(10, -0.13 * (magnitude - 1.77)).toDouble();

/// The seven stars of the Northern Dipper over a speed: a faint outline of
/// the asterism, a violet-to-gold trail along it up to [level], and the stars
/// it has passed lit in gold, each as large as it is bright and the newest
/// with a halo. [level] eases to each new speed.
class DipperGauge extends StatelessWidget {
  const DipperGauge({super.key, required this.level, required this.dark});

  /// How full the gauge stands, from 0 to 1: see [dipperLevel].
  final double level;
  final bool dark;

  static const _ease = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: level),
      duration: _ease,
      curve: Curves.easeOutCubic,
      builder: (context, level, _) => CustomPaint(
        painter: _DipperPainter(
          level: level,
          palette: dark ? StarPalette.dark : StarPalette.light,
          track: dark ? const Color(0x33B9A4F0) : const Color(0x265B3FB8),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DipperPainter extends CustomPainter {
  _DipperPainter({
    required this.level,
    required this.palette,
    required this.track,
  });

  final double level;
  final StarPalette palette;
  final Color track;

  static final _heart = Paint()..color = const Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    // The widest asterism whose stars fit the box; their soft glow may
    // spill a little past it.
    const margin = _litReach;
    final width = math.max(
      0.0,
      math.min(
        size.width / (1 + margin * 2),
        size.height / (_depth + margin * 2),
      ),
    );
    if (width == 0) {
      return;
    }
    // The asterism stands in the middle of the box.
    final origin = Offset(
      (size.width - width) / 2,
      (size.height - width * _depth) / 2,
    );
    Offset place(Offset at) => origin + at * width;
    final points = [for (final star in _stars) place(star.$1)];
    final stroke = width * 0.009;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    final outline = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      outline.lineTo(point.dx, point.dy);
    }
    outline.lineTo(points[_bowlStart].dx, points[_bowlStart].dy);
    canvas.drawPath(outline, trackPaint);

    // The trail reaches star i once it has gone i sixths of the way; each
    // star brightens over the step before it, and none lights at idle.
    final steps = (_stars.length - 1).toDouble();
    final reached = level * steps;
    final awake = (level * 12).clamp(0.0, 1.0);
    double litOf(int index) => (reached - index + 1).clamp(0.0, 1.0) * awake;
    if (level > 0) {
      final trail = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(
          place(Offset.zero),
          place(const Offset(1, 0)),
          [palette.ringLight, palette.gold],
        );
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index++) {
        final share = (reached - index + 1).clamp(0.0, 1.0);
        if (share == 0) {
          break;
        }
        final to = Offset.lerp(points[index - 1], points[index], share)!;
        path.lineTo(to.dx, to.dy);
      }
      // The bowl closes once its lip, the last star, is lit.
      final closing = litOf(_bowlEnd);
      if (closing > 0) {
        final to = Offset.lerp(points[_bowlEnd], points[_bowlStart], closing)!;
        path
          ..moveTo(points[_bowlEnd].dx, points[_bowlEnd].dy)
          ..lineTo(to.dx, to.dy);
      }
      canvas.drawPath(path, trail);
    }

    final rest = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.18
      ..color = track.withValues(alpha: math.min(1, track.a * 2.5));
    final restHeart = Paint()
      ..color = track.withValues(alpha: math.min(1, track.a * 3));
    final newestIndex = level > 0
        ? math.min(reached.ceil(), steps.toInt())
        : -1;

    void drawStar(Offset at, double scale, double lit, {bool newest = false}) {
      final reach =
          width * scale * (_restReach + (_litReach - _restReach) * lit);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(reach);
      if (lit == 0) {
        canvas
          ..drawPath(starPath, rest)
          ..drawCircle(Offset.zero, 0.16, restHeart)
          ..restore();
        return;
      }
      canvas.drawCircle(
        Offset.zero,
        newest ? _glowReach : _glowReach * 0.7,
        Paint()
          ..color = palette.gold.withValues(
            alpha: (newest ? 0.32 : 0.14 * scale) * lit,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
      );
      canvas
        ..drawPath(
          starPath,
          Paint()..color = palette.gold.withValues(alpha: 0.35 + 0.65 * lit),
        )
        ..drawCircle(Offset.zero, 0.14, _heart)
        ..restore();
    }

    for (var index = 0; index < _stars.length; index++) {
      final lit = litOf(index);
      final scale = _sizeOf(_stars[index].$2);
      drawStar(points[index], scale, lit, newest: index == newestIndex);
      if (index == _companionOf) {
        canvas.drawCircle(
          place(_stars[index].$1 + _companionOffset),
          width * _companionReach * (0.8 + 0.2 * lit),
          lit == 0
              ? restHeart
              : (Paint()
                  ..color = palette.gold.withValues(alpha: 0.35 + 0.65 * lit)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DipperPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.palette != palette ||
      oldDelegate.track != track;
}
