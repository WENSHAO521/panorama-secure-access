import 'package:animations/animations.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/glass.dart';
import 'package:flutter/material.dart';

class BaseNavigator {
  static Future<T?> push<T>(BuildContext context, Widget child) async {
    if (!globalState.container.read(isMobileViewProvider)) {
      return Navigator.of(
        context,
      ).push<T>(CommonDesktopRoute(builder: (context) => child));
    }
    return Navigator.of(
      context,
    ).push<T>(CommonRoute(builder: (context) => child));
  }

  // static Future<T?> modal<T>(BuildContext context, Widget child) async {
  //   if (globalState.appState.viewMode != ViewMode.mobile) {
  //     return await globalState.showCommonDialog<T>(
  //       child: CommonModal(
  //         child: child,
  //       ),
  //     );
  //   }
  //   return await Navigator.of(context).push<T>(
  //     CommonRoute(
  //       builder: (context) => child,
  //     ),
  //   );
  // }
}

const commonSharedXPageTransitions = SharedAxisPageTransitionsBuilder(
  transitionType: SharedAxisTransitionType.horizontal,
  fillColor: Colors.transparent,
);

class CommonDesktopRoute<T> extends PageRoute<T> {
  final Widget Function(BuildContext context) builder;

  CommonDesktopRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  // The route's own Scaffold background is transparent (see
  // scaffoldBackgroundColor in application.dart) so its glass surfaces read
  // against an ambient backdrop — but buildPage below now paints that
  // backdrop itself, so this route is fully opaque and Flutter can safely
  // offstage whatever sits behind it once the push transition finishes.
  @override
  bool get opaque => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // AmbientBackground must sit outside the FadeTransition, not inside it.
    // Because this route is opaque, Flutter stops painting whatever sits
    // behind it as soon as it's pushed — it doesn't wait for the transition
    // to finish. If the background were part of the faded subtree, the very
    // first frames (animation value near 0) would paint neither the old
    // route (offstaged already) nor the new one (still near-transparent),
    // flashing the bare window colour. Keeping it outside means this route
    // paints a fully opaque backdrop from frame one; only the page content
    // on top fades in.
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          FadeTransition(opacity: animation, child: builder(context)),
        ],
      ),
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);
}

class CommonRoute<T> extends PageRoute<T> {
  final Widget Function(BuildContext context) builder;

  CommonRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  // Mobile has no per-tab nested Navigator (see _HomePageView), so pushing
  // here goes on the root Navigator directly below HomePage. buildPage below
  // paints its own AmbientBackground rather than relying on HomePage's
  // showing through, so this route is fully opaque and Flutter can safely
  // offstage HomePage once the push transition finishes.
  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // See CommonDesktopRoute.buildPage: AmbientBackground must stay outside
    // the SharedAxisTransition. This route is opaque, so Flutter stops
    // painting HomePage underneath as soon as this route is pushed, not
    // once the transition settles — if the background were inside the
    // transition too, the near-transparent early frames would show neither
    // page and flash the bare window colour. Keeping it outside means this
    // route is fully opaque from frame one; only the page content slides in.
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Colors.transparent,
            child: builder(context),
          ),
        ],
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);
}

final Animatable<Offset> _kRightMiddleTween = Tween<Offset>(
  begin: const Offset(1.0, 0.0),
  end: Offset.zero,
);
final Animatable<Offset> _kMiddleLeftTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(-1.0 / 3.0, 0.0),
);

class CommonPageTransitionsBuilder extends PageTransitionsBuilder {
  const CommonPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CommonPageTransition(
      context: context,
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  }
}

class CommonPageTransition extends StatefulWidget {
  const CommonPageTransition({
    super.key,
    required this.context,
    required this.primaryRouteAnimation,
    required this.secondaryRouteAnimation,
    required this.child,
    required this.linearTransition,
  });

  final Widget child;

  final Animation<double> primaryRouteAnimation;

  final Animation<double> secondaryRouteAnimation;

  final BuildContext context;

  final bool linearTransition;

  static Widget? delegatedTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    final CurvedAnimation animation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.easeInToLinear,
    );
    final Animation<Offset> delegatedPositionAnimation = animation.drive(
      _kMiddleLeftTween,
    );
    animation.dispose();

    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    return SlideTransition(
      position: delegatedPositionAnimation,
      textDirection: textDirection,
      transformHitTests: false,
      child: child,
    );
  }

  @override
  State<CommonPageTransition> createState() => _CommonPageTransitionState();
}

class _CommonPageTransitionState extends State<CommonPageTransition> {
  late Animation<Offset> _primaryPositionAnimation;
  late Animation<Offset> _secondaryPositionAnimation;
  late Animation<Decoration> _primaryShadowAnimation;
  CurvedAnimation? _primaryPositionCurve;
  CurvedAnimation? _secondaryPositionCurve;
  CurvedAnimation? _primaryShadowCurve;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant CommonPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryRouteAnimation != widget.primaryRouteAnimation ||
        oldWidget.secondaryRouteAnimation != widget.secondaryRouteAnimation ||
        oldWidget.linearTransition != widget.linearTransition) {
      _disposeCurve();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _disposeCurve();
    super.dispose();
  }

  void _disposeCurve() {
    _primaryPositionCurve?.dispose();
    _secondaryPositionCurve?.dispose();
    _primaryShadowCurve?.dispose();
    _primaryPositionCurve = null;
    _secondaryPositionCurve = null;
    _primaryShadowCurve = null;
  }

  void _setupAnimation() {
    if (!widget.linearTransition) {
      _primaryPositionCurve = CurvedAnimation(
        parent: widget.primaryRouteAnimation,
        curve: Curves.fastEaseInToSlowEaseOut,
        reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
      );
      _secondaryPositionCurve = CurvedAnimation(
        parent: widget.secondaryRouteAnimation,
        curve: Curves.linearToEaseOut,
        reverseCurve: Curves.easeInToLinear,
      );
      _primaryShadowCurve = CurvedAnimation(
        parent: widget.primaryRouteAnimation,
        curve: Curves.linearToEaseOut,
      );
    }
    _primaryPositionAnimation =
        (_primaryPositionCurve ?? widget.primaryRouteAnimation).drive(
          _kRightMiddleTween,
        );
    _secondaryPositionAnimation =
        (_secondaryPositionCurve ?? widget.secondaryRouteAnimation).drive(
          _kMiddleLeftTween,
        );
    _primaryShadowAnimation =
        (_primaryShadowCurve ?? widget.primaryRouteAnimation).drive(
          DecorationTween(
            begin: const _CommonEdgeShadowDecoration(),
            end: const _CommonEdgeShadowDecoration(<Color>[
              Color(0x04000000),
              Colors.transparent,
            ]),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    return SlideTransition(
      position: _secondaryPositionAnimation,
      textDirection: textDirection,
      transformHitTests: false,
      child: SlideTransition(
        position: _primaryPositionAnimation,
        textDirection: textDirection,
        child: DecoratedBoxTransition(
          decoration: _primaryShadowAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

class _CommonEdgeShadowDecoration extends Decoration {
  final List<Color>? _colors;

  const _CommonEdgeShadowDecoration([this._colors]);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CommonEdgeShadowPainter(this, onChanged);
  }
}

class _CommonEdgeShadowPainter extends BoxPainter {
  _CommonEdgeShadowPainter(this._decoration, super.onChanged)
    : assert(_decoration._colors == null || _decoration._colors.length > 1);

  final _CommonEdgeShadowDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final List<Color>? colors = _decoration._colors;
    if (colors == null) {
      return;
    }

    final double shadowWidth = 0.05 * configuration.size!.width;
    final double shadowHeight = configuration.size!.height;
    final double bandWidth = shadowWidth / (colors.length - 1);

    final TextDirection? textDirection = configuration.textDirection;
    assert(textDirection != null);
    final (double shadowDirection, double start) = switch (textDirection!) {
      TextDirection.rtl => (1, offset.dx + configuration.size!.width),
      TextDirection.ltr => (-1, offset.dx),
    };

    int bandColorIndex = 0;
    for (int dx = 0; dx < shadowWidth; dx += 1) {
      if (dx ~/ bandWidth != bandColorIndex) {
        bandColorIndex += 1;
      }
      final Paint paint = Paint()
        ..color = Color.lerp(
          colors[bandColorIndex],
          colors[bandColorIndex + 1],
          (dx % bandWidth) / bandWidth,
        )!;
      final double x = start + shadowDirection * dx;
      canvas.drawRect(
        Rect.fromLTWH(x - 1.0, offset.dy, 1.0, shadowHeight),
        paint,
      );
    }
  }
}
