import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart' hide Switch;
import 'package:prism_ui/prism_ui.dart' as prism show Switch;

import 'star_chart.dart';

/// prism_ui's switch, drawn as a yao line under the star-chart look so every
/// page's switches follow it without each call site knowing.
class Switch extends StatelessWidget {
  const Switch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  static const trackWidth = prism.Switch.trackWidth;
  static const trackHeight = prism.Switch.trackHeight;

  @override
  Widget build(BuildContext context) {
    if (!StarChartScope.of(context)) {
      return prism.Switch(
        value: value,
        onChanged: onChanged,
        semanticLabel: semanticLabel,
      );
    }
    // The same footprint as prism_ui's, so a row keeps its height.
    return SizedBox(
      width: trackWidth + 8,
      height: switch (Theme.of(context).tapTargetSize) {
        TapTargetSize.padded => kMinInteractiveDimension,
        TapTargetSize.shrinkWrap => kMinInteractiveDimension - 8,
      },
      child: Center(
        child: YaoSwitch(
          value: value,
          onChanged: onChanged,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

/// The star-chart switch: off shows a broken line (陰爻) across its track, on
/// a whole one (陽爻), with a gilt bead at the on end.
class YaoSwitch extends StatelessWidget {
  const YaoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final colorScheme = context.colorScheme;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: PressRegion(
        onTap: onChanged == null ? null : () => onChanged(!value),
        shape: AppShape.full,
        overlay: PressRegion.focusOverlay,
        excludeFromSemantics: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value ? 1 : 0),
          duration: context.motionDuration(commonDuration),
          curve: Curves.easeOutCubic,
          builder: (_, on, _) => CustomPaint(
            size: const Size(prism.Switch.trackWidth, prism.Switch.trackHeight),
            painter: _YaoPainter(
              on: on,
              enabled: onChanged != null,
              colorScheme: colorScheme,
            ),
          ),
        ),
      ),
    );
  }
}

class _YaoPainter extends CustomPainter {
  const _YaoPainter({
    required this.on,
    required this.enabled,
    required this.colorScheme,
  });

  final double on;
  final bool enabled;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = colorScheme.brightness == Brightness.dark;
    final gilt = StarChartColors.giltOf(colorScheme.brightness);
    final rect = Offset.zero & size;
    final track = Color.lerp(
      colorScheme.surfaceContainerHighest,
      Color.alphaBlend(
        gilt.withValues(alpha: dark ? 0.22 : 0.2),
        colorScheme.surfaceContainerHigh,
      ),
      on,
    )!;
    AppShape.full.paintInterior(canvas, rect, Paint()..color = track);
    canvas.drawPath(
      AppShape.full.getOuterPath(rect.deflate(0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.lerp(
          StarChartColors.hairlineOf(colorScheme.brightness),
          gilt,
          on,
        )!,
    );
    final thumbRadius = size.height / 2 - 4;
    final left = size.height / 2;
    final right = size.width - size.height / 2;
    final thumbX = left + (right - left) * on;
    final y = size.height / 2;
    final lineStart = size.height * 0.36;
    final lineEnd = size.width - size.height * 0.36;
    final gap = size.width * 0.16 * (1 - on);
    final mid = size.width / 2;
    final line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        colorScheme.outline,
        gilt.withValues(alpha: 0.75),
        on,
      )!;
    canvas
      ..drawLine(Offset(lineStart, y), Offset(mid - gap / 2, y), line)
      ..drawLine(Offset(mid + gap / 2, y), Offset(lineEnd, y), line)
      ..drawCircle(
        Offset(thumbX, y + 1),
        thumbRadius,
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      )
      ..drawCircle(
        Offset(thumbX, y),
        thumbRadius,
        Paint()
          ..color = Color.lerp(
            dark ? const Color(0xFF4A4B55) : const Color(0xFFFFFFFF),
            dark ? StarChartColors.goldBright : StarChartColors.goldInk,
            on,
          )!.withValues(alpha: enabled ? 1 : 0.5),
      );
  }

  @override
  bool shouldRepaint(_YaoPainter oldDelegate) =>
      oldDelegate.on != on ||
      oldDelegate.enabled != enabled ||
      oldDelegate.colorScheme != colorScheme;
}
