import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'star_badge.dart';

/// The seven stars of the Northern Dipper round the pole star (紫微, the
/// emperor's star of Zi Wei Dou Shu): where each sits as seen looking up at
/// the pole, x to the right and y down, in shares of the orbit's radius with
/// the farthest, Merak's rim of the bowl, near one; and its magnitude. Laid
/// out from Alkaid (搖光) at the tip of the handle to Dubhe (天樞) at the lip
/// of the bowl, with the dipper standing over the pole.
const _dipper = [
  (Offset(0.46, -0.907), 1.86), // Alkaid 搖光
  (Offset(0.314, -0.819), 2.04), // Mizar 開陽
  (Offset(0.199, -0.828), 1.77), // Alioth 玉衡
  (Offset(0.055, -0.822), 3.31), // Megrez 天權
  (Offset(-0.024, -0.907), 2.44), // Phecda 天璣
  (Offset(-0.211, -0.814), 2.37), // Merak 天璇
  (Offset(-0.172, -0.685), 1.79), // Dubhe 天樞
];

/// Megrez, where the bowl starts, and Dubhe, which closes it.
const _bowlStart = 3;
const _bowlEnd = 6;

/// Where the dipper rests while the tunnel is down, as a turn from standing
/// over the pole, counterclockwise as the sky turns: to the left of the
/// button, where the card has the most room.
const _restTurn = -0.267 * 2 * math.pi;

/// How long the dipper takes to go once round the pole while running.
/// Two minutes: slow enough to read as the sky turning, quick enough to see.
const _orbitPeriod = Duration(seconds: 120);

/// How far the dipper sits from the pole, and the orbit it rides on, as a
/// share of the halo's radius.
const _orbitRadius = 0.78;

/// The middle of the dipper as laid out in [_dipper], and how much larger
/// than the sky would draw it the halo draws it round that middle, so it
/// reads at a glance beside the button.
const _dipperMiddle = Offset(0.088, -0.826);
const _dipperGrowth = 1.7;

/// How far a star reaches at rest and lit, as a share of the halo's radius,
/// for the brightest of the seven.
const _restReach = 0.035;
const _litReach = 0.05;

double _sizeOf(double magnitude) =>
    math.pow(10, -0.13 * (magnitude - 1.77)).toDouble();

/// Paints the halo round the start button: a round [field], a faint orbit,
/// and the Northern Dipper turned [turn] round the pole from where it rests,
/// its stars lit in gold as far as [lit].
void paintPoleStar(
  Canvas canvas,
  Offset center,
  double radius, {
  required Color field,
  required double lit,
  required double turn,
  required bool dark,
}) {
  final palette = dark ? StarPalette.dark : StarPalette.light;
  final track = dark ? const Color(0x33B9A4F0) : const Color(0x265B3FB8);
  canvas.drawCircle(center, radius, Paint()..color = field);
  final orbit = radius * _orbitRadius;
  canvas.drawCircle(
    center,
    orbit * _dipperMiddle.distance,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, radius * 0.006)
      ..color = Color.lerp(track, palette.line, lit * 0.3)!,
  );
  final angle = _restTurn + turn;
  final cos = math.cos(angle);
  final sin = math.sin(angle);
  Offset place(Offset at) {
    final grown = _dipperMiddle + (at - _dipperMiddle) * _dipperGrowth;
    return center +
        Offset(
              grown.dx * cos - grown.dy * sin,
              grown.dx * sin + grown.dy * cos,
            ) *
            orbit;
  }

  final points = [for (final star in _dipper) place(star.$1)];
  final lines = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    lines.lineTo(point.dx, point.dy);
  }
  lines.lineTo(points[_bowlStart].dx, points[_bowlStart].dy);
  canvas.drawPath(
    lines,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, radius * 0.008)
      ..strokeJoin = StrokeJoin.round
      ..color = Color.lerp(track, palette.line.withValues(alpha: 0.5), lit)!,
  );
  final rest = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.18
    ..color = track.withValues(alpha: math.min(1, track.a * 2.5));
  final heart = Paint()..color = const Color(0xFFFFFFFF);
  for (var index = 0; index < _dipper.length; index++) {
    final scale = _sizeOf(_dipper[index].$2);
    final reach =
        radius * scale * (_restReach + (_litReach - _restReach) * lit);
    canvas
      ..save()
      ..translate(points[index].dx, points[index].dy)
      ..scale(reach);
    if (lit == 0) {
      canvas
        ..drawPath(starPath, rest)
        ..restore();
      continue;
    }
    if (index == _bowlEnd || index == 2) {
      // Dubhe and Alioth, the brightest, glow.
      canvas.drawCircle(
        Offset.zero,
        1.6,
        Paint()
          ..color = palette.gold.withValues(alpha: 0.25 * lit)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
      );
    }
    canvas
      ..drawPath(
        starPath,
        Paint()..color = palette.gold.withValues(alpha: 0.35 + 0.65 * lit),
      )
      ..drawCircle(Offset.zero, 0.14, heart)
      ..restore();
  }
}

/// The halo behind the start button, the button standing for the pole star:
/// while running, the Northern Dipper lights up and goes round it with the
/// run time, once every [_orbitPeriod], as the sky turns; stopped, it goes
/// on round to rest and dims.
class PoleStarHalo extends StatefulWidget {
  const PoleStarHalo({
    super.key,
    required this.size,
    required this.runTime,
    required this.lit,
    required this.field,
    required this.dark,
  });

  final double size;

  /// How long the tunnel has run, in milliseconds, or null while it is down.
  final int? runTime;

  /// How lit the stars are, from 0 to 1, eased by the caller with the
  /// button's own morph.
  final double lit;
  final Color field;
  final bool dark;

  @override
  State<PoleStarHalo> createState() => _PoleStarHaloState();
}

class _PoleStarHaloState extends State<PoleStarHalo>
    with SingleTickerProviderStateMixin {
  /// How many turns round the pole the dipper has gone. The run time moves
  /// it on about once a second, and each move eases over that second, so it
  /// stands still between moves and never holds a frame running.
  late final AnimationController _orbit = AnimationController.unbounded(
    vsync: this,
  );
  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _follow();
  }

  @override
  void didUpdateWidget(PoleStarHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runTime != widget.runTime) {
      _follow();
    }
  }

  void _follow() {
    final runTime = widget.runTime;
    if (_still) {
      _orbit.value = 0;
      return;
    }
    if (runTime != null) {
      _orbit.animateTo(
        runTime / _orbitPeriod.inMilliseconds,
        duration: const Duration(seconds: 1),
      );
      return;
    }
    final turns = _orbit.value;
    if (turns == turns.roundToDouble()) {
      _orbit.value = 0;
      return;
    }
    // Go on round to rest rather than wind back.
    _orbit
        .animateTo(
          turns.ceilToDouble(),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
        )
        .whenCompleteOrCancel(() {
          if (mounted && widget.runTime == null) {
            _orbit.value = 0;
          }
        });
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _PoleStarPainter(
          orbit: _orbit,
          lit: widget.lit,
          field: widget.field,
          dark: widget.dark,
        ),
      ),
    );
  }
}

class _PoleStarPainter extends CustomPainter {
  _PoleStarPainter({
    required this.orbit,
    required this.lit,
    required this.field,
    required this.dark,
  }) : super(repaint: orbit);

  final Animation<double> orbit;
  final double lit;
  final Color field;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    paintPoleStar(
      canvas,
      size.center(Offset.zero),
      size.shortestSide / 2,
      field: field,
      lit: lit.clamp(0.0, 1.0),
      // Counterclockwise, as the sky turns round the north pole.
      turn: -orbit.value * 2 * math.pi,
      dark: dark,
    );
  }

  @override
  bool shouldRepaint(_PoleStarPainter oldDelegate) =>
      oldDelegate.orbit != orbit ||
      oldDelegate.lit != lit ||
      oldDelegate.field != field ||
      oldDelegate.dark != dark;
}
