import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Brief §102: a development-time count of the blurs on screen.
///
/// Off unless the debug build is started with
/// `--dart-define=PANORAMA_BLUR_AUDIT=true`; compiled out of release builds.
const blurAuditEnabled =
    kDebugMode && bool.fromEnvironment('PANORAMA_BLUR_AUDIT');

/// The number of [BackdropFilterLayer]s the last frame composited: the
/// blurs the engine actually ran, so offstage subtrees and pages kept alive
/// offscreen don't count. Debug builds only (layers aren't reachable from
/// outside the render object otherwise); returns 0 in other modes.
int visibleBackdropFilters([Iterable<RenderView>? views]) {
  var count = 0;
  void visit(Layer? layer) {
    while (layer != null) {
      if (layer is BackdropFilterLayer) count++;
      if (layer is ContainerLayer) visit(layer.firstChild);
      layer = layer.nextSibling;
    }
  }

  for (final view in views ?? RendererBinding.instance.renderViews) {
    visit(view.debugLayer);
  }
  return count;
}

/// Shows [visibleBackdropFilters] in a corner when [blurAuditEnabled].
/// Samples after frames the app draws anyway; it never schedules one.
class BlurAuditOverlay extends StatefulWidget {
  final Widget child;

  const BlurAuditOverlay({super.key, required this.child});

  @override
  State<BlurAuditOverlay> createState() => _BlurAuditOverlayState();
}

class _BlurAuditOverlayState extends State<BlurAuditOverlay> {
  final _count = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    if (blurAuditEnabled) {
      SchedulerBinding.instance.addPostFrameCallback(_sample);
    }
  }

  void _sample(Duration _) {
    if (!mounted) return;
    _count.value = visibleBackdropFilters();
    SchedulerBinding.instance.addPostFrameCallback(_sample);
  }

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!blurAuditEnabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 4,
          bottom: 4,
          child: IgnorePointer(
            child: ValueListenableBuilder(
              valueListenable: _count,
              builder: (_, count, _) => BlurAuditBadge(count: count),
            ),
          ),
        ),
      ],
    );
  }
}

class BlurAuditBadge extends StatelessWidget {
  final int count;

  const BlurAuditBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    // Developer tooling, not product UI: fixed high-contrast colours so it
    // reads over any theme.
    return ColoredBox(
      color: const Color(0xCC000000),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'visibleBackdropFilters: $count',
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11),
        ),
      ),
    );
  }
}
