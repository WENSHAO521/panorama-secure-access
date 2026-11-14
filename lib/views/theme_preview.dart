import 'dart:async';
import 'dart:ui' as ui;

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/views/dashboard/widgets/dipper_gauge.dart';
import 'package:fl_clash/views/dashboard/widgets/pole_star.dart';
import 'package:fl_clash/views/dashboard/widgets/star_plate.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreviewChoice<T> {
  const PreviewChoice({
    required this.value,
    required this.label,
    required this.pictogram,
  });

  final T value;
  final String label;
  final Widget pictogram;
}

class PreviewChoiceGroup<T> extends StatelessWidget {
  const PreviewChoiceGroup({
    super.key,
    required this.info,
    required this.choices,
    required this.value,
    required this.onChanged,
  });

  final Info info;
  final List<PreviewChoice<T>> choices;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoHeader(info: info),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: generateGroup([
            for (final choice in choices)
              DecorationListItem(
                leading: ExcludeSemantics(child: choice.pictogram),
                title: Text(choice.label),
                isSelected: choice.value == value,
                trailing: choice.value == value ? const SelectionCheck() : null,
                onPressed: () => onChanged(choice.value),
              ),
          ]),
        ),
      ],
    );
  }
}

/// The foot of a [MiniScreen], where the options differ, drawn at the size of
/// an icon.
class MiniScreenThumb extends StatelessWidget {
  const MiniScreenThumb({super.key, required this.screen});

  static const Size _screenSize = Size(96, 128);
  static const double _shownHeight = 66;
  static const double _height = 30;

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: _height * _screenSize.width / _shownHeight,
      child: StillRaster(
        child: ClipRSuperellipse(
          borderRadius: AppRadius.sm,
          child: FittedBox(
            child: SizedBox(
              width: _screenSize.width,
              height: _shownHeight,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: _screenSize.height,
                  maxHeight: _screenSize.height,
                  child: screen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSchemeTween extends Tween<ColorScheme> {
  _ColorSchemeTween({super.end});

  @override
  ColorScheme lerp(double t) => ColorScheme.lerp(begin!, end!, t);
}

/// The home page as the theme settings will draw it; its destinations can be
/// tapped to try the tab animation.
class ThemeLivePreview extends ConsumerStatefulWidget {
  const ThemeLivePreview({super.key});

  @override
  ConsumerState<ThemeLivePreview> createState() => _ThemeLivePreviewState();
}

class _ThemeLivePreviewState extends ConsumerState<ThemeLivePreview>
    with SingleTickerProviderStateMixin {
  static const double _phoneWidth = 168;
  static const _duration = Duration(milliseconds: 300);

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: kTabScrollDuration,
  );
  late final CurvedAnimation _slideCurve = CurvedAnimation(
    parent: _slide,
    curve: Curves.easeOut,
  );
  int _selected = 0;
  int? _previous;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      appSettingProvider.select((state) => state.tabAnimation),
      (_, _) => _select((_selected + 1) % MiniScreen.destinationCount),
    );
  }

  Future<void> _select(int index) async {
    if (index == _selected) {
      return;
    }
    final tabAnimation = ref.read(appSettingProvider).tabAnimation;
    final fade = tabAnimation == TabAnimation.fade;
    _slide.duration = fade ? fadeTabDuration : kTabScrollDuration;
    _slideCurve.curve = fade ? fadeTabCurve : Curves.easeOut;
    setState(() {
      _previous = _selected;
      _selected = index;
    });
    await _slide.forward(from: 0).orCancel.catchError((_) {});
    if (mounted && _selected == index) {
      setState(() => _previous = null);
    }
  }

  @override
  void dispose() {
    _slideCurve.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final brightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    final colorScheme = ref.watch(genColorSchemeProvider(brightness));
    final floatingBar = ref.watch(
      appSettingProvider.select((state) => state.floatingNavigationBar),
    );
    final tabAnimation = ref.watch(
      appSettingProvider.select((state) => state.tabAnimation),
    );
    final liquidGlass = ref.watch(
      themeSettingProvider.select(
        (state) => state.liquidGlass != LiquidGlassMode.none,
      ),
    );
    final starChart = ref.watch(
      themeSettingProvider.select((state) => state.starChart),
    );
    final corner = AppCorner.fit(_phoneWidth);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: context.raisedSurfaceLevel.colorOf(context.colorScheme),
        shape: AppShape.xxl,
      ),
      child: SizedBox(
        width: _phoneWidth,
        child: AspectRatio(
          aspectRatio: 9 / 17,
          child: StillRaster(
            child: ClipRSuperellipse(
              borderRadius: AppRadius.all(corner),
              child: TweenAnimationBuilder<ColorScheme>(
                tween: _ColorSchemeTween(end: colorScheme),
                duration: _duration,
                builder: (_, colorScheme, _) => AnimatedSwitcher(
                  duration: _duration,
                  child: AnimatedBuilder(
                    key: ValueKey((floatingBar, liquidGlass, starChart)),
                    animation: _slideCurve,
                    builder: (_, _) => MiniScreen(
                      colorScheme: colorScheme,
                      floatingBar: floatingBar,
                      liquidGlass: liquidGlass,
                      selected: _selected,
                      previous: _previous,
                      progress: _previous == null ? 1 : _slideCurve.value,
                      tabAnimation: tabAnimation,
                      onSelect: _select,
                      starChart: starChart,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws [child] from a raster of itself once it has held still for [settle].
///
/// Impeller keeps no raster cache, so a sketch of hundreds of paths and
/// blurred glows costs the raster thread all of them again on every frame the
/// page scrolls; the theme page shows sixteen. Held still, each is one image.
/// A repaint under it drops the raster and paints live until the child holds
/// still again, so an animation never captures a frame per frame. The first
/// paint is taken at once. A repaint
/// boundary under it would keep its changes from reaching it: keep none.
class StillRaster extends SingleChildRenderObjectWidget {
  const StillRaster({
    super.key,
    this.settle = const Duration(milliseconds: 150),
    super.child,
  });

  final Duration settle;

  @override
  RenderStillRaster createRenderObject(BuildContext context) =>
      RenderStillRaster(
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        settle: settle,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderStillRaster renderObject,
  ) {
    renderObject
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..settle = settle;
  }
}

class RenderStillRaster extends RenderProxyBox {
  RenderStillRaster({required double devicePixelRatio, required this.settle})
    : _devicePixelRatio = devicePixelRatio;

  Duration settle;
  ui.Image? _raster;
  Timer? _timer;
  bool _dirty = true;
  bool _captured = false;

  /// Whether the child is drawn from its raster.
  bool get hasRaster => _raster != null;

  double _devicePixelRatio;

  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void markNeedsPaint() {
    _drop();
    _dirty = true;
    super.markNeedsPaint();
  }

  void _drop() {
    _timer?.cancel();
    _timer = null;
    _raster?.dispose();
    _raster = null;
  }

  /// Takes the frame on screen, which this boundary's layer still holds.
  void _capture() {
    _timer = null;
    final layer = this.layer;
    if (!attached ||
        _dirty ||
        _raster != null ||
        !hasSize ||
        layer is! OffsetLayer) {
      return;
    }
    _raster = layer.toImageSync(
      Offset.zero & size,
      pixelRatio: _devicePixelRatio,
    );
    super.markNeedsPaint();
  }

  @override
  void detach() {
    _drop();
    super.detach();
  }

  @override
  void dispose() {
    _drop();
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _dirty = false;
    final raster = _raster;
    if (raster == null) {
      super.paint(context, offset);
      if (!_captured) {
        // The first paint is taken right after its frame, so a page sliding
        // in moves images rather than drawing every sketch on each frame.
        _captured = true;
        SchedulerBinding.instance.addPostFrameCallback((_) => _capture());
      } else {
        _timer ??= Timer(settle, _capture);
      }
      return;
    }
    context.canvas.drawImageRect(
      raster,
      Rect.fromLTWH(0, 0, raster.width.toDouble(), raster.height.toDouble()),
      offset & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }
}

enum _MiniPage { dashboard, proxies, profiles, tools }

/// A phone-shaped sketch of the home page, drawn in [colorScheme].
///
/// With [previous], the page is caught [progress] of the way through a switch
/// from it, drawn as [tabAnimation] moves the pages.
class MiniScreen extends StatelessWidget {
  const MiniScreen({
    super.key,
    required this.colorScheme,
    required this.floatingBar,
    this.liquidGlass = false,
    this.selected = 0,
    this.previous,
    this.progress = 1,
    this.tabAnimation = TabAnimation.slide,
    this.onSelect,
    this.starChart = false,
  });

  static const int destinationCount = 4;

  /// Draws the dashboard in the star-chart look.
  final bool starChart;

  final ColorScheme colorScheme;
  final bool floatingBar;

  /// Draws a floating bar as glass; a docked one stays a fill, as the app's
  /// does.
  final bool liquidGlass;

  final int selected;
  final int? previous;
  final double progress;
  final TabAnimation tabAnimation;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final sketch = SizedBox.expand(
      child: CustomPaint(
        painter: _MiniScreenPainter(
          colorScheme: colorScheme,
          floatingBar: floatingBar,
          liquidGlass: liquidGlass,
          selected: selected,
          previous: previous,
          progress: progress,
          tabAnimation: tabAnimation,
          starChart: starChart,
          glyphs: starChart ? starPlateGlyphs(context) : null,
        ),
      ),
    );
    final onSelect = this.onSelect;
    if (onSelect == null) {
      return sketch;
    }
    return LayoutBuilder(
      builder: (_, constraints) {
        final geometry = _MiniGeometry(
          constraints.biggest,
          floatingBar: floatingBar,
        );
        return Stack(
          children: [
            sketch,
            Positioned.fromRect(
              rect: geometry.bar,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < destinationCount; i++)
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(i),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class MiniSplitScreen extends StatelessWidget {
  const MiniSplitScreen({super.key, required this.light, required this.dark});

  final Widget light;
  final Widget dark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        light,
        ClipPath(clipper: _DiagonalClipper(), child: dark),
      ],
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_DiagonalClipper oldClipper) => false;
}

class _MiniGeometry {
  _MiniGeometry(this.size, {required bool floatingBar})
    : unit = size.width / 20 {
    margin = unit * 1.5;
    final barHeight = floatingBar ? unit * 3.2 : unit * 3.6;
    pageBottom = floatingBar ? 0 : barHeight;
    bar = floatingBar
        ? Rect.fromLTWH(
            margin,
            size.height - margin - barHeight,
            size.width - margin * 2,
            barHeight,
          )
        : Rect.fromLTWH(0, size.height - barHeight, size.width, barHeight);
  }

  final Size size;
  final double unit;
  late final double margin;
  late final double pageBottom;
  late final Rect bar;
}

class _MiniScreenPainter extends CustomPainter {
  const _MiniScreenPainter({
    required this.colorScheme,
    required this.floatingBar,
    required this.liquidGlass,
    required this.selected,
    required this.previous,
    required this.progress,
    required this.tabAnimation,
    required this.starChart,
    required this.glyphs,
  });

  final ColorScheme colorScheme;
  final bool floatingBar;
  final bool liquidGlass;
  final int selected;
  final int? previous;
  final double progress;
  final TabAnimation tabAnimation;
  final bool starChart;
  final TextStyle? glyphs;

  bool get _glass => floatingBar && liquidGlass;

  static _MiniPage _pageOf(int index) =>
      _MiniPage.values[index % _MiniPage.values.length];

  static void _fill(
    Canvas canvas,
    Rect rect,
    Color color,
    ShapeBorder shape, {
    List<BoxShadow>? shadows,
    MaskFilter? blur,
  }) {
    if (blur != null) {
      shape.paintInterior(
        canvas,
        rect,
        Paint()
          ..color = color
          ..maskFilter = blur,
      );
      return;
    }
    ShapeDecoration(color: color, shape: shape, shadows: shadows)
        .createBoxPainter(() {})
        .paint(canvas, rect.topLeft, ImageConfiguration(size: rect.size));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _MiniGeometry(size, floatingBar: floatingBar);
    _paintPages(canvas, geometry);
    final unit = geometry.unit;
    final dock = SurfaceLevel.floatingOf(colorScheme).colorOf(colorScheme);
    final shadow = BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.12),
      blurRadius: unit,
      offset: Offset(0, unit * 0.3),
    );
    if (_glass) {
      _paintGlassBar(canvas, geometry, shadow);
    } else if (floatingBar) {
      _fill(canvas, geometry.bar, dock, AppShape.full, shadows: [shadow]);
    } else {
      canvas.drawRect(geometry.bar, Paint()..color = dock);
    }
    _paintDestinations(canvas, geometry.bar, unit);
  }

  void _paintPages(Canvas canvas, _MiniGeometry geometry, {MaskFilter? blur}) {
    final size = geometry.size;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = SurfaceLevel.page.colorOf(colorScheme),
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size, doAntiAlias: false);
    final previous = this.previous;
    if (previous == null) {
      _paintPage(canvas, geometry, selected, 0, blur: blur);
    } else if (tabAnimation == TabAnimation.fade) {
      _paintPage(
        canvas,
        geometry,
        previous,
        0,
        opacity: 1 - progress,
        blur: blur,
      );
      _paintPage(canvas, geometry, selected, 0, opacity: progress, blur: blur);
    } else {
      final direction = previous > selected ? -1 : 1;
      _paintPage(
        canvas,
        geometry,
        previous,
        -direction * size.width * progress,
        blur: blur,
      );
      _paintPage(
        canvas,
        geometry,
        selected,
        direction * size.width * (1 - progress),
        blur: blur,
      );
    }
    canvas.restore();
  }

  /// The page frosted under a tint, ringed with light and casting its shadow
  /// only outside, after what [LiquidGlass] does at full size.
  void _paintGlassBar(Canvas canvas, _MiniGeometry geometry, BoxShadow shadow) {
    final bar = geometry.bar;
    final unit = geometry.unit;
    final path = AppShape.full.getOuterPath(bar);
    final style = LiquidGlassStyle.pill(colorScheme);
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(bar.inflate(unit * 3))
          ..addPath(path, Offset.zero),
      );
    AppShape.full.paintInterior(
      canvas,
      bar.shift(shadow.offset),
      shadow.toPaint(),
    );
    // Each shape blurs on its own in one pass, where a blurred layer would
    // cost an offscreen pass per sketch on every frame of the theme page.
    canvas
      ..restore()
      ..save()
      ..clipPath(path);
    _paintPages(
      canvas,
      geometry,
      blur: MaskFilter.blur(BlurStyle.normal, unit * 0.4),
    );
    final rimWidth = unit * 0.15;
    canvas
      ..drawPath(path, Paint()..color = style.tint)
      ..drawPath(
        AppShape.full.getOuterPath(bar.deflate(rimWidth / 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rimWidth
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: style.rim),
              Colors.white.withValues(alpha: style.rim * 0.15),
              Colors.white.withValues(alpha: style.rim * 0.5),
            ],
          ).createShader(bar),
      )
      ..restore();
  }

  void _paintPage(
    Canvas canvas,
    _MiniGeometry geometry,
    int index,
    double offset, {
    double opacity = 1,
    MaskFilter? blur,
  }) {
    final alpha = Color.getAlphaFromOpacity(opacity);
    if (alpha == 0) {
      return;
    }
    final size = geometry.size;
    final margin = geometry.margin;
    final content = Rect.fromLTRB(
      offset + margin,
      margin,
      offset + size.width - margin,
      size.height - geometry.pageBottom,
    );
    if (alpha < 255) {
      canvas.saveLayer(null, Paint()..color = Color.fromARGB(alpha, 0, 0, 0));
    } else {
      canvas.save();
    }
    canvas.clipRect(content, doAntiAlias: false);
    _PageSketch(
      canvas,
      colorScheme,
      geometry.unit,
      content,
      blur: blur,
      glyphs: glyphs,
    ).paint(_pageOf(index));
    canvas.restore();
  }

  void _paintDestinations(Canvas canvas, Rect bar, double unit) {
    final cell = bar.width / MiniScreen.destinationCount;
    final dark = colorScheme.brightness == Brightness.dark;
    final indicator = _glass
        ? colorScheme.onSurface.withValues(alpha: dark ? 0.14 : 0.08)
        : SurfaceLevel.floatingOf(colorScheme).next.colorOf(colorScheme);
    for (var i = 0; i < MiniScreen.destinationCount; i++) {
      final center = Offset(bar.left + cell * i + cell / 2, bar.center.dy);
      final icon = center.translate(0, -unit * 0.4);
      final isSelected = i == selected;
      if (isSelected) {
        _fill(
          canvas,
          floatingBar
              ? Rect.fromCenter(
                  center: center,
                  width: cell - unit * 0.5,
                  height: bar.height - unit * 0.5,
                )
              : Rect.fromCenter(
                  center: icon,
                  width: unit * 2.8,
                  height: unit * 1.5,
                ),
          indicator,
          AppShape.full,
        );
      }
      final ink = isSelected
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant;
      _fill(
        canvas,
        Rect.fromCircle(center: icon, radius: unit * 0.45),
        ink,
        AppShape.circle,
      );
      _fill(
        canvas,
        Rect.fromCenter(
          center: center.translate(0, unit * 0.8),
          width: unit * 1.7,
          height: unit * 0.35,
        ),
        isSelected ? ink : ink.withValues(alpha: 0.6),
        AppShape.full,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniScreenPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.floatingBar != floatingBar ||
        oldDelegate.liquidGlass != liquidGlass ||
        oldDelegate.selected != selected ||
        oldDelegate.previous != previous ||
        oldDelegate.progress != progress ||
        oldDelegate.tabAnimation != tabAnimation ||
        oldDelegate.starChart != starChart ||
        oldDelegate.glyphs != glyphs;
  }
}

/// One page of a [MiniScreen] after the app's own, laid out in units of a
/// twentieth of the screen's width from the top left of [content].
class _PageSketch {
  _PageSketch(
    this.canvas,
    this.colorScheme,
    this.unit,
    this.content, {
    this.blur,
    this.glyphs,
  }) : width = content.width / unit,
       card = SurfaceLevel.card.colorOf(colorScheme),
       inset = SurfaceLevel.inset.colorOf(colorScheme),
       text = colorScheme.onSurface.withValues(alpha: 0.72),
       line = colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
       faint = colorScheme.onSurfaceVariant.withValues(alpha: 0.16);

  static const double _gap = 0.6;

  final Canvas canvas;
  final ColorScheme colorScheme;
  final double unit;
  final Rect content;
  final MaskFilter? blur;

  /// The star plate's face; set when the sketch wears the star-chart look.
  final TextStyle? glyphs;
  final double width;

  bool get starChart => glyphs != null;
  final Color card;
  final Color inset;
  final Color text;
  final Color line;
  final Color faint;

  void paint(_MiniPage page) {
    switch (page) {
      case _MiniPage.dashboard:
        _dashboard(_header(actions: 1));
      case _MiniPage.proxies:
        _proxies(_header(actions: 2));
      case _MiniPage.profiles:
        _profiles(_header(actions: 2));
      case _MiniPage.tools:
        _tools(_header(actions: 0));
    }
  }

  Rect _rect(double x, double y, double w, double h) => Rect.fromLTWH(
    content.left + x * unit,
    content.top + y * unit,
    w * unit,
    h * unit,
  );

  ShapeBorder _shape(double extent) =>
      AppShape.all(AppCorner.fit(unit * extent));

  void _block(Rect rect, Color color, {double extent = 5}) {
    _MiniScreenPainter._fill(canvas, rect, color, _shape(extent), blur: blur);
    if (starChart && color == card) {
      final hairline = StarChartColors.hairlineOf(colorScheme.brightness);
      final inset = unit * 0.25;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..maskFilter = blur;
      canvas
        ..drawPath(
          _shape(extent).getOuterPath(rect.deflate(0.4)),
          stroke
            ..strokeWidth = 0.8
            ..color = hairline,
        )
        ..drawPath(
          _shape(extent).getOuterPath(rect.deflate(inset)),
          stroke
            ..strokeWidth = 0.5
            ..color = hairline.withValues(alpha: hairline.a * 0.7),
        );
    }
  }

  void _pill(double x, double y, double w, double h, Color color) {
    _MiniScreenPainter._fill(
      canvas,
      _rect(x, y, w, h),
      color,
      AppShape.full,
      blur: blur,
    );
  }

  void _dot(double x, double y, double radius, Color color) {
    _MiniScreenPainter._fill(
      canvas,
      _rect(x - radius, y - radius, radius * 2, radius * 2),
      color,
      AppShape.circle,
      blur: blur,
    );
  }

  /// The title and the bar's round buttons; returns where the body starts.
  double _header({required int actions}) {
    _pill(0, 0.45, 7, 1.1, text);
    for (var i = 0; i < actions; i++) {
      final x = width - 1 - i * 2.4;
      _dot(x, 1, 1, card);
      _dot(x, 1, 0.3, line);
    }
    return 2.8;
  }

  void _dashboard(double top) {
    if (starChart) {
      final sky = Rect.fromLTRB(
        content.left - unit * 1.5,
        content.top - unit * 1.5,
        content.right + unit * 1.5,
        content.bottom,
      );
      canvas
        ..save()
        ..translate(sky.left, sky.top);
      StarChartBackdropPainter(
        brightness: colorScheme.brightness,
        lit: 1,
        detail: unit / 20,
      ).paint(canvas, sky.size);
      canvas.restore();
    }
    var y = top;
    final status = _rect(0, y, width, 6.2);
    final buttonX = width - 3;
    final buttonY = y + 3.1;
    _block(status, card);
    if (starChart) {
      final dark = colorScheme.brightness == Brightness.dark;
      paintStarPlate(
        canvas,
        _rect(buttonX - 0.2, buttonY, 0, 0).topLeft,
        unit * 2.8,
        brightness: colorScheme.brightness,
        lit: 1,
        turn: 0,
        disc: dark ? const Color(0xFF262335) : const Color(0xFFFFF9EA),
        error: colorScheme.error,
        glyphs: glyphs!,
      );
    } else {
      canvas
        ..save()
        ..clipPath(_shape(5).getOuterPath(status));
      // The pole star's halo, as behind the running dashboard's button.
      paintPoleStar(
        canvas,
        _rect(buttonX, buttonY, 0, 0).topLeft,
        unit * 4.6,
        field: colorScheme.primary.withValues(alpha: 0.1),
        lit: 1,
        turn: 0,
        dark: colorScheme.brightness == Brightness.dark,
      );
      canvas.restore();
      _dot(buttonX, buttonY, 1.8, colorScheme.primary);
      for (final dx in [-0.675, 0.325]) {
        _pill(buttonX + dx, buttonY - 0.6, 0.35, 1.2, colorScheme.onPrimary);
      }
    }
    _pill(1, y + 0.9, 3, 0.7, line);
    _dot(1.9, y + 3, 0.9, inset);
    _pill(3.5, y + 2.3, 5, 0.9, text);
    _pill(3.5, y + 3.5, 2.4, 0.7, inset);
    _pill(1, y + 4.8, 2.4, 0.7, line);
    _pill(4.6, y + 4.8, 3.6, 0.7, line);
    y += 6.2 + _gap;

    // One Northern Dipper for both directions, laid out as the phone card
    // lays it: the upload's figure over its handle, the download's under its
    // bowl.
    final span = width - 2;
    final gaugeTop = y + 2.3;
    final downloadTop = gaugeTop + span * dipperRoomUnderBowl;
    final blockHeight = downloadTop + 2.4 - y;
    _block(_rect(0, y, width, blockHeight), card);
    _pill(1, y + 0.9, 4.5, 0.7, line);
    paintDipper(
      canvas,
      _rect(1, gaugeTop, span, span * dipperBoxDepth),
      level: 0.6,
      download: 0.8,
      dark: colorScheme.brightness == Brightness.dark,
      starScaleCap: span * unit * 0.5,
    );
    _pill(1, gaugeTop, 2, 0.6, line);
    _pill(1, gaugeTop + 0.9, 3.6, 1, text);
    _pill(width - 3, downloadTop, 2, 0.6, line);
    _pill(width - 4.6, downloadTop + 0.9, 3.6, 1, text);
    y += blockHeight + _gap;

    _block(_rect(0, y, width, 4.4), card);
    _pill(1, y + 0.9, 4, 0.7, line);
    final segment = (width - 2.6) / 3;
    for (var i = 0; i < 3; i++) {
      final x = 1 + i * (segment + 0.3);
      _pill(x, y + 2.1, segment, 1.6, i == 0 ? colorScheme.primary : inset);
      _dot(
        x + segment / 2,
        y + 2.9,
        0.3,
        i == 0 ? colorScheme.onPrimary : line,
      );
    }
    y += 4.4 + _gap;

    _block(_rect(0, y, width, 3), card);
    _dot(1.9, y + 1.5, 0.9, colorScheme.primary);
    _pill(3.4, y + 1.1, 2.4, 0.8, line);
    if (starChart) {
      final gilt = StarChartColors.giltOf(colorScheme.brightness);
      _pill(
        width - 3.6,
        y + 0.8,
        2.6,
        1.4,
        Color.alphaBlend(gilt.withValues(alpha: 0.22), inset),
      );
      _pill(width - 3.3, y + 1.45, 2, 0.1, gilt.withValues(alpha: 0.75));
      _dot(width - 1.7, y + 1.5, 0.5, gilt);
    } else {
      _pill(width - 3.6, y + 0.8, 2.6, 1.4, colorScheme.primary);
      _dot(width - 1.7, y + 1.5, 0.55, colorScheme.onPrimary);
    }
    y += 3 + _gap;

    for (var i = 0; i < 3; i++) {
      _block(_rect(0, y, width, 4.5), card);
      _pill(1, y + 0.9, 3.5 + i % 2, 0.7, line);
      y += 4.5 + _gap;
    }
  }

  void _proxies(double top) {
    var y = top;
    for (var i = 0; i < 9; i++) {
      _block(_rect(0, y, width, 2.6), card);
      _dot(1.5, y + 1.3, 0.8, inset);
      _pill(3, y + 0.6, 3 + i % 3, 0.7, line);
      _pill(3, y + 1.55, 4, 0.5, faint);
      _pill(width - 4.4, y + 1.05, 1.8, 0.5, faint);
      _dot(width - 1.3, y + 1.3, 0.55, inset);
      y += 2.6 + _gap;
    }
  }

  void _profiles(double top) {
    var y = top;
    for (var i = 0; i < 3; i++) {
      _block(_rect(0, y, width, 2.8), card);
      _pill(1, y + 0.7, 3.4 - i * 0.6, 0.75, line);
      _pill(
        4.8 - i * 0.6,
        y + 0.72,
        2.6,
        0.7,
        colorScheme.primary.withValues(alpha: 0.16),
      );
      _pill(1, y + 1.7, 3, 0.5, faint);
      _pill(width - 4.1, y + 1.15, 1.6, 0.5, faint);
      if (i == 0) {
        _dot(width - 1.4, y + 1.4, 0.6, colorScheme.primary);
      }
      y += 2.8 + _gap;
    }
  }

  void _tools(double top) {
    const rowHeight = 2.4;
    var y = top;
    for (final rows in [4, 7]) {
      _pill(0.8, y + 0.2, 1.6 + rows * 0.15, 0.5, faint);
      y += 1.3;
      _block(_rect(0, y, width, rows * rowHeight), card);
      for (var i = 0; i < rows; i++) {
        final row = y + i * rowHeight;
        _dot(1.3, row + rowHeight / 2, 0.45, line);
        _pill(2.6, row + 0.85, 4 + (i * 3 + rows) % 4, 0.7, line);
        if (i < rows - 1) {
          canvas.drawRect(
            _rect(2.6, row + rowHeight - 0.03, width - 3.4, 0.06),
            Paint()
              ..color = faint
              ..maskFilter = blur,
          );
        }
      }
      y += rows * rowHeight + _gap * 2;
    }
  }
}
