import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';

import 'fade_box.dart';
import 'glass.dart';
import 'text.dart';

class Info {
  final String label;
  final IconData? iconData;

  const Info({required this.label, this.iconData});
}

class InfoHeader extends StatelessWidget {
  final Info info;
  final List<Widget> actions;
  final EdgeInsets? padding;

  const InfoHeader({
    super.key,
    required this.info,
    this.padding,
    List<Widget>? actions,
  }) : actions = actions ?? const [];

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry nextPadding = (padding ?? baseInfoEdgeInsets);
    if (actions.isNotEmpty) {
      nextPadding = nextPadding.subtract(EdgeInsets.symmetric(vertical: 8.mAp));
    }
    return Padding(
      padding: nextPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (info.iconData != null) ...[
                  Icon(
                    info.iconData,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  flex: 1,
                  child: TooltipText(
                    text: Text(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (actions.isNotEmpty)
            SizedBox(
              height: globalState.measure.titleSmallHeight + 16.ap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [...actions],
              ),
            ),
        ],
      ),
    );
  }
}

class CommonCard extends StatefulWidget {
  const CommonCard({
    super.key,
    bool? isSelected,
    this.type = CommonCardType.plain,
    this.onPressed,
    this.selectWidget,
    this.radius,
    required this.child,
    this.padding,
    this.enterAnimated = false,
    this.info,
    this.onLongPress,
    this.shape,
    this.isError = false,
  }) : isSelected = isSelected ?? false;

  final bool enterAnimated;
  final bool isSelected;
  final bool isError;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final Widget? selectWidget;
  final Widget child;
  final EdgeInsets? padding;
  final Info? info;
  final CommonCardType type;
  final double? radius;
  final OutlinedBorder? shape;

  @override
  State<CommonCard> createState() => _CommonCardState();
}

class _CommonCardState extends State<CommonCard> {
  // Shared with the FilledButton/OutlinedButton below via `statesController:`
  // so the hover/press micro-interaction painted by _LiquidCardInteraction
  // (edge/specular boost on hover, tiny material compression on press) can
  // read the exact same state the button itself reacts to, instead of
  // duplicating hover/press detection with a second MouseRegion/GestureDetector.
  final _statesController = WidgetStatesController();

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  bool get isSelected => widget.isSelected;

  bool get isError => widget.isError;

  CommonCardType get type => widget.type;

  BorderSide _buildBorderSide(BuildContext context, Set<WidgetState> states) {
    final colorScheme = context.colorScheme;
    if (isError) {
      if (type == CommonCardType.filled) {
        return BorderSide(color: colorScheme.error);
      }
      final hoverColor = isSelected
          ? colorScheme.error.opacity80
          : colorScheme.error.opacity38;
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused) ||
          states.contains(WidgetState.pressed)) {
        return BorderSide(color: hoverColor);
      }
      return BorderSide(
        color: isSelected
            ? colorScheme.error.opacity60
            : colorScheme.error.opacity30,
      );
    }
    if (type == CommonCardType.filled) {
      return BorderSide.none;
    }
    final hoverColor = isSelected
        ? colorScheme.primary.opacity80
        : colorScheme.primary.opacity60;
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.pressed)) {
      return BorderSide(color: hoverColor);
    }
    return BorderSide(
      color: isSelected
          ? colorScheme.primary
          // Subtle outlineVariant instead of a solid neutral tone — this
          // card's own low-alpha GlassSurface.repeated fill is meant to
          // read as a lightweight control, not a mini glass panel with its
          // own bright border competing with whatever it's nested inside
          // (e.g. the strategy buttons in a BottomSheet group picker).
          : colorScheme.outlineVariant.withValues(
              alpha: GlassTokens.borderOpacityFor(colorScheme.brightness),
            ),
    );
  }

  Color? _buildBackgroundColor(BuildContext context) {
    final colorScheme = context.colorScheme;
    // if (isError) {
    //   if (type == CommonCardType.filled) {
    //     return isSelected
    //         ? colorScheme.errorContainer.opacity80
    //         : colorScheme.errorContainer;
    //   }
    //   return isSelected
    //       ? colorScheme.errorContainer.opacity60
    //       : colorScheme.errorContainer.opacity12;
    // }
    if (type == CommonCardType.filled) {
      if (isSelected) {
        return colorScheme.secondaryContainer.opacity80;
      }
      return colorScheme.surfaceContainerHigh;
    }
    if (isSelected) {
      return colorScheme.secondaryContainer;
    }
    return colorScheme.surfaceContainerLow;
  }

  Color? _buildForegroundColor(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (isError) {
      return colorScheme.error;
    }
    if (type == CommonCardType.filled) {
      if (isSelected) {
        return colorScheme.onSecondaryContainer;
      }
      return colorScheme.onSurfaceVariant;
    }
    if (isSelected) {
      return colorScheme.onSecondaryContainer;
    }
    return colorScheme.onSurfaceVariant;
  }

  Color? _buildIconColor(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (isError) {
      return colorScheme.error;
    }
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    var childWidget = widget.child;

    if (widget.info != null) {
      childWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoHeader(
            padding: baseInfoEdgeInsets.copyWith(bottom: 0),
            info: widget.info!,
          ),
          Flexible(flex: 1, child: widget.child),
        ],
      );
    }

    if (widget.selectWidget != null && isSelected) {
      final List<Widget> children = [];
      children.add(childWidget);
      children.add(Positioned.fill(child: widget.selectWidget!));
      childWidget = Stack(children: children);
    }

    final cardShape =
        widget.shape ??
        RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(
            widget.radius ?? GlassTokens.radiusCard,
          ),
        );

    final card = switch (type == CommonCardType.filled) {
      true => FilledButton(
        onLongPress: widget.onLongPress,
        statesController: _statesController,
        clipBehavior: Clip.antiAlias,
        style:
            FilledButton.styleFrom(
              padding: widget.padding ?? EdgeInsets.zero,
              shape: cardShape,
              iconSize: 20,
              iconColor: _buildIconColor(context),
              foregroundColor: _buildForegroundColor(context),
              side: BorderSide.none,
              elevation: 0,
            ).copyWith(
              backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
              side: WidgetStateProperty.resolveWith(
                (states) => _buildBorderSide(context, states),
              ),
            ),
        onPressed: widget.onPressed,
        child: childWidget,
      ),
      false => OutlinedButton(
        onLongPress: widget.onLongPress,
        statesController: _statesController,
        clipBehavior: Clip.antiAlias,
        style:
            OutlinedButton.styleFrom(
              padding: widget.padding ?? EdgeInsets.zero,
              shape: cardShape,
              iconSize: 20,
              iconColor: _buildIconColor(context),
              backgroundColor: Colors.transparent,
              foregroundColor: _buildForegroundColor(context),
              elevation: 0,
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => _buildBorderSide(context, states),
              ),
            ),
        onPressed: widget.onPressed,
        child: childWidget,
      ),
    };

    // GlassSurfaceType.repeated on purpose: CommonCard can appear dozens of
    // times at once (proxy grids, provider lists), and stacking that many
    // backdrop filters is a real scroll-jank risk, so this never blurs. Its
    // opacity is also deliberately low — CommonCard nests inside panel/modal
    // GlassSurfaces (settings groups, bottom sheets) constantly, and a
    // repeated child anywhere near panel-level opacity compounds with its
    // parent into a near-opaque block instead of reading as "glass inside
    // glass".
    //
    // showBorder: false — the OutlinedButton/FilledButton above already owns
    // the border via _buildBorderSide (its `side:` on the same cardShape).
    // Leaving GlassSurface's own default border on top double-paints the
    // identical outlineVariant stroke, compositing to roughly double the
    // intended alpha on every idle card.
    final glassCard = GlassSurface.repeated(
      shape: cardShape,
      color: _buildBackgroundColor(context),
      showBorder: false,
      child: card,
    );

    // The material-response layer: a tiny press compression plus a hover
    // edge/specular boost, both driven by the same WidgetStatesController
    // the button above already updates — no second hover/press detector,
    // no BackdropFilter, no per-frame repaint, so this stays cheap even
    // when dozens of these are on screen (proxy grids, provider lists).
    final interactiveCard = _LiquidCardInteraction(
      statesController: _statesController,
      shape: cardShape,
      child: glassCard,
    );

    return switch (widget.enterAnimated) {
      true => FadeScaleEnterBox(child: interactiveCard),
      false => interactiveCard,
    };
  }
}

/// CommonCard's hover/press material response. Listens to the same
/// [WidgetStatesController] the card's FilledButton/OutlinedButton reacts
/// to (via `statesController:`) instead of adding a second
/// MouseRegion/GestureDetector, and only ever repaints this one card when
/// its own state changes — never the list/grid it sits in.
///
/// Pressed: a ~1% [AnimatedScale] compression (bounded to the
/// spec's 0.985–0.995 band via [GlassTokens.pressedScale]) — material
/// tension, not a bouncy button.
/// Hovered (desktop only — mobile never emits a hover state): a static,
/// low-opacity directional gradient over the card's own shape, standing
/// in for "edge/specular increases" without giving every repeated card its
/// own [CustomPainter] or pointer-tracked specular layer the way
/// [GlassSurfaceType.crystal]/[GlassSurfaceType.modal] surfaces get.
class _LiquidCardInteraction extends StatefulWidget {
  final WidgetStatesController statesController;
  final OutlinedBorder shape;
  final Widget child;

  const _LiquidCardInteraction({
    required this.statesController,
    required this.shape,
    required this.child,
  });

  @override
  State<_LiquidCardInteraction> createState() =>
      _LiquidCardInteractionState();
}

class _LiquidCardInteractionState extends State<_LiquidCardInteraction> {
  @override
  void initState() {
    super.initState();
    widget.statesController.addListener(_onStatesChanged);
  }

  @override
  void didUpdateWidget(covariant _LiquidCardInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      oldWidget.statesController.removeListener(_onStatesChanged);
      widget.statesController.addListener(_onStatesChanged);
    }
  }

  @override
  void dispose() {
    widget.statesController.removeListener(_onStatesChanged);
    super.dispose();
  }

  void _onStatesChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final states = widget.statesController.value;
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isPressed = !reducedMotion && states.contains(WidgetState.pressed);
    final isHovered =
        !reducedMotion &&
        (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused));
    final brightness = context.colorScheme.brightness;
    return AnimatedScale(
      scale: isPressed ? GlassTokens.pressedScale : 1.0,
      duration: GlassTokens.pressDuration,
      curve: GlassTokens.materialTransitionCurve,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: isHovered ? 1 : 0,
                duration: GlassTokens.hoverDuration,
                curve: GlassTokens.materialTransitionCurve,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: widget.shape,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(
                          alpha: brightness == Brightness.dark ? 0.05 : 0.10,
                        ),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectIcon extends StatelessWidget {
  const SelectIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.inversePrimary,
      shape: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.check, size: 16),
      ),
    );
  }
}

class SettingsBlock extends StatelessWidget {
  final String title;
  final List<Widget> settings;

  const SettingsBlock({super.key, required this.title, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          InfoHeader(info: Info(label: title)),
          GlassSurface.panel(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
            ),
            color: context.colorScheme.surfaceContainer,
            child: Column(children: settings),
          ),
        ],
      ),
    );
  }
}
