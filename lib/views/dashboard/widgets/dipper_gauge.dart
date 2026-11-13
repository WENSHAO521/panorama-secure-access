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

/// The width past which stars and lines stop growing with the asterism.
const _starScaleCap = 140.0;

/// How much room a star's glow takes beyond its reach.
const _glowReach = 1.7;

/// How big a star of [magnitude] is next to the brightest of the seven. Each
/// magnitude is about two and a half times fainter; the size follows that
/// gently so the faintest, Megrez, is still plainly a star.
double _sizeOf(double magnitude) =>
    math.pow(10, -0.13 * (magnitude - 1.77)).toDouble();

/// The handle, Alkaid to Alioth, and the bowl, Megrez to Dubhe, as the
/// first and last star of each in [_stars].
const _handle = (0, 2);
const _bowl = (_bowlStart, _bowlEnd);

/// Where the asterism sits when it spans a box [width] wide, as shares of
/// that width: the room left above its handle, from the top of the box to
/// the top of its stars there, and the top of the room under its bowl.
const dipperBoxDepth = (_depth + _litReach * 2) / (1 + _litReach * 2);
const dipperRoomOverHandle = 0.268 / (1 + _litReach * 2);
const dipperRoomUnderBowl = 0.51 / (1 + _litReach * 2);

/// The seven stars of the Northern Dipper over a speed: a faint outline of
/// the asterism, a violet-to-gold trail along it up to [level], and the stars
/// it has passed lit in gold, each as large as it is bright and the newest
/// with a halo. [level] eases to each new speed.
///
/// [DipperGauge.split] shows two speeds at once: the upload climbs the
/// handle in violet and the download fills the bowl in gold.
class DipperGauge extends StatelessWidget {
  const DipperGauge({super.key, required this.level, required this.dark})
    : download = null;

  const DipperGauge.split({
    super.key,
    required double upload,
    required double this.download,
    required this.dark,
  }) : level = upload;

  /// How full the gauge stands, from 0 to 1: see [dipperLevel]. On a split
  /// gauge, the upload's.
  final double level;

  /// On a split gauge, how full the download stands.
  final double? download;
  final bool dark;

  static const _ease = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    final download = this.download;
    return TweenAnimationBuilder<Offset>(
      tween: Tween(end: Offset(level, download ?? 0)),
      duration: _ease,
      curve: Curves.easeOutCubic,
      builder: (context, levels, _) => CustomPaint(
        painter: _DipperPainter.of(
          level: levels.dx,
          download: download == null ? null : levels.dy,
          dark: dark,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Paints the gauge at [level] into [box] of [canvas] without easing, for a
/// sketch of the dashboard such as the theme preview. With [download], it is
/// split as [DipperGauge.split] is.
///
/// [starScaleCap] keeps the stars in proportion to a sketch drawn smaller
/// than the real card.
void paintDipper(
  Canvas canvas,
  Rect box, {
  required double level,
  double? download,
  required bool dark,
  double starScaleCap = _starScaleCap,
}) {
  canvas
    ..save()
    ..translate(box.left, box.top);
  _DipperPainter.of(
    level: level,
    download: download,
    dark: dark,
    starScaleCap: starScaleCap,
  ).paint(canvas, box.size);
  canvas.restore();
}

/// A run of stars that lights up together, from [first] to [last], as far as
/// [level], in [colors] from its first star to its last.
typedef _Run = ({int first, int last, double level, List<Color> colors});

class _DipperPainter extends CustomPainter {
  _DipperPainter({
    required this.level,
    required this.download,
    required this.palette,
    required this.track,
    required this.starScaleCap,
  });

  _DipperPainter.of({
    required double level,
    double? download,
    required bool dark,
    double starScaleCap = _starScaleCap,
  }) : this(
         level: level,
         download: download,
         starScaleCap: starScaleCap,
         palette: dark ? StarPalette.dark : StarPalette.light,
         track: dark ? const Color(0x33B9A4F0) : const Color(0x265B3FB8),
       );

  final double level;
  final double? download;
  final StarPalette palette;
  final Color track;
  final double starScaleCap;

  static final _heart = Paint()..color = const Color(0xFFFFFFFF);

  List<_Run> get _runs {
    final download = this.download;
    if (download == null) {
      return [
        (
          first: 0,
          last: _stars.length - 1,
          level: level,
          colors: [palette.ringLight, palette.gold],
        ),
      ];
    }
    return [
      (
        first: _handle.$1,
        last: _handle.$2,
        level: level,
        colors: [palette.ringLight, palette.ringDeep],
      ),
      (
        first: _bowl.$1,
        last: _bowl.$2,
        level: download,
        colors: [palette.gold, palette.gold],
      ),
    ];
  }

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
    // Stars and lines keep to a size that reads as a sky of points however
    // wide the asterism is drawn.
    final unit = math.min(width, starScaleCap);
    final stroke = unit * 0.009;
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

    // Along each run, the trail reaches its k-th star once it has gone k
    // steps of the way; each star brightens over the step before it, and
    // none lights at idle.
    final lit = List.filled(_stars.length, 0.0);
    final newest = <int>{};
    for (final run in _runs) {
      final steps = (run.last - run.first).toDouble();
      final reached = run.level * steps;
      final awake = (run.level * 12).clamp(0.0, 1.0);
      for (var k = 0; k <= steps; k++) {
        lit[run.first + k] = (reached - k + 1).clamp(0.0, 1.0) * awake;
      }
      if (run.level <= 0) {
        continue;
      }
      newest.add(run.first + math.min(reached.ceil(), steps.toInt()));
      final from = points[run.first];
      final path = Path()..moveTo(from.dx, from.dy);
      for (var k = 1; k <= steps; k++) {
        final share = (reached - k + 1).clamp(0.0, 1.0);
        if (share == 0) {
          break;
        }
        final index = run.first + k;
        final to = Offset.lerp(points[index - 1], points[index], share)!;
        path.lineTo(to.dx, to.dy);
      }
      // The bowl closes once its lip, the last star, is lit.
      if (run.last == _bowlEnd) {
        final closing = lit[_bowlEnd];
        if (closing > 0) {
          final to = Offset.lerp(
            points[_bowlEnd],
            points[_bowlStart],
            closing,
          )!;
          path
            ..moveTo(points[_bowlEnd].dx, points[_bowlEnd].dy)
            ..lineTo(to.dx, to.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = ui.Gradient.linear(
            Offset(points[run.first].dx, 0),
            Offset(math.max(points[run.last].dx, points[run.first].dx + 1), 0),
            run.colors,
          ),
      );
    }

    final rest = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.18
      ..color = track.withValues(alpha: math.min(1, track.a * 2.5));
    final restHeart = Paint()
      ..color = track.withValues(alpha: math.min(1, track.a * 3));

    void drawStar(Offset at, double scale, double lit, {bool newest = false}) {
      final reach =
          unit * scale * (_restReach + (_litReach - _restReach) * lit);
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
      final scale = _sizeOf(_stars[index].$2);
      drawStar(
        points[index],
        scale,
        lit[index],
        newest: newest.contains(index),
      );
      if (index == _companionOf) {
        canvas.drawCircle(
          place(_stars[index].$1 + _companionOffset),
          unit * _companionReach * (0.8 + 0.2 * lit[index]),
          lit[index] == 0
              ? restHeart
              : (Paint()
                  ..color = palette.gold.withValues(
                    alpha: 0.35 + 0.65 * lit[index],
                  )),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DipperPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.download != download ||
      oldDelegate.palette != palette ||
      oldDelegate.track != track ||
      oldDelegate.starScaleCap != starScaleCap;
}
