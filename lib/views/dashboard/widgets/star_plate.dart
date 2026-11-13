import 'dart:async';

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The twelve earthly branches round the plate, 子 at the bottom and running
/// clockwise, as a south-up chart sets 卯 in the east on the left.
const _branches = '子丑寅卯辰巳午未申酉戌亥';

/// Radii as shares of the plate's.
const _rim = 0.96;
const _branchRing = 0.79;
const _scale = 0.64;
const _flow = 0.53;
const _disc = 0.41;

/// One turn of the yin-yang flow while running, as the dipper turned before.
const _flowPeriod = Duration(minutes: 2);

/// What the plate shows, from the core's real state and the request in
/// flight: a transition holds until the request returns, and a start that
/// leaves the core down settles on [failed] instead of [on].
enum StarPlatePhase { off, starting, on, stopping, failed }

/// The rings that do not move, drawn once for each size, brightness and
/// lighting; a lit plate is the dim one with the lit one laid over it.
final _rings = <(double, Brightness, bool, TextStyle), ui.Picture>{};

/// The branches' face, at a size the plate scales to its own.
TextStyle starPlateGlyphs(BuildContext context) =>
    AppTextStyle.custom(
      context,
      size: _glyphSize,
      leading: _glyphSize,
      weight: FontWeight.w700,
    ).copyWith(
      fontFamily: starChartSerifFamilies.first,
      fontFamilyFallback: starChartSerifFamilies.skip(1).toList(),
    );

const _glyphSize = 32.0;

ui.Picture _ringsOf(
  double radius,
  Brightness brightness,
  TextStyle glyphs, {
  required bool lit,
}) {
  final key = (radius, brightness, lit, glyphs);
  if (_rings[key] case final picture?) {
    return picture;
  }
  final dark = brightness == Brightness.dark;
  final gilt = StarChartColors.giltOf(brightness);
  final glyph = lit
      ? (dark ? StarChartColors.goldBright : StarChartColors.goldInk)
      : (dark ? const Color(0xFF6A675F) : const Color(0xFFB3AA98));
  final strength = lit ? 1.0 : 0.45;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final stroke = Paint()..style = PaintingStyle.stroke;
  canvas
    ..drawCircle(
      Offset.zero,
      radius * _rim,
      stroke
        ..strokeWidth = 1.4
        ..color = gilt.withValues(alpha: 0.7 * strength),
    )
    ..drawCircle(
      Offset.zero,
      radius * (_rim - 0.045),
      stroke
        ..strokeWidth = 0.8
        ..color = gilt.withValues(alpha: 0.35 * strength),
    )
    ..drawCircle(
      Offset.zero,
      radius * _scale,
      stroke
        ..strokeWidth = 1
        ..color = gilt.withValues(alpha: 0.6 * strength),
    );
  final tick = Paint()..strokeCap = StrokeCap.round;
  for (var i = 0; i < 72; i++) {
    final major = i % 6 == 3;
    final angle = i * math.pi / 36;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final outer = radius * _scale;
    final inner = outer - radius * (major ? 0.075 : 0.038);
    canvas.drawLine(
      direction * outer,
      direction * inner,
      tick
        ..strokeWidth = major ? 1.3 : 0.8
        ..color = gilt.withValues(alpha: (major ? 0.9 : 0.5) * strength),
    );
  }
  final style = glyphs.copyWith(color: glyph);
  final scale = radius * 0.16 / _glyphSize;
  for (var i = 0; i < _branches.length; i++) {
    final angle = math.pi / 2 + i * math.pi / 6;
    final painter = TextPainter(
      text: TextSpan(text: _branches[i], style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas
      ..save()
      ..translate(
        math.cos(angle) * radius * _branchRing,
        math.sin(angle) * radius * _branchRing,
      )
      ..scale(scale);
    painter
      ..paint(canvas, Offset(-painter.width / 2, -painter.height / 2))
      ..dispose();
    canvas.restore();
  }
  final picture = recorder.endRecording();
  _rings[key] = picture;
  if (_rings.length > 12) {
    _rings.remove(_rings.keys.first)?.dispose();
  }
  return picture;
}

/// Paints the plate centered on [center]: the branches and graduations,
/// lit as far as [lit]; while a request is in flight, [sweep] lights them
/// from 子 round to its head; the yin-yang ring turned [turn]; and the disc
/// the button sits on with its sign, the dipper's seven-pointed star once
/// lit and an armillary sphere at rest.
void paintStarPlate(
  Canvas canvas,
  Offset center,
  double radius, {
  required Brightness brightness,
  required double lit,
  required double turn,
  required Color disc,
  required Color error,
  required TextStyle glyphs,
  double? sweep,
  bool failed = false,
}) {
  final dark = brightness == Brightness.dark;
  final gilt = StarChartColors.giltOf(brightness);
  final bright = dark ? StarChartColors.goldBright : StarChartColors.goldInk;
  canvas
    ..save()
    ..translate(center.dx, center.dy);
  if (lit > 0) {
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, radius, [
          bright.withValues(alpha: 0.16 * lit),
          bright.withValues(alpha: 0),
        ]),
    );
  }
  canvas
    ..drawCircle(
      Offset.zero,
      radius * _rim,
      Paint()..color = dark ? const Color(0xFF141725) : const Color(0xFFF7F2E7),
    )
    ..drawPicture(_ringsOf(radius, brightness, glyphs, lit: false));
  if (sweep != null) {
    final reach = sweep * math.pi * 2;
    canvas
      ..save()
      ..clipPath(
        Path()
          ..moveTo(0, 0)
          ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: radius),
            math.pi / 2,
            reach,
            false,
          )
          ..close(),
      )
      ..drawPicture(_ringsOf(radius, brightness, glyphs, lit: true))
      ..restore()
      ..drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * (_rim - 0.02)),
        math.pi / 2,
        reach,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2, radius * 0.022)
          ..color = bright,
      );
  } else if (lit > 0) {
    canvas
      ..saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, lit.clamp(0, 1)),
      )
      ..drawPicture(_ringsOf(radius, brightness, glyphs, lit: true))
      ..restore();
  }
  if (failed) {
    canvas.drawCircle(
      Offset.zero,
      radius * _rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = error,
    );
  }

  final flow = radius * _flow;
  final flowRect = Rect.fromCircle(center: Offset.zero, radius: flow);
  canvas
    ..save()
    ..rotate(turn * math.pi * 2)
    ..drawCircle(
      Offset.zero,
      flow,
      Paint()
        ..shader = ui.Gradient.linear(
          flowRect.topLeft,
          flowRect.bottomRight,
          [
            bright.withValues(alpha: 0.2 + 0.6 * lit),
            gilt.withValues(alpha: 0.06 + 0.18 * lit),
            (dark ? const Color(0xFF0F1118) : const Color(0xFF24201A))
                .withValues(alpha: 0.25 + 0.4 * lit),
          ],
          const [0, 0.5, 1],
        ),
    )
    ..drawPath(
      Path()
        ..moveTo(0, -flow)
        ..arcToPoint(Offset.zero, radius: Radius.circular(flow / 2))
        ..arcToPoint(
          Offset(0, flow),
          radius: Radius.circular(flow / 2),
          clockwise: false,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gilt.withValues(alpha: 0.2 + 0.35 * lit),
    )
    ..restore();

  final discRadius = radius * _disc;
  canvas
    ..drawCircle(Offset.zero, discRadius, Paint()..color = disc)
    ..drawCircle(
      Offset.zero,
      discRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = failed ? error : gilt.withValues(alpha: 0.45 + 0.4 * lit),
    );
  final sign = discRadius * 0.6;
  final rest = failed
      ? error
      : dark
      ? const Color(0xFFB9B2A0)
      : const Color(0xFF7A6F5C);
  if (lit < 1 || failed) {
    _paintArmillary(
      canvas,
      sign,
      rest.withValues(alpha: failed ? 1 : 1 - lit),
      radius * 0.022,
    );
  }
  if (lit > 0 && !failed) {
    _paintHeptagram(canvas, sign * 1.04, bright.withValues(alpha: lit), radius);
  }
  canvas.restore();
}

void _paintArmillary(Canvas canvas, double radius, Color color, double width) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;
  canvas
    ..drawCircle(Offset.zero, radius, paint)
    ..save()
    ..rotate(-23 * math.pi / 180)
    ..drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2,
        height: radius * 0.64,
      ),
      paint..strokeWidth = width * 0.85,
    )
    ..restore()
    ..drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.64,
        height: radius * 2,
      ),
      paint..color = color.withValues(alpha: color.a * 0.7),
    )
    ..drawLine(
      Offset(0, radius),
      Offset(0, radius * 1.28),
      paint
        ..color = color
        ..strokeWidth = width,
    )
    ..drawCircle(Offset.zero, radius * 0.12, Paint()..color = color);
}

/// The seven-pointed star {7/3}, the dipper's sign.
void _paintHeptagram(Canvas canvas, double radius, Color color, double plate) {
  final path = Path();
  for (var i = 0; i < 7; i++) {
    final angle = -math.pi / 2 + i * 3 * math.pi * 2 / 7;
    final point = Offset(math.cos(angle), math.sin(angle)) * radius;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  path.close();
  canvas
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, plate * 0.024)
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    )
    ..drawCircle(Offset.zero, radius * 0.16, Paint()..color = color);
}

/// The start button as a star plate: tap to start or stop the core, with the
/// plate following the request until the core answers.
class StarPlateToggle extends ConsumerStatefulWidget {
  const StarPlateToggle({
    super.key,
    required this.size,
    required this.enabled,
    required this.running,
    required this.suspended,
  });

  final double size;
  final bool enabled;
  final bool running;
  final bool suspended;

  @override
  ConsumerState<StarPlateToggle> createState() => _StarPlateToggleState();
}

class _StarPlateToggleState extends ConsumerState<StarPlateToggle>
    with SingleTickerProviderStateMixin {
  static const _sweepPeriod = Duration(milliseconds: 2400);

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: _sweepPeriod,
  );

  /// The request in flight, or a start that left the core down.
  StarPlatePhase? _pending;
  var _hovered = false;
  var _focused = false;

  bool get _busy =>
      _pending == StarPlatePhase.starting ||
      _pending == StarPlatePhase.stopping;

  StarPlatePhase get _phase =>
      _pending ?? (widget.running ? StarPlatePhase.on : StarPlatePhase.off);

  @override
  void didUpdateWidget(StarPlateToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pending == StarPlatePhase.failed &&
        oldWidget.running != widget.running) {
      _pending = null;
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) {
      return;
    }
    final target = !ref.read(isStartProvider);
    setState(
      () =>
          _pending = target ? StarPlatePhase.starting : StarPlatePhase.stopping,
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      unawaited(_sweep.repeat());
    }
    try {
      await ref.read(commonActionProvider.notifier).setRunning(target);
    } finally {
      if (mounted) {
        _sweep
          ..stop()
          ..value = 0;
        setState(() {
          _pending = target && !ref.read(isStartProvider)
              ? StarPlatePhase.failed
              : null;
        });
      }
    }
  }

  String _label(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return switch (_phase) {
      StarPlatePhase.starting => appLocalizations.coreStarting,
      StarPlatePhase.stopping => appLocalizations.coreStopping,
      StarPlatePhase.failed => appLocalizations.startFailedRetry,
      StarPlatePhase.on =>
        widget.suspended ? appLocalizations.suspended : appLocalizations.stop,
      StarPlatePhase.off => appLocalizations.start,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final brightness = colorScheme.brightness;
    final dark = brightness == Brightness.dark;
    final phase = _phase;
    final enabled = widget.enabled;
    final lit = switch (phase) {
      StarPlatePhase.on => widget.suspended ? 0.4 : 1.0,
      StarPlatePhase.stopping => 0.5,
      _ => 0.0,
    };
    final overlay = !enabled
        ? 0.0
        : _focused
        ? 0.1
        : _hovered
        ? 0.06
        : 0.0;
    final label = _label(context);
    final size = widget.size;
    final glyphs = starPlateGlyphs(context);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: PressRegion(
          onTap: enabled ? _toggle : null,
          shape: AppShape.circle,
          onHover: (value) => setState(() => _hovered = value),
          onFocusChange: (value) => setState(() => _focused = value),
          excludeFromSemantics: true,
          child: ElasticPress(
            enabled: enabled,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: lit),
              duration: context.motionDuration(
                const Duration(milliseconds: 600),
              ),
              curve: Curves.easeOutCubic,
              builder: (_, lit, _) => Consumer(
                builder: (_, ref, _) {
                  final runTime = phase == StarPlatePhase.on
                      ? ref.watch(runTimeProvider)
                      : null;
                  final turn =
                      runTime == null || MediaQuery.disableAnimationsOf(context)
                      ? 0.0
                      : runTime / _flowPeriod.inMilliseconds % 1;
                  final disc = Color.alphaBlend(
                    colorScheme.onSurface.withValues(alpha: overlay),
                    Color.lerp(
                      dark ? const Color(0xFF1B1E2A) : const Color(0xFFF2ECE0),
                      dark ? const Color(0xFF262335) : const Color(0xFFFFF9EA),
                      lit,
                    )!,
                  );
                  return AnimatedBuilder(
                    animation: _sweep,
                    builder: (_, _) => CustomPaint(
                      size: Size.square(size),
                      painter: _StarPlatePainter(
                        brightness: brightness,
                        lit: enabled ? lit : 0,
                        turn: turn,
                        disc: disc,
                        error: colorScheme.error,
                        glyphs: glyphs,
                        sweep: _busy
                            ? (phase == StarPlatePhase.starting
                                  ? _sweep.value
                                  : 1 - _sweep.value)
                            : null,
                        failed: phase == StarPlatePhase.failed,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPlatePainter extends CustomPainter {
  const _StarPlatePainter({
    required this.brightness,
    required this.lit,
    required this.turn,
    required this.disc,
    required this.error,
    required this.glyphs,
    required this.sweep,
    required this.failed,
  });

  final Brightness brightness;
  final double lit;
  final double turn;
  final Color disc;
  final Color error;
  final TextStyle glyphs;
  final double? sweep;
  final bool failed;

  @override
  void paint(Canvas canvas, Size size) {
    paintStarPlate(
      canvas,
      size.center(Offset.zero),
      size.shortestSide / 2,
      brightness: brightness,
      lit: lit,
      turn: turn,
      disc: disc,
      error: error,
      glyphs: glyphs,
      sweep: sweep,
      failed: failed,
    );
  }

  @override
  bool shouldRepaint(_StarPlatePainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.lit != lit ||
      oldDelegate.turn != turn ||
      oldDelegate.disc != disc ||
      oldDelegate.error != error ||
      oldDelegate.glyphs != glyphs ||
      oldDelegate.sweep != sweep ||
      oldDelegate.failed != failed;
}
