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

/// The seven stars of the Northern Dipper (北斗七星) strung along an arch.
const _starCount = 7;

/// Where the arch starts and ends, in degrees from three o'clock.
const _startAngle = -168.0;
const _endAngle = -12.0;

/// How many times wider than tall the arch may stand.
const _widest = 2.4;

/// How far a star reaches at rest and at its brightest, as a share of the
/// gauge's width.
const _restReach = 0.03;
const _litReach = 0.052;

/// An arch of the seven stars of the Northern Dipper over a speed: a faint
/// track, a violet-to-gold trail up to [level], and the stars it has passed
/// lit in gold, the newest with a halo. [level] eases to each new speed.
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
    // On a wide card the arch keeps its shape and stands in the middle.
    final width = math.min(size.width, size.height * _widest);
    final left = (size.width - width) / 2;
    // Stars and strokes keep to the height on a wide card, so they stay fine.
    final unit = math.min(width, size.height * 1.8);
    final margin = unit * _litReach;
    final rect = Rect.fromLTRB(
      left + margin,
      margin,
      left + width - margin,
      // The arch's ends sit on the bottom edge.
      size.height * 2 - margin,
    );
    double radians(double degrees) => degrees * math.pi / 180;
    final start = radians(_startAngle);
    final sweep = radians(_endAngle - _startAngle);
    final stroke = unit * 0.012;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track,
    );
    if (level > 0) {
      canvas.drawArc(
        rect,
        start,
        sweep * level,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.3
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(rect.centerLeft, rect.centerRight, [
            palette.ringLight,
            palette.gold,
          ]),
      );
    }
    Offset pointAt(double angle) =>
        rect.center +
        Offset(
          math.cos(angle) * rect.width / 2,
          math.sin(angle) * rect.height / 2,
        );
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.18
      ..color = track.withValues(alpha: math.min(1, track.a * 2.5));
    final reached = level * _starCount;
    for (var index = 0; index < _starCount; index++) {
      // Each star sits at the end of its share of the arch, so the last one
      // lights only once the gauge is full.
      final share = (index + 1) / _starCount;
      final at = pointAt(start + sweep * share);
      final lit = (reached - index).clamp(0.0, 1.0);
      final newest = lit > 0 && reached <= index + 1;
      final reach = unit * (_restReach + (_litReach - _restReach) * lit);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(reach);
      if (lit == 0) {
        canvas
          ..drawPath(starPath, outline)
          ..restore();
        continue;
      }
      if (newest) {
        canvas.drawCircle(
          Offset.zero,
          1.4,
          Paint()
            ..color = palette.gold.withValues(alpha: 0.3 * lit)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
        );
      }
      canvas
        ..drawPath(
          starPath,
          Paint()..color = palette.gold.withValues(alpha: 0.35 + 0.65 * lit),
        )
        ..drawCircle(Offset.zero, 0.14, _heart)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_DipperPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.palette != palette ||
      oldDelegate.track != track;
}
