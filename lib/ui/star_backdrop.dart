import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import 'star_chart.dart';

/// The page behind the star-chart dashboard: sky with the Purple Forbidden
/// Enclosure's two walls (紫微垣) above, ink-wash mountains and a river
/// below. One scene for both states; [lit] brightens it while running.
class StarChartBackdrop extends StatelessWidget {
  const StarChartBackdrop({super.key, required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    final brightness = context.colorScheme.brightness;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: lit ? 1 : 0),
        duration: context.motionDuration(const Duration(milliseconds: 1200)),
        curve: Curves.easeInOutCubic,
        builder: (_, lit, _) => CustomPaint(
          painter: lit == 0 || lit == 1
              ? StarChartBackdropRasterPainter(
                  brightness: brightness,
                  lit: lit,
                  pixelRatio: pixelRatio,
                )
              : StarChartBackdropPainter(brightness: brightness, lit: lit),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// The backdrop at rest, drawn from one image shared by every page.
///
/// Impeller keeps no raster cache, so the sky's gradient, stars and the
/// three gradient-filled ranges were filled and tessellated again on every
/// frame a page scrolled or slid, twice while one page slid over another.
/// The scene is soft, so the image is taken at no more than twice the
/// logical size.
class StarChartBackdropRasterPainter extends CustomPainter {
  const StarChartBackdropRasterPainter({
    required this.brightness,
    required this.lit,
    required this.pixelRatio,
  });

  static const double maxPixelRatio = 2;

  /// The images held at once, one per size, brightness and lighting; two
  /// cover a page and a sheet or window of another size.
  static const int cacheSize = 2;

  static final _rasters = <(Size, double, Brightness, double), ui.Image>{};

  /// How many images are held, for tests.
  static int get cachedCount => _rasters.length;

  static void clearCache() {
    for (final raster in _rasters.values) {
      raster.dispose();
    }
    _rasters.clear();
  }

  final Brightness brightness;
  final double lit;
  final double pixelRatio;

  ui.Image _rasterOf(Size size) {
    final ratio = math.min(pixelRatio, maxPixelRatio);
    final key = (size, ratio, brightness, lit);
    final cached = _rasters.remove(key);
    if (cached != null) {
      return _rasters[key] = cached;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    StarChartBackdropPainter(
      brightness: brightness,
      lit: lit,
    ).paint(canvas, size);
    final picture = recorder.endRecording();
    final raster = picture.toImageSync(
      (size.width * ratio).ceil(),
      (size.height * ratio).ceil(),
    );
    picture.dispose();
    _rasters[key] = raster;
    while (_rasters.length > cacheSize) {
      // A picture already recorded with it keeps its own reference.
      _rasters.remove(_rasters.keys.first)!.dispose();
    }
    return raster;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final raster = _rasterOf(size);
    canvas.drawImageRect(
      raster,
      Rect.fromLTWH(0, 0, raster.width.toDouble(), raster.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(StarChartBackdropRasterPainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.lit != lit ||
      oldDelegate.pixelRatio != pixelRatio;
}

/// Stars in shares of the sky's width and height, with a radius and an
/// opacity, from a fixed seed so the sky is the same every time.
final _stars = () {
  final random = math.Random(11);
  return [
    for (var i = 0; i < 160; i++)
      (
        Offset(
          random.nextDouble(),
          math.pow(random.nextDouble(), 1.6).toDouble() * 0.62,
        ),
        0.3 + random.nextDouble() * 1.1,
        0.35 + random.nextDouble() * 0.65,
      ),
  ];
}();

class StarChartBackdropPainter extends CustomPainter {
  const StarChartBackdropPainter({
    required this.brightness,
    required this.lit,
    this.detail = 1,
  });

  final Brightness brightness;
  final double lit;

  /// Shrinks stars and strokes for a small sketch of the page.
  final double detail;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final dark = brightness == Brightness.dark;
    final star = StarChartColors.starOf(brightness);
    final gilt = StarChartColors.giltOf(brightness);
    final glow = dark ? const Color(0xFF232740) : const Color(0xFFFBF5E6);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.62, -size.height * 0.1),
          size.longestSide * 0.8,
          [
            glow.withValues(alpha: 0.35 + 0.65 * lit),
            glow.withValues(alpha: 0),
          ],
        ),
    );

    final count = (size.width * size.height / 5200).clamp(24, 160).round();
    final starPaint = Paint();
    final dim = dark ? 1.0 : 0.55;
    for (final (at, radius, alpha) in _stars.take(count)) {
      canvas.drawCircle(
        Offset(at.dx * size.width, at.dy * size.height),
        radius * detail,
        starPaint
          ..color = star.withValues(alpha: (0.28 + 0.27 * lit) * alpha * dim),
      );
    }
    _paintEnclosure(canvas, size, star, gilt);
    _paintLand(canvas, size, gilt, dark);
  }

  /// The enclosure's left and right walls, a row of stars each joined as a
  /// star official (星官) is drawn, arcing round the pole above the page.
  void _paintEnclosure(Canvas canvas, Size size, Color star, Color gilt) {
    final radius = math.min(size.width, size.height) * 0.36;
    final center = Offset(size.width * 0.62, radius * 0.1);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = detail
      ..color = gilt.withValues(alpha: 0.1 + 0.12 * lit);
    final dot = Paint()..color = star.withValues(alpha: 0.25 + 0.3 * lit);
    for (final side in const [-1, 1]) {
      final wall = Path();
      for (var k = 0; k < 8; k++) {
        final degrees = side < 0 ? 200 + k * 14.0 : -20 - k * 14.0;
        final angle = degrees * math.pi / 180;
        final reach = radius * (1 + 0.04 * math.sin(k * 1.7));
        final point =
            center +
            Offset(
              math.cos(angle) * reach,
              math.sin(angle).abs() * reach * 0.85,
            );
        k == 0
            ? wall.moveTo(point.dx, point.dy)
            : wall.lineTo(point.dx, point.dy);
        canvas.drawCircle(point, 2 * detail, dot);
      }
      canvas.drawPath(wall, line);
    }
  }

  void _paintLand(Canvas canvas, Size size, Color gilt, bool dark) {
    final height = math.min(size.height * 0.3, 300.0 * detail);
    final top = size.height - height;
    final colors = StarChartColors.mountainsOf(brightness);
    const layers = [(0.40, 0.38, 3.0), (0.62, 0.36, 9.0), (0.86, 0.30, 17.0)];
    for (var i = 0; i < layers.length; i++) {
      final (base, amplitude, phase) = layers[i];
      final ridge = _ridge(
        size.width,
        top + height * base,
        height * amplitude,
        phase,
      );
      final color = colors[i];
      final strength =
          (dark ? 0.55 + i * 0.2 : 0.55 + i * 0.08) * (0.7 + 0.3 * lit);
      canvas.drawPath(
        Path.from(ridge)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, top + height * (base - amplitude)),
            Offset(0, size.height),
            [
              color.withValues(alpha: strength),
              color.withValues(alpha: strength * 0.55),
              color.withValues(alpha: strength * 0.2),
            ],
            const [0, 0.75, 1],
          ),
      );
      if (lit > 0) {
        canvas.drawPath(
          ridge,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (1.2 - i * 0.25) * detail
            ..color = gilt.withValues(alpha: (0.28 - i * 0.06) * lit),
        );
      }
    }
    final y = top + height * 0.93;
    final w = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(0, y)
        ..cubicTo(
          w * 0.25,
          y - 18 * detail,
          w * 0.45,
          y + 22 * detail,
          w * 0.7,
          y - 6 * detail,
        )
        ..cubicTo(
          w * 0.82,
          y - 14 * detail,
          w * 0.92,
          y + 8 * detail,
          w,
          y - 4 * detail,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2 * detail
        ..color = Color.lerp(
          dark ? const Color(0x803A3D4C) : const Color(0x80C9C0AD),
          gilt.withValues(alpha: 0.32),
          lit,
        )!,
    );
  }

  /// A ridge line across [width] round [base], from a few summed waves.
  static Path _ridge(
    double width,
    double base,
    double amplitude,
    double phase,
  ) {
    final path = Path();
    final step = math.max(8.0, width / 60);
    Offset? last;
    for (var x = 0.0; x <= width + step; x += step) {
      final t = x / width;
      final y =
          base -
          amplitude *
              (math.sin(t * math.pi * 2.2 + phase) * 0.5 +
                  math.sin(t * math.pi * 5.3 + phase * 2) * 0.28 +
                  math.sin(t * math.pi * 11 + phase) * 0.12 +
                  0.6);
      final point = Offset(x, y);
      if (last == null) {
        path.moveTo(point.dx, point.dy);
      } else {
        final mid = (last + point) / 2;
        path.quadraticBezierTo(last.dx, last.dy, mid.dx, mid.dy);
      }
      last = point;
    }
    return path;
  }

  @override
  bool shouldRepaint(StarChartBackdropPainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.lit != lit ||
      oldDelegate.detail != detail;
}
