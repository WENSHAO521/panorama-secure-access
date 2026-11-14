import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart'
    hide
        ListHeader,
        generateAnimatedSection,
        generateGroup,
        generateSection,
        generateSliverSection;
import 'package:prism_ui/prism_ui.dart' as prism show ListHeader, generateGroup;

import 'star_chart.dart';

/// prism_ui's section title; under the star-chart look a serif title in gilt
/// with a ruled line running from it, as a letter paper's heading.
class ListHeader extends StatelessWidget {
  const ListHeader({
    super.key,
    required this.title,
    this.padding,
    this.actions = const [],
    this.trailing,
  });

  static const _actionSize = TonalButtonSize.section;
  static const _actionsGap = 6.0;

  final String title;
  final List<IconButtonData> actions;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    if (!StarChartScope.of(context)) {
      return prism.ListHeader(
        title: title,
        padding: padding,
        actions: actions,
        trailing: trailing,
      );
    }
    final inset = padding ?? listHeaderPaddingOf(context);
    final style = AppTextStyle.headline.of(context);
    final lineHeight = MeasureScope.of(
      context,
    ).textHeight(AppTextStyle.headline);
    final overhang = (_actionSize.button - lineHeight) / 2;
    final brightness = context.colorScheme.brightness;
    final grouped = actions.length > 1 ? actions.take(2) : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        inset.left,
        math.max(0, inset.top - overhang),
        inset.right,
        math.max(_actionsGap, inset.bottom - overhang),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _actionSize.button),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  spacing: 12,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.8,
                      ),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StarChartScope.titleOf(
                          context,
                          style,
                        ).copyWith(color: StarChartColors.giltOf(brightness)),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.8,
                        color: StarChartColors.hairlineOf(brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ?trailing,
            if (actions.isNotEmpty)
              TonalButtonTheme(
                size: _actionSize,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: appBarActionSpace,
                  children: [
                    if (grouped != null)
                      TonalButtonGroup(
                        size: _actionSize,
                        children: [
                          for (final data in grouped)
                            AppBarActionButton(data: data),
                        ],
                      ),
                    for (final data in actions.skip(grouped?.length ?? 0))
                      ElasticPress(
                        enabled: !data.isLoading && data.onPressed != null,
                        child: AppBarActionButton(data: data),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

StarFrameDecoration _groupFrameOf(BuildContext context) => StarFrameDecoration(
  radius: AppRadius.all(AppCorner.xl),
  color: StarChartColors.hairlineOf(context.colorScheme.brightness),
);

/// prism_ui's grouped rows, framed under the star-chart look.
Widget generateGroup(Iterable<Widget> items) =>
    _StarGroup(child: prism.generateGroup(items));

class _StarGroup extends StatelessWidget {
  const _StarGroup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!StarChartScope.of(context)) {
      return child;
    }
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: _groupFrameOf(context),
      child: child,
    );
  }
}

Widget generateSection({
  String? title,
  required Iterable<Widget> items,
  List<IconButtonData> actions = const [],
  String? footer,
}) {
  return Column(
    children: [
      if (items.isNotEmpty)
        title != null
            ? ListHeader(title: title, actions: actions)
            : const ListSectionGap(),
      if (items.isNotEmpty) generateGroup(items),
      if (items.isNotEmpty && footer != null) ListFooter(text: footer),
    ],
  );
}

Widget generateAnimatedSection({
  String? title,
  required List<Widget> items,
  String? footer,
}) {
  return Column(
    children: [
      if (items.isNotEmpty)
        title != null ? ListHeader(title: title) : const ListSectionGap(),
      _StarGroup(child: AnimatedEntries(grouped: true, children: items)),
      if (items.isNotEmpty && footer != null) ListFooter(text: footer),
    ],
  );
}

Widget generateSliverSection<T>({
  String? title,
  required List<T> items,
  required Widget Function(T item) itemBuilder,
  List<IconButtonData> actions = const [],
  String? footer,
}) {
  if (items.isEmpty) {
    return const SliverToBoxAdapter();
  }
  return SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: title != null
            ? ListHeader(title: title, actions: actions)
            : const ListSectionGap(),
      ),
      _StarSliverGroup(
        sliver: SliverPrismList(
          itemCount: items.length,
          itemBuilder: (_, index) => ItemPositionProvider(
            position: ItemPosition.get(index, items.length),
            child: itemBuilder(items[index]),
          ),
        ),
      ),
      if (footer != null) SliverToBoxAdapter(child: ListFooter(text: footer)),
    ],
  );
}

class _StarSliverGroup extends StatelessWidget {
  const _StarSliverGroup({required this.sliver});

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    if (!StarChartScope.of(context)) {
      return sliver;
    }
    return DecoratedSliver(
      position: DecorationPosition.foreground,
      decoration: _groupFrameOf(context),
      sliver: sliver,
    );
  }
}
