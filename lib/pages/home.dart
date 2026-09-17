import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/manager/app_manager.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

typedef OnSelected = void Function(int index);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _handleToPage(PageLabel pageLabel) {
    globalState.container
        .read(currentPageLabelProvider.notifier)
        .toPage(pageLabel);
  }

  @override
  Widget build(BuildContext context) {
    return HomeBackScopeContainer(
      child: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          AppSidebarContainer(
            child: Material(
              color: Colors.transparent,
              child: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(navigationStateProvider);
                  final isMobile = state.viewMode == ViewMode.mobile;
                  final navigationItems = state.navigationItems;
                  final currentIndex = state.currentIndex;
                  final bottomNavigationBar = Container(
                    decoration: const BoxDecoration(
                      color: EditorialPalette.paper,
                      border: Border(
                        top: BorderSide(color: EditorialPalette.hairline),
                      ),
                    ),
                    child: NavigationBarTheme(
                      data: _NavigationBarDefaultsM3(context),
                      child: NavigationBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        destinations: navigationItems
                            .map(
                              (e) => NavigationDestination(
                                icon: e.icon,
                                selectedIcon: e.icon,
                                label: Intl.message(e.label.name),
                              ),
                            )
                            .toList(),
                        onDestinationSelected: (index) {
                          _handleToPage(navigationItems[index].label);
                        },
                        selectedIndex: currentIndex,
                      ),
                    ),
                  );
                  if (isMobile) {
                    return Column(
                      children: [
                        Flexible(
                          flex: 1,
                          child: MediaQuery.removePadding(
                            removeTop: false,
                            removeBottom: true,
                            removeLeft: true,
                            removeRight: true,
                            context: context,
                            child: child!,
                          ),
                        ),
                        MediaQuery.removePadding(
                          removeTop: true,
                          removeBottom: false,
                          removeLeft: true,
                          removeRight: true,
                          context: context,
                          child: bottomNavigationBar,
                        ),
                      ],
                    );
                  } else {
                    return child!;
                  }
                },
                child: Consumer(
                  builder: (_, ref, _) {
                    final navigationItems = ref
                        .watch(currentNavigationItemsStateProvider)
                        .value;
                    final isMobile = ref.watch(isMobileViewProvider);
                    return _HomePageView(
                      navigationItems: navigationItems,
                      pageBuilder: (_, index) {
                        final navigationItem = navigationItems[index];
                        final navigationView = navigationItem.builder(context);
                        final view = KeepScope(
                          keep: navigationItem.keep,
                          child: isMobile
                              ? navigationView
                              : Navigator(
                                  pages: [MaterialPage(child: navigationView)],
                                  onDidRemovePage: (_) {},
                                ),
                        );
                        return view;
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePageView extends ConsumerStatefulWidget {
  final IndexedWidgetBuilder pageBuilder;
  final List<NavigationItem> navigationItems;

  const _HomePageView({
    required this.pageBuilder,
    required this.navigationItems,
  });

  @override
  ConsumerState createState() => _HomePageViewState();
}

// Matches upstream FlClash's tab-switch timing (kTabScrollDuration +
// Curves.easeOut) rather than the app's iOS-style push-route curve — this
// animation now only ever runs on mobile (see _toPage), where it competes
// every frame with the bottom NavigationBar's always-on BackdropFilter
// blur for GPU time, so it stays on the cheaper, well-trodden curve instead
// of a bespoke one.
const _kPageTransitionDuration = kTabScrollDuration;
const _kPageTransitionCurve = Curves.easeOut;

class _HomePageViewState extends ConsumerState<_HomePageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndex);
    ref.listenManual(currentPageLabelProvider, (prev, next) {
      if (prev != next) {
        _toPage(next);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HomePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationItems.length != widget.navigationItems.length) {
      _updatePageController();
    }
  }

  int get _pageIndex {
    final pageLabel = ref.read(currentPageLabelProvider);
    return widget.navigationItems.indexWhere((item) => item.label == pageLabel);
  }

  Future<void> _toPage(
    PageLabel pageLabel, [
    bool ignoreAnimateTo = false,
  ]) async {
    if (!mounted) {
      return;
    }
    final index = widget.navigationItems.indexWhere(
      (item) => item.label == pageLabel,
    );
    if (index == -1) {
      return;
    }
    final isAnimateToPage = ref.read(appSettingProvider).isAnimateToPage;
    // Upstream FlClash only animates this switch on mobile (a touch-driven
    // tab bar reads naturally as a slide) and jumps instantly everywhere
    // else. This fork had dropped the isMobile check, so every desktop
    // nav-rail click paid for a 320ms slide+cross-fade over glass/blur-heavy
    // pages instead of the instant switch users expect from mouse/keyboard
    // navigation — that's the "switching feels laggy" regression.
    final isMobile = ref.read(isMobileViewProvider);
    if (isAnimateToPage && isMobile && !ignoreAnimateTo) {
      await _pageController.animateToPage(
        index,
        duration: _kPageTransitionDuration,
        curve: _kPageTransitionCurve,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  void _updatePageController() {
    final pageLabel = ref.read(currentPageLabelProvider);
    _toPage(pageLabel, true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = ref.watch(
      currentNavigationItemsStateProvider.select((state) => state.value.length),
    );
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // No manual cross-fade here (there used to be one, via
        // AnimatedBuilder + Opacity tracking _pageController): this switch
        // only ever animates on mobile now (see _toPage), where every one
        // of its ~18 frames had to alpha-composite two full pages worth of
        // BackdropFilter glass on top of the slide PageView already does
        // for free. Upstream FlClash doesn't cross-fade this transition
        // either — a plain slide reads fine and is the difference between
        // this feeling instant and feeling laggy on real phones. The
        // RepaintBoundary still earns its keep: it caches each page as one
        // rasterized layer so the slide only ever costs a cheap
        // compositor-side translate instead of repainting glass on every
        // frame.
        return RepaintBoundary(child: widget.pageBuilder(context, index));
      },
    );
  }
}

class _NavigationBarDefaultsM3 extends NavigationBarThemeData {
  _NavigationBarDefaultsM3(this.context)
    : super(
        height: kHomeNavigationBarHeight,
        elevation: 3.0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      );

  final BuildContext context;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  // The surrounding Container (see HomePage) already paints the flat
  // paper background + hairline border, so this stays transparent.
  @override
  Color? get backgroundColor => Colors.transparent;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get surfaceTintColor => Colors.transparent;

  @override
  WidgetStateProperty<IconThemeData?>? get iconTheme {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      return IconThemeData(
        size: 24.0,
        color: states.contains(WidgetState.disabled)
            ? EditorialPalette.muted.opacity38
            : states.contains(WidgetState.selected)
            ? EditorialPalette.accent
            : EditorialPalette.muted,
      );
    });
  }

  @override
  Color? get indicatorColor => EditorialPalette.accent.opacity12;

  @override
  ShapeBorder? get indicatorShape => const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  @override
  WidgetStateProperty<TextStyle?>? get labelTextStyle {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      final TextStyle style = _textTheme.labelMedium!;
      return style.apply(
        overflow: TextOverflow.ellipsis,
        color: states.contains(WidgetState.disabled)
            ? EditorialPalette.muted.opacity38
            : states.contains(WidgetState.selected)
            ? EditorialPalette.ink
            : EditorialPalette.muted,
      );
    });
  }
}

class HomeBackScopeContainer extends ConsumerWidget {
  final Widget child;

  const HomeBackScopeContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, ref) {
    return CommonPopScope(
      onPop: (context) async {
        final pageLabel = ref.read(currentPageLabelProvider);
        final realContext =
            GlobalObjectKey(pageLabel).currentContext ?? context;
        final canPop = Navigator.canPop(realContext);
        if (canPop) {
          Navigator.of(realContext).pop();
        } else {
          await globalState.container
              .read(systemActionProvider.notifier)
              .handleClose();
        }
        return false;
      },
      child: child,
    );
  }
}
