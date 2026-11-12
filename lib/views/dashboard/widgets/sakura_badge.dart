import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/shapes/shapes.dart';

import 'card.dart';

/// The turn after which the petals are back where they rest.
const sakuraSymmetry = math.pi;

const _petalBase = Color(0xFFFFF4F7);
const _fallenBase = Color(0xFFFCD6E2);
const _shadow = Color(0x59000000);
const _petalTipLight = Color(0xFFF7A8C0);
const _petalTipDark = Color(0xFFF59AB8);
const _vein = Color(0x55FFFFFF);

/// One notched cherry petal growing up from the origin, one unit long.
final Path _petal = Path()
  ..moveTo(0, 0)
  ..cubicTo(-0.42, -0.18, -0.46, -0.78, -0.16, -0.98)
  ..quadraticBezierTo(-0.07, -1.02, 0, -0.86)
  ..quadraticBezierTo(0.08, -1.03, 0.18, -0.97)
  ..cubicTo(0.44, -0.72, 0.36, -0.16, 0, 0)
  ..close();

/// Where each petal rests in the badge's unit square, with its tilt, its
/// length, how far it is turned away (a narrower width), and whether it lies
/// on top of [SakuraBadge.child].
const _scattered = [
  (x: 0.06, y: 0.22, tilt: -0.7, length: 0.2, width: 0.85, over: false),
  (x: 0.9, y: 0.12, tilt: 1.0, length: 0.16, width: 0.6, over: false),
  (x: 0.98, y: 0.72, tilt: 2.2, length: 0.18, width: 0.9, over: false),
  (x: 0.1, y: 0.86, tilt: -2.5, length: 0.15, width: 0.7, over: false),
  (x: 0.56, y: 1.0, tilt: 2.9, length: 0.12, width: 0.65, over: false),
  (x: 0.42, y: 0.02, tilt: 0.4, length: 0.11, width: 0.8, over: false),
  (x: 0.24, y: 0.36, tilt: 2.2, length: 0.2, width: 0.8, over: true),
  (x: 0.78, y: 0.7, tilt: -0.9, length: 0.18, width: 0.7, over: true),
  (x: 0.62, y: 0.36, tilt: 2.7, length: 0.11, width: 0.6, over: true),
];

/// Cherry petals scattered around [child], a few fallen on it.
///
/// [rotation] stands for how far a check has gone; the petals drift and
/// tumble with it. Hover and focus show on a clover behind [child].
class SakuraBadge extends StatelessWidget {
  const SakuraBadge({
    super.key,
    required this.size,
    required this.dark,
    this.overlay,
    this.rotation = 0,
    this.ring,
    this.child,
  });

  final double size;
  final bool dark;

  /// Fills the clover, as hover feedback.
  final Color? overlay;
  final double rotation;
  final BorderSide? ring;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tip = dark ? _petalTipDark : _petalTipLight;
    final drift = rotation / sakuraSymmetry;
    return CustomPaint(
      painter: ShapePainter(
        path: shapePathOf(MaterialShapes.clover4Leaf),
        color: overlay ?? const Color(0x00000000),
        ring: ring,
      ),
      child: CustomPaint(
        painter: _FallingPetalsPainter(tip: tip, drift: drift, over: false),
        foregroundPainter: _FallingPetalsPainter(
          tip: tip,
          drift: drift,
          over: true,
        ),
        child: SizedBox.square(
          dimension: size,
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _FallingPetalsPainter extends CustomPainter {
  _FallingPetalsPainter({
    required this.tip,
    required this.drift,
    required this.over,
  }) : _fill = Paint()
         ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, -1), [
           over ? _fallenBase : _petalBase,
           tip,
         ]);

  final Color tip;
  final double drift;
  final bool over;
  final Paint _fill;

  static final _veinPaint = Paint()
    ..color = _vein
    ..strokeWidth = 0.025;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = drift - drift.floorToDouble();
    for (final (index, petal) in _scattered.indexed) {
      if (petal.over != over) {
        continue;
      }
      final flight = math.sin(phase * math.pi);
      final sway = math.sin((phase + index / _scattered.length) * math.pi * 2);
      final length = size.width * petal.length;
      final turn = math.cos(phase * math.pi * 2 + index).abs();
      canvas
        ..save()
        ..translate(
          (petal.x + sway * flight * 0.04) * size.width,
          (petal.y + flight * 0.08) * size.height,
        )
        ..rotate(petal.tilt + sway * flight * 0.4)
        ..scale(length * petal.width * (1 - (1 - turn) * flight), length);
      if (over) {
        canvas.drawShadow(_petal, _shadow, 0.06, true);
      }
      canvas
        ..drawPath(_petal, _fill)
        ..drawLine(const Offset(0, -0.08), const Offset(0, -0.62), _veinPaint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_FallingPetalsPainter oldDelegate) =>
      oldDelegate.drift != drift ||
      oldDelegate.tip != tip ||
      oldDelegate.over != over;
}
