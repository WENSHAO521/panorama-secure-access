import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/shapes/shapes.dart';

import 'card.dart';

/// The turn after which the halo and the blossom are back where they rest.
const sakuraSymmetry = 2 * math.pi;

/// The share of the badge the flag's disc spans.
const sakuraFlagExtent = 0.7;

const _haloLight = Color(0xFFFFD1E0);
const _haloMid = Color(0xFFF48FB1);
const _haloDeep = Color(0xFFEC6F9B);
const _blossomHeart = Color(0xFFF48FB1);
const _blossomMid = Color(0xFFFBC8D9);
const _blossomEdge = Color(0xFFFFF3F7);
const _blossomLine = Color(0x59F06F9A);
const _stamen = Color(0xFFE0507F);
const _anther = Color(0xFFF7C948);
const _fallen = Color(0xFFFBC8D9);
const _disc = Color(0xFFFFFFFF);
const _discEdgeLight = Color(0x14000000);
const _discEdgeDark = Color(0x33FFFFFF);

/// Where the halo runs, as a radius of the badge's unit square, and how wide.
const _haloRadius = 0.44;
const _haloWidth = 0.05;

/// One notched cherry petal growing up from the origin, one unit long.
final Path _petal = Path()
  ..moveTo(0, 0)
  ..cubicTo(-0.42, -0.18, -0.46, -0.78, -0.16, -0.98)
  ..quadraticBezierTo(-0.07, -1.02, 0, -0.86)
  ..quadraticBezierTo(0.08, -1.03, 0.18, -0.97)
  ..cubicTo(0.44, -0.72, 0.36, -0.16, 0, 0)
  ..close();

/// Five petals around the origin, one unit across from heart to tip.
final Path _blossom = () {
  final blossom = Path();
  for (var index = 0; index < 5; index++) {
    final turn = Matrix4.rotationZ(index * 2 * math.pi / 5)
      ..scaleByDouble(1.05, 1, 1, 1);
    blossom.addPath(_petal.transform(turn.storage), Offset.zero);
  }
  return blossom;
}();

/// [child] on a white disc inside a cherry-pink halo, with a blossom on the
/// halo's shoulder and a petal fallen at its foot.
///
/// When [flag] is set, [child] is a flag glyph filling the disc and clipped
/// to it; otherwise [child] sits bare in the halo. [rotation] stands for how
/// far a check has gone; the halo's shading and the blossom turn with it.
/// Hover and focus show on a circle behind the halo.
class SakuraBadge extends StatelessWidget {
  const SakuraBadge({
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

  /// Fills the circle behind the halo, as hover feedback.
  final Color? overlay;
  final double rotation;
  final BorderSide? ring;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final extent = size * sakuraFlagExtent;
    final child = this.child;
    return CustomPaint(
      painter: ShapePainter(
        path: shapePathOf(MaterialShapes.circle),
        color: overlay ?? const Color(0x00000000),
        ring: ring,
      ),
      child: CustomPaint(
        painter: _HaloPainter(rotation: rotation, flag: flag),
        foregroundPainter: _BlossomPainter(
          rotation: rotation,
          discEdge: flag ? (dark ? _discEdgeDark : _discEdgeLight) : null,
        ),
        child: SizedBox.square(
          dimension: size,
          child: child == null
              ? null
              : Center(
                  child: flag
                      ? ClipOval(
                          child: SizedBox.square(
                            dimension: extent,
                            child: OverflowBox(
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: child,
                            ),
                          ),
                        )
                      : child,
                ),
        ),
      ),
    );
  }
}

/// The halo, with the flag's disc inside it.
class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.rotation, required this.flag});

  final double rotation;
  final bool flag;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width;
    // Light from the top left to deep at the bottom right, turned on a check.
    final turned = Offset.fromDirection(math.pi / 4 + rotation, unit * 0.5);
    canvas.drawCircle(
      center,
      unit * _haloRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * _haloWidth
        ..shader = ui.Gradient.linear(
          center - turned,
          center + turned,
          const [_haloLight, _haloMid, _haloDeep],
          const [0, 0.5, 1],
        ),
    );
    if (flag) {
      canvas.drawCircle(
        center,
        unit * sakuraFlagExtent / 2,
        Paint()..color = _disc,
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.flag != flag;
}

/// The disc's edge, the blossom on the halo and the petal at its foot, all
/// over the flag.
class _BlossomPainter extends CustomPainter {
  _BlossomPainter({required this.rotation, required this.discEdge});

  final double rotation;
  final Color? discEdge;

  static final _line = Paint()
    ..style = PaintingStyle.stroke
    ..color = _blossomLine
    ..strokeWidth = 0.035
    ..strokeJoin = StrokeJoin.round;
  static final _stamenPaint = Paint()
    ..color = _stamen
    ..strokeWidth = 0.04
    ..strokeCap = StrokeCap.round;
  static final _antherPaint = Paint()..color = _anther;
  static final _heartPaint = Paint()..color = _stamen;
  static final _blossomFill = Paint()
    ..shader = ui.Gradient.radial(
      Offset.zero,
      1,
      const [_blossomHeart, _blossomMid, _blossomEdge],
      const [0, 0.45, 1],
    );
  static final _fallenFill = Paint()..color = _fallen;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width;
    if (discEdge case final edge?) {
      canvas.drawCircle(
        size.center(Offset.zero),
        unit * (sakuraFlagExtent / 2 - 0.01),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.02
          ..color = edge,
      );
    }

    canvas
      ..save()
      ..translate(unit * 0.15, unit * 0.86)
      ..rotate(-130 * math.pi / 180)
      ..scale(unit * 0.09, unit * 0.12)
      ..drawPath(_petal, _fallenFill)
      ..drawPath(_petal, _line)
      ..restore();

    canvas
      ..save()
      ..translate(unit * 0.82, unit * 0.2)
      ..rotate(-10 * math.pi / 180 - rotation)
      ..scale(unit * 0.15)
      ..drawPath(_blossom, _blossomFill)
      ..drawPath(_blossom, _line);
    for (var index = 0; index < 5; index++) {
      final angle = (index + 0.5) * 2 * math.pi / 5;
      final towards = Offset(math.sin(angle), -math.cos(angle));
      canvas
        ..drawLine(Offset.zero, towards * 0.32, _stamenPaint)
        ..drawCircle(towards * 0.34, 0.06, _antherPaint);
    }
    canvas
      ..drawCircle(Offset.zero, 0.1, _heartPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_BlossomPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.discEdge != discEdge;
}
