import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart' hide Card;
import 'package:prism_ui/prism_ui.dart' as prism show Card;

import 'star_chart.dart';

/// prism_ui's card, framed under the star-chart look; a selected card's frame
/// turns gilt.
class Card extends StatelessWidget {
  const Card({
    super.key,
    bool? isSelected,
    this.onPressed,
    this.radius,
    this.padding,
    this.enterAnimated = false,
    this.shape,
    this.isError = false,
    this.enterActionsOnRight = false,
    this.statesController,
    this.inert = false,
    this.fillsSelection = false,
    this.framed = true,
    this.frameInner = true,
    required this.child,
  }) : isSelected = isSelected ?? false;

  final bool inert;
  final bool enterAnimated;
  final bool enterActionsOnRight;
  final bool isSelected;
  final bool fillsSelection;
  final bool isError;
  final void Function()? onPressed;
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;
  final OutlinedBorder? shape;
  final WidgetStatesController? statesController;

  /// Whether the card carries its own frame; one nested in a framed box
  /// leaves it to that box.
  final bool framed;

  /// Whether the frame keeps its fine inner line; small tiles in a grid
  /// draw the edge alone.
  final bool frameInner;

  static BoxConstraints minimumOf(BuildContext context) =>
      prism.Card.minimumOf(context);

  static EdgeInsets paddingOf(BuildContext context, EdgeInsets padding) =>
      prism.Card.paddingOf(context, padding);

  @override
  Widget build(BuildContext context) {
    final card = prism.Card(
      isSelected: isSelected,
      onPressed: onPressed,
      radius: radius,
      padding: padding,
      enterAnimated: enterAnimated,
      shape: shape,
      isError: isError,
      enterActionsOnRight: enterActionsOnRight,
      statesController: statesController,
      inert: inert,
      fillsSelection: fillsSelection,
      child: child,
    );
    if (!framed || isError || !StarChartScope.of(context)) {
      return card;
    }
    final borderRadius = switch (shape) {
      final RoundedSuperellipseBorder shape => shape.borderRadius.resolve(
        Directionality.maybeOf(context),
      ),
      _ => AppRadius.all(radius ?? AppCorner.md),
    };
    final selected = isSelected && !fillsSelection;
    final brightness = context.colorScheme.brightness;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: StarFrameDecoration(
        radius: borderRadius,
        inner: frameInner && !fillsSelection,
        color: selected
            ? StarChartColors.chosenHairlineOf(brightness)
            : StarChartColors.hairlineOf(brightness),
      ),
      child: card,
    );
  }
}

/// Frames a hand-made card surface under the star-chart look.
class StarFramed extends StatelessWidget {
  const StarFramed({
    super.key,
    required this.radius,
    this.chosen = false,
    this.inner = true,
    this.openTop = false,
    this.openBottom = false,
    required this.child,
  });

  final BorderRadius radius;
  final bool chosen;
  final bool inner;
  final bool openTop;
  final bool openBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!StarChartScope.of(context)) {
      return child;
    }
    final brightness = context.colorScheme.brightness;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: StarFrameDecoration(
        radius: radius,
        inner: inner,
        openTop: openTop,
        openBottom: openBottom,
        color: chosen
            ? StarChartColors.chosenHairlineOf(brightness)
            : StarChartColors.hairlineOf(brightness),
      ),
      child: child,
    );
  }
}
