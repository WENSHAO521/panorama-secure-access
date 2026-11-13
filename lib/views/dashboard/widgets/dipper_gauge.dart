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

/// How much of a circle the arch spans, centered on twelve o'clock, in
/// degrees: a low arch, so it sits over the figure without reaching round it.
const _sweepDegrees = 116.0;

/// How far a star reaches at rest and at its brightest, as a share of the
/// arch's radius.
const _restReach = 0.05;
const _litReach = 0.085;

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
    const sweep = _sweepDegrees * math.pi / 180;
    const start = -math.pi / 2 - sweep / 2;
    final halfChord = math.sin(sweep / 2);
    final sagitta = 1 - math.cos(sweep / 2);
    // The largest circle whose arch, and the halo of its stars, fits the box.
    var radius = math.min(
      size.width / 2 / (halfChord + _litReach * 1.6),
      size.height / (sagitta + _litReach * 3.2),
    );
    radius = math.max(radius, 0);
    final margin = radius * _litReach * 1.6;
    // The arch stands in the middle of the box.
    final top = (size.height - radius * sagitta - margin * 2) / 2 + margin;
    final center = Offset(size.width / 2, top + radius);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final unit = radius;
    final stroke = unit * 0.02;
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
          ..strokeWidth = stroke * 1.4
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            center + Offset(-radius * halfChord, 0),
            center + Offset(radius * halfChord, 0),
            [palette.ringLight, palette.gold],
          ),
      );
    }
    Offset pointAt(double angle) =>
        center + Offset.fromDirection(angle, radius);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.18
      ..color = track.withValues(alpha: math.min(1, track.a * 2.5));
    // The trail reaches star i once it has gone i sixths of the way; each
    // star brightens over the step before it, and none lights at idle.
    final steps = (_starCount - 1).toDouble();
    final reached = level * steps;
    final awake = (level * 12).clamp(0.0, 1.0);
    final newestIndex = level > 0
        ? math.min(reached.ceil(), steps.toInt())
        : -1;
    for (var index = 0; index < _starCount; index++) {
      final at = pointAt(start + sweep * index / steps);
      final lit = (reached - index + 1).clamp(0.0, 1.0) * awake;
      final newest = index == newestIndex;
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
