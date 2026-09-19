import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/overview.dart';

typedef _IsEditWidgetBuilder = Widget Function(bool isEdit);

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final key = GlobalKey<SuperGridState>();
  final _isEditNotifier = ValueNotifier<bool>(false);
  final _addedWidgetsNotifier = ValueNotifier<List<GridItem>>([]);

  @override
  void dispose() {
    _isEditNotifier.dispose();
    _addedWidgetsNotifier.dispose();
    super.dispose();
  }

  Widget _buildIsEdit(_IsEditWidgetBuilder builder) {
    return ValueListenableBuilder(
      valueListenable: _isEditNotifier,
      builder: (_, isEdit, _) {
        return builder(isEdit);
      },
    );
  }

  Future<void> _handleConnection() async {
    final coreStatus = ref.read(coreStatusProvider);
    if (coreStatus == CoreStatus.connecting) {
      return;
    }
    final tip = coreStatus == CoreStatus.connected
        ? context.appLocalizations.forceRestartCoreTip
        : context.appLocalizations.restartCoreTip;
    final res = await globalState.showMessage(message: TextSpan(text: tip));
    if (res != true) {
      return;
    }
    globalState.container.read(coreActionProvider.notifier).restartCore();
  }

  List<Widget> _buildActions(bool isEdit) {
    return [
      if (!isEdit)
        Consumer(
          builder: (_, ref, _) {
            final coreStatus = ref.watch(coreStatusProvider);
            return _ConnectionStatusBadge(
              coreStatus: coreStatus,
              onPressed: _handleConnection,
            );
          },
        ),
      if (isEdit)
        ValueListenableBuilder(
          valueListenable: _addedWidgetsNotifier,
          builder: (_, addedChildren, child) {
            if (addedChildren.isEmpty) {
              return Container();
            }
            return child!;
          },
          child: IconButton(
            onPressed: () {
              _showAddWidgetsModal();
            },
            icon: const Icon(Icons.add_circle),
          ),
        ),
      FadeRotationScaleBox(
        child: isEdit
            ? IconButton(
                key: const ValueKey(true),
                icon: const Icon(Icons.save, key: ValueKey('save-icon')),
                onPressed: _handleUpdateIsEdit,
              )
            : IconButton(
                key: const ValueKey(false),
                icon: const Icon(Icons.edit, key: ValueKey('edit-icon')),
                onPressed: _handleUpdateIsEdit,
              ),
      ),
    ];
  }

  AppBar _buildDashboardAppBar({required bool isEdit}) {
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    final profile = ref.watch(currentProfileProvider);
    final themeLabel = colorScheme.brightness == Brightness.dark
        ? appLocalizations.dark
        : appLocalizations.light;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 36,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Text(
            appLocalizations.dashboardActiveProfile,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.statusConnected,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              profile?.realLabel ?? appLocalizations.profile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 19,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                colorScheme.brightness == Brightness.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                themeLabel,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 19,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        ..._buildActions(isEdit),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          height: 1,
        ),
      ),
    );
  }

  void _showAddWidgetsModal() {
    showSheet(
      builder: (_) {
        return ValueListenableBuilder(
          valueListenable: _addedWidgetsNotifier,
          builder: (_, value, _) {
            return AdaptiveSheetScaffold(
              body: _AddDashboardWidgetModal(
                items: value,
                onAdd: (gridItem) {
                  key.currentState?.handleAdd(gridItem);
                },
              ),
              title: context.appLocalizations.add,
            );
          },
        );
      },
      context: context,
    );
  }

  Future<void> _handleUpdateIsEdit() async {
    if (_isEditNotifier.value == true) {
      await _handleSave();
    }
    _isEditNotifier.value = !_isEditNotifier.value;
  }

  Future<void> _handleSave() async {
    final currentState = key.currentState;
    if (currentState == null) {
      return;
    }
    if (mounted && currentState.children.isNotEmpty) {
      await currentState.isTransformCompleter;
      final dashboardWidgets = currentState.children
          .map((item) => DashboardWidget.getDashboardWidget(item))
          .toList();
      ref
          .read(appSettingProvider.notifier)
          .update(
            (state) => state.copyWith(dashboardWidgets: dashboardWidgets),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardStateProvider);
    final columns = max(4 * ((dashboardState.contentWidth / 280).ceil()), 8);
    final spacing = 14.mAp;
    final children = [
      ...dashboardState.dashboardWidgets
          .where(
            (item) => item.platforms.contains(SupportPlatform.currentPlatform),
          )
          .map((item) => item.widget),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addedWidgetsNotifier.value = DashboardWidget.values
          .where(
            (item) =>
                !children.contains(item.widget) &&
                item.platforms.contains(SupportPlatform.currentPlatform),
          )
          .map((item) => item.widget)
          .toList();
    });
    return _buildIsEdit(
      (isEdit) => CommonScaffold(
        appBar: _buildDashboardAppBar(isEdit: isEdit),
        body: isEdit
            ? Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 88),
                  child: SystemBackBlock(
                    child: CommonPopScope(
                      child: SuperGrid(
                        key: key,
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        children: children,
                        onUpdate: () {
                          _handleSave();
                        },
                      ),
                      onPop: (context) {
                        _handleUpdateIsEdit();
                        return false;
                      },
                    ),
                  ),
                ),
              )
            : const DashboardOverview(),
      ),
    );
  }
}

/// Compact AppBar-scale connection-status control shown beside the Dashboard
/// edit action. Deliberately small (matches the neighbouring [IconButton]'s
/// hit area) and tinted rather than solid-filled, so it reads as glass
/// status chrome instead of a standalone success badge.
class _ConnectionStatusBadge extends StatelessWidget {
  static const double _hitSize = 44;
  static const double _badgeSize = 40;

  final CoreStatus coreStatus;
  final VoidCallback onPressed;

  const _ConnectionStatusBadge({
    required this.coreStatus,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final String tooltip;
    final Color tint;
    final double tintAlpha;
    final BorderSide border;
    final List<BoxShadow>? glow;
    final Color iconColor;
    final Widget icon;

    switch (coreStatus) {
      case CoreStatus.connected:
        tooltip = appLocalizations.connected;
        tint = colorScheme.statusConnected;
        tintAlpha = isDark ? 0.14 : 0.10;
        border = BorderSide(
          color: colorScheme.statusConnected.withValues(
            alpha: isDark ? 0.37 : 0.28,
          ),
        );
        glow = [
          BoxShadow(
            color: colorScheme.statusConnected.withValues(
              alpha: isDark ? 0.10 : 0.06,
            ),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ];
        iconColor = colorScheme.statusConnected;
        icon = const Icon(Icons.check_rounded, size: 24);
        break;
      case CoreStatus.connecting:
        tooltip = appLocalizations.connecting;
        tint = colorScheme.statusWarning;
        tintAlpha = isDark ? 0.14 : 0.10;
        border = BorderSide(
          color: colorScheme.statusWarning.withValues(
            alpha: isDark ? 0.32 : 0.26,
          ),
        );
        glow = null;
        iconColor = colorScheme.statusWarning;
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: colorScheme.statusWarning,
          ),
        );
        break;
      case CoreStatus.disconnected:
        tooltip = appLocalizations.disconnected;
        tint = colorScheme.onSurfaceVariant;
        tintAlpha = isDark ? 0.10 : 0.08;
        border = BorderSide(color: colorScheme.outlineVariant);
        glow = null;
        iconColor = colorScheme.onSurfaceVariant;
        icon = const Icon(Icons.power_settings_new_rounded, size: 22);
        break;
    }

    final isInteractive = coreStatus != CoreStatus.connecting;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: '${appLocalizations.coreStatus}：$tooltip',
        button: isInteractive,
        child: SizedBox(
          width: _hitSize,
          height: _hitSize,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isInteractive ? onPressed : null,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return tint.withValues(alpha: 0.05);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return tint.withValues(alpha: 0.08);
                }
                return null;
              }),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    final scale = TweenSequence<double>([
                      TweenSequenceItem(
                        tween: Tween(
                          begin: 0.88,
                          end: 1.04,
                        ).chain(CurveTween(curve: Curves.easeOut)),
                        weight: 60,
                      ),
                      TweenSequenceItem(
                        tween: Tween(
                          begin: 1.04,
                          end: 1.0,
                        ).chain(CurveTween(curve: Curves.easeIn)),
                        weight: 40,
                      ),
                    ]).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: scale, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey(coreStatus),
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.withValues(alpha: tintAlpha),
                      border: Border.fromBorderSide(border),
                      boxShadow: glow,
                    ),
                    child: Center(
                      child: IconTheme.merge(
                        data: IconThemeData(color: iconColor),
                        child: icon,
                      ),
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

class _AddDashboardWidgetModal extends StatelessWidget {
  final List<GridItem> items;
  final Function(GridItem item) onAdd;

  const _AddDashboardWidgetModal({required this.items, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return DeferredPointerHandler(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Grid(
          crossAxisCount: 8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: items
              .map(
                (item) => item.wrap(
                  builder: (child) {
                    return _AddedContainer(
                      onAdd: () {
                        onAdd(item);
                      },
                      child: child,
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _AddedContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onAdd;

  const _AddedContainer({required this.child, required this.onAdd});

  @override
  State<_AddedContainer> createState() => _AddedContainerState();
}

class _AddedContainerState extends State<_AddedContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(_AddedContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {}
  }

  Future<void> _handleAdd() async {
    widget.onAdd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActivateBox(child: widget.child),
        Positioned(
          top: -8,
          right: -8,
          child: DeferPointer(
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton.filled(
                iconSize: 20,
                padding: const EdgeInsets.all(2),
                onPressed: _handleAdd,
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
