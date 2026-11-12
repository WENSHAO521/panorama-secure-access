import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/shapes/shapes.dart';

import 'card.dart';

/// The turn after which the clover under the petals looks the same again.
const sakuraSymmetry = math.pi / 2;

const _groundLight = Color(0xFFFCE4EC);
const _groundDark = Color(0xFF4A2733);
const _petalLight = Color(0xFFF48FB1);
const _petalDark = Color(0xFFE38AAA);

/// One notched cherry petal pointing up from the origin, its tip at 0.5.
final Path _petal = Path()
  ..moveTo(0, 0)
  ..cubicTo(-0.26, -0.1, -0.3, -0.4, -0.12, -0.49)
  ..quadraticBezierTo(-0.05, -0.52, 0, -0.4)
  ..quadraticBezierTo(0.05, -0.52, 0.12, -0.49)
  ..cubicTo(0.3, -0.4, 0.26, -0.1, 0, 0)
  ..close();

/// Where each petal lies in the badge's unit square, with its tilt, size and
/// strength; a few have blown a little past the badge's edge.
const _scattered = [
  (x: 0.2, y: 0.22, tilt: -0.6, scale: 0.3, alpha: 0.9),
  (x: 0.52, y: 0.12, tilt: 0.9, scale: 0.24, alpha: 0.7),
  (x: 0.82, y: 0.26, tilt: 2.1, scale: 0.28, alpha: 0.85),
  (x: 0.14, y: 0.6, tilt: -2.4, scale: 0.22, alpha: 0.6),
  (x: 0.86, y: 0.66, tilt: 1.5, scale: 0.26, alpha: 0.75),
  (x: 0.32, y: 0.86, tilt: 2.8, scale: 0.28, alpha: 0.9),
  (x: 0.7, y: 0.9, tilt: -1.2, scale: 0.22, alpha: 0.65),
  (x: -0.08, y: 0.34, tilt: -1.0, scale: 0.26, alpha: 0.8),
  (x: 1.08, y: 0.48, tilt: 1.1, scale: 0.22, alpha: 0.7),
  (x: 0.96, y: 1.06, tilt: 2.5, scale: 0.26, alpha: 0.8),
  (x: 0.02, y: 1.02, tilt: -2.2, scale: 0.2, alpha: 0.6),
];

/// A pale clover strewn with cherry petals, [child] centered on it.
///
/// [rotation] turns the clover; the petals drift down while it turns.
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

  /// Blended over the clover, as hover feedback.
  final Color? overlay;
  final double rotation;
  final BorderSide? ring;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ground = dark ? _groundDark : _groundLight;
    final overlay = this.overlay;
    return CustomPaint(
      painter: ShapePainter(
        path: shapePathOf(MaterialShapes.clover4Leaf),
        color: overlay == null ? ground : Color.alphaBlend(overlay, ground),
        rotation: rotation,
        ring: ring,
      ),
      child: CustomPaint(
        painter: _FallingPetalsPainter(
          color: dark ? _petalDark : _petalLight,
          drift: rotation / sakuraSymmetry,
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
  const _FallingPetalsPainter({required this.color, required this.drift});

  final Color color;

  /// Clover turns so far; each whole one brings every petal back to rest.
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = drift - drift.floorToDouble();
    final settle = math.cos(phase * math.pi * 2) * 0.25 + 0.75;
    for (final (index, petal) in _scattered.indexed) {
      final sway = math.sin((phase + index / _scattered.length) * math.pi * 2);
      final paint = Paint()
        ..color = color.withValues(alpha: petal.alpha * settle);
      canvas
        ..save()
        ..translate(
          (petal.x + sway * 0.03) * size.width,
          (petal.y + phase * 0.12) * size.height,
        )
        ..rotate(petal.tilt + phase * math.pi)
        ..scale(size.width * petal.scale)
        ..drawPath(_petal, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_FallingPetalsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.drift != drift;
}
