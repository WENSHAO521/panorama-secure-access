import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/views/dashboard/style.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import 'card.dart';
import 'dipper_gauge.dart';

enum TrafficDirection {
  upload,
  download;

  num of(Traffic traffic) => this == upload ? traffic.up : traffic.down;

  Glyph get glyph => this == upload ? AppGlyphs.arrowUp : AppGlyphs.arrowDown;

  Color glyphColorOf(BuildContext context) => this == upload
      ? context.colorScheme.onSurfaceVariant
      : context.colorScheme.primary;

  String labelOf(BuildContext context) => this == upload
      ? context.appLocalizations.upload
      : context.appLocalizations.download;
}

String _speedUnit(TrafficShow show) => '${show.unit}/s';

class _Figure extends StatelessWidget {
  const _Figure({
    required this.show,
    required this.unit,
    required this.style,
    required this.unitStyle,
  });

  final TrafficShow show;
  final String unit;
  final AppTextStyle style;
  final AppTextStyle unitStyle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: show.value,
            style: DashboardText.figure(context, style),
          ),
          TextSpan(
            text: ' $unit',
            style: DashboardText.unit(context, unitStyle),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }
}

/// The upload or the download on its own desktop card: the title row with
/// the peak over the window, a low arch of the seven stars of the Northern
/// Dipper that lights up with the speed, and the figure and total under it.
class SpeedCard extends ConsumerWidget {
  const SpeedCard({super.key, required this.direction});

  final TrafficDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final compact = density.isCompact;
    final scale = DashboardDensityScope.scaleOf(context);
    final appLocalizations = context.appLocalizations;
    final traffics = ref.watch(trafficsProvider);
    final total = ref.watch(
      totalTrafficProvider.select((state) => direction.of(state)),
    );
    final current = direction.of(traffics.list.safeLast(const Traffic()));
    final peak = traffics.list.fold<num>(
      0,
      (peak, traffic) => math.max(peak, direction.of(traffic)),
    );
    final speed = current.traffic;
    final gap = compact ? 6.0 : 10.0;
    return DashboardCard(
      semanticLabel: direction.labelOf(context),
      child: Column(
        children: [
          SizedBox(
            height: 24 * scale,
            child: Row(
              spacing: 8,
              children: [
                GlyphIcon(
                  direction.glyph,
                  size: 18,
                  color: direction.glyphColorOf(context),
                ),
                Text(
                  direction.labelOf(context),
                  maxLines: 1,
                  style: DashboardText.cardTitle(context),
                ),
                Expanded(
                  child: Text(
                    appLocalizations.trafficPeak('${dashboardTraffic(peak)}/s'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: DashboardText.label(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          Expanded(
            child: RepaintBoundary(
              child: DipperGauge(
                level: dipperLevel(current),
                dark: context.colorScheme.brightness == Brightness.dark,
              ),
            ),
          ),
          SizedBox(height: gap / 2),
          _Figure(
            show: speed,
            unit: _speedUnit(speed),
            style: compact ? AppTextStyle.title1 : AppTextStyle.largeTitle,
            unitStyle: AppTextStyle.subheadline,
          ),
          Text(
            appLocalizations.trafficTotal(dashboardTraffic(total)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardText.label(context),
          ),
        ],
      ),
    );
  }
}

/// The phone's single card: both directions side by side.
class NetworkSpeedCard extends ConsumerWidget {
  const NetworkSpeedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffics = ref.watch(trafficsProvider);
    final total = ref.watch(totalTrafficProvider);
    final latest = traffics.list.safeLast(const Traffic());
    return DashboardCard(
      semanticLabel: context.appLocalizations.networkSpeed,
      child: Column(
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.speed,
            title: context.appLocalizations.networkSpeed,
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 10,
            children: [
              for (final direction in TrafficDirection.values)
                Expanded(
                  child: _SpeedTile(
                    direction: direction,
                    speed: direction.of(latest),
                    total: direction.of(total),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Keeps one shape at every width, growing only when the text needs more: the
/// title, a low arch of the seven stars of the Northern Dipper that lights up
/// with the speed, and the figure and total under it.
class _SpeedTile extends StatelessWidget {
  const _SpeedTile({
    required this.direction,
    required this.speed,
    required this.total,
  });

  final TrafficDirection direction;
  final num speed;
  final num total;

  static const _aspectRatio = 1.2;
  static const _padding = EdgeInsets.fromLTRB(12, 12, 12, 12);
  static const _gaugeHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final color = direction.glyphColorOf(context);
    final show = speed.traffic;
    final scale = DashboardDensityScope.scaleOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            minHeight: constraints.maxWidth / _aspectRatio,
          ),
          padding: _padding,
          decoration: ShapeDecoration(
            color: DashboardColors.of(context).tone,
            shape: AppShape.all(DashboardCorner.mobileBlock),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 4,
                children: [
                  GlyphIcon(direction.glyph, size: 16, color: color),
                  Flexible(
                    child: Text(
                      direction.labelOf(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.footnote
                          .of(context, emphasized: true)
                          .copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: _gaugeHeight * scale,
                child: RepaintBoundary(
                  child: DipperGauge(
                    level: dipperLevel(speed),
                    dark: context.colorScheme.brightness == Brightness.dark,
                  ),
                ),
              ),
              Column(
                children: [
                  _Figure(
                    show: show,
                    unit: _speedUnit(show),
                    style: AppTextStyle.title1,
                    unitStyle: AppTextStyle.footnote,
                  ),
                  Text(
                    context.appLocalizations.trafficTotal(
                      dashboardTraffic(total),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardText.label(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
