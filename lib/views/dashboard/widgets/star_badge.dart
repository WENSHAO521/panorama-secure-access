import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/shapes/shapes.dart';

import 'card.dart';

/// The turn after which the seven stars are all back at rest.
const starSymmetry = 2 * math.pi;

/// The share of the badge the round flag spans.
const starFlagExtent = 0.72;

/// Where the violet ring runs, as a radius of the badge's unit square, and
/// how wide.
const _ringRadius = 0.42;
const _ringWidth = 0.02;

/// The seven stars of the Northern Dipper (北斗七星), from Dubhe (天樞) at
/// the lip of the bowl to Alkaid (搖光) at the end of the handle: where each
/// sits as an angle round the ring in degrees from three o'clock, how far out
/// as a radius of the badge, and how far it reaches as a share of the badge.
const _dipper = [
  (-140.0, 0.425, 0.075),
  (-117.0, 0.465, 0.052),
  (-95.0, 0.42, 0.052),
  (-72.0, 0.44, 0.075),
  (-48.0, 0.41, 0.052),
  (-22.0, 0.45, 0.052),
  (2.0, 0.425, 0.052),
];

/// How far a star grows while it lights up during a check.
const _lightGrowth = 0.7;

/// The colors of one brightness, shared by every star motif on the dashboard.
class StarPalette {
  const StarPalette({
    required this.ringDeep,
    required this.ringLight,
    required this.gold,
    required this.line,
    required this.field,
    required this.shadow,
    required this.rim,
  });

  final Color ringDeep;
  final Color ringLight;
  final Color gold;
  final Color line;

  /// Fills the ring when there is no flag.
  final Color field;

  /// Falls under the flag's disc.
  final Color shadow;

  /// Edges the flag's disc.
  final Color rim;

  static const light = StarPalette(
    ringDeep: Color(0xFF2E1F6B),
    ringLight: Color(0xFF5B3FB8),
    gold: Color(0xFFB8902F),
    line: Color(0xCCB8902F),
    field: Color(0x0F5B3FB8),
    shadow: Color(0x402E1F6B),
    rim: Color(0x1F000000),
  );

  static const dark = StarPalette(
    ringDeep: Color(0xFFB9A4F0),
    ringLight: Color(0xFF8A6BE0),
    gold: Color(0xFFE8C97A),
    line: Color(0xCCE8C97A),
    field: Color(0x1FB9A4F0),
    shadow: Color(0x99000000),
    rim: Color(0x33FFFFFF),
  );
}

/// A four-pointed star with concave sides, reaching one unit from its heart.
final Path starPath = Path()
  ..moveTo(0, -1)
  ..quadraticBezierTo(0.16, -0.16, 1, 0)
  ..quadraticBezierTo(0.16, 0.16, 0, 1)
  ..quadraticBezierTo(-0.16, 0.16, -1, 0)
  ..quadraticBezierTo(-0.16, -0.16, 0, -1)
  ..close();

/// How lit star [index] is, from 0 at rest to 1 at its brightest, when a
/// check has gone [rotation] round: the stars light up one after another
/// through each turn and are all at rest at its start and end.
double _lit(int index, double rotation) {
  final turn = rotation / starSymmetry;
  final phase = turn - turn.floorToDouble();
  final step = 1 / (_dipper.length + 1);
  final offset = phase - (index + 1) * step;
  if (offset.abs() >= step) {
    return 0;
  }
  return (1 + math.cos(offset / step * math.pi)) / 2;
}

/// [child] on a white disc inside a violet ring, with the seven gold stars of
/// the Northern Dipper strung along the ring's upper arc.
///
/// When [flag] is set, [child] is a round flag, laid out for a circle so the
/// whole of it shows; it is clipped to a disc that sits raised inside the
/// ring with a soft shadow and a gloss. Otherwise [child] sits bare on a
/// faint violet field. [rotation] stands for how
/// far a check has gone; the stars light up one after another with it. Hover and
/// focus show on a circle behind the ring.
class StarBadge extends StatelessWidget {
  const StarBadge({
    super.key,
    required this.size,
    required this.dark,
    this.flag = false,
    this.overlay,
    this.rotation = 0,
    this.ring,
    this.child,
  });

  final double size;
  final bool dark;
  final bool flag;

  /// Fills the circle behind the ring, as hover feedback.
  final Color? overlay;
  final double rotation;
  final BorderSide? ring;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = dark ? StarPalette.dark : StarPalette.light;
    final child = this.child;
    return CustomPaint(
      painter: ShapePainter(
        path: shapePathOf(MaterialShapes.circle),
        color: overlay ?? const Color(0x00000000),
        ring: ring,
      ),
      child: CustomPaint(
        painter: _RingPainter(palette: palette, flag: flag),
        foregroundPainter: _StarPainter(
          palette: palette,
          rotation: rotation,
          flag: flag,
        ),
        child: SizedBox.square(
          dimension: size,
          child: child == null
              ? null
              : Center(
                  child: flag
                      ? ClipOval(
                          child: SizedBox.square(
                            dimension: size * starFlagExtent,
                            child: child,
                          ),
                        )
                      : child,
                ),
        ),
      ),
    );
  }
}

/// The ring, with the flag's shadow or the bare field inside it.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.palette, required this.flag});

  final StarPalette palette;
  final bool flag;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width;
    canvas.drawCircle(
      center,
      unit * _ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * _ringWidth
        // Light at the top left to deep at the bottom right.
        ..shader = ui.Gradient.linear(
          center - Offset(unit, unit) * 0.35,
          center + Offset(unit, unit) * 0.35,
          [palette.ringLight, palette.ringDeep],
        ),
    );
    if (flag) {
      // The flag's disc stands a little off the page.
      canvas.drawCircle(
        center + Offset(0, unit * 0.02),
        unit * starFlagExtent / 2,
        Paint()
          ..color = palette.shadow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.03),
      );
    } else {
      canvas.drawCircle(
        center,
        unit * (_ringRadius - _ringWidth / 2),
        Paint()..color = palette.field,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.flag != flag;
}

/// The flag's gloss and rim, then the seven stars and the line through them.
class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.palette,
    required this.rotation,
    required this.flag,
  });

  final StarPalette palette;
  final double rotation;
  final bool flag;

  static final _heart = Paint()..color = const Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width;
    if (flag) {
      final radius = unit * starFlagExtent / 2;
      // A soft light from the top left, and a fine rim to finish the edge.
      canvas
        ..drawCircle(
          center,
          radius,
          Paint()
            ..shader = ui.Gradient.radial(
              center - Offset(radius, radius) * 0.45,
              radius * 1.3,
              const [Color(0x47FFFFFF), Color(0x00FFFFFF)],
            ),
        )
        ..drawCircle(
          center,
          radius - unit * 0.004,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = unit * 0.008
            ..color = palette.rim,
        );
    }
    final points = [
      for (final (degrees, radius, _) in _dipper)
        center + Offset.fromDirection(degrees * math.pi / 180, unit * radius),
    ];
    canvas.drawPoints(
      ui.PointMode.polygon,
      points,
      Paint()
        ..strokeWidth = unit * 0.01
        ..strokeJoin = StrokeJoin.round
        ..color = palette.line,
    );
    final gold = Paint()..color = palette.gold;
    for (var index = 0; index < _dipper.length; index++) {
      final lit = _lit(index, rotation);
      final reach = unit * _dipper[index].$3 * (1 + _lightGrowth * lit);
      final at = points[index];
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(reach);
      if (lit > 0) {
        canvas.drawCircle(
          Offset.zero,
          0.6,
          Paint()..color = palette.gold.withValues(alpha: 0.35 * lit),
        );
      }
      canvas
        ..drawPath(starPath, gold)
        ..drawCircle(Offset.zero, 0.14, _heart)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.rotation != rotation ||
      oldDelegate.flag != flag;
}
