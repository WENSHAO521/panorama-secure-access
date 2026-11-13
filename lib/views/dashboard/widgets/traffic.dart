import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/views/dashboard/style.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';
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

/// One Northern Dipper for both directions, the upload climbing its handle
/// and the download filling its bowl, with the upload's figure in the open
/// sky over the handle and the download's under the bowl.
///
/// On the phone it takes the height its width calls for; with [fill], as on
/// a desktop grid, it fills the height it is given and the gauge narrows to
/// fit.
class NetworkSpeedCard extends ConsumerWidget {
  const NetworkSpeedCard({super.key, this.fill = false});

  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffics = ref.watch(trafficsProvider);
    final total = ref.watch(totalTrafficProvider);
    final latest = traffics.list.safeLast(const Traffic());
    const upload = TrafficDirection.upload;
    const download = TrafficDirection.download;
    return DashboardCard(
      semanticLabel: context.appLocalizations.networkSpeed,
      child: Column(
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.speed,
            title: context.appLocalizations.networkSpeed,
          ),
          const SizedBox(height: 12),
          _fit(
            _DipperSpeedLayout(
              upload: _SpeedFigures(
                direction: upload,
                speed: upload.of(latest),
                total: upload.of(total),
                alignment: CrossAxisAlignment.start,
              ),
              gauge: RepaintBoundary(
                child: DipperGauge.split(
                  upload: dipperLevel(upload.of(latest)),
                  download: dipperLevel(download.of(latest)),
                  dark: context.colorScheme.brightness == Brightness.dark,
                ),
              ),
              download: _SpeedFigures(
                direction: download,
                speed: download.of(latest),
                total: download.of(total),
                alignment: CrossAxisAlignment.end,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fit(Widget layout) => fill ? Expanded(child: layout) : layout;
}

/// One direction's label, figure and total.
class _SpeedFigures extends StatelessWidget {
  const _SpeedFigures({
    required this.direction,
    required this.speed,
    required this.total,
    required this.alignment,
  });

  final TrafficDirection direction;
  final num speed;
  final num total;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final show = speed.traffic;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            GlyphIcon(
              direction.glyph,
              size: 16,
              color: direction.glyphColorOf(context),
            ),
            Flexible(
              child: Text(
                direction.labelOf(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.footnote
                    .of(context, emphasized: true)
                    .copyWith(color: context.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        _Figure(
          show: show,
          unit: _speedUnit(show),
          style: AppTextStyle.title1,
          unitStyle: AppTextStyle.footnote,
        ),
        Text(
          context.appLocalizations.trafficTotal(dashboardTraffic(total)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.label(context),
        ),
      ],
    );
  }
}

/// Lays the gauge across the full width with [upload] over its handle at
/// the top left and [download] under its bowl at the bottom right, moving
/// the gauge down when the upload's text grows too tall for the sky over
/// the handle.
class _DipperSpeedLayout extends MultiChildRenderObjectWidget {
  _DipperSpeedLayout({
    required Widget upload,
    required Widget gauge,
    required Widget download,
  }) : super(children: [upload, gauge, download]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDipperSpeedLayout();
}

class _DipperSpeedParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDipperSpeedLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DipperSpeedParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DipperSpeedParentData> {
  /// How wide each figure may grow, as a share of the width, to stay clear
  /// of Megrez and the bowl over the handle and of Alkaid under the bowl.
  static const _figureWidth = 0.54;

  /// How much of the width the gauge may take when it fills a set height.
  static const _filledSpan = 0.62;
  static const _gap = 4.0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DipperSpeedParentData) {
      child.parentData = _DipperSpeedParentData();
    }
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final upload = firstChild!;
    final gauge = childAfter(upload)!;
    final download = childAfter(gauge)!;
    final loose = BoxConstraints(maxWidth: width * _figureWidth);
    upload.layout(loose, parentUsesSize: true);
    download.layout(loose, parentUsesSize: true);
    final uploadBottom = upload.size.height + _gap;

    if (constraints.hasBoundedHeight) {
      _layoutFilled(upload, gauge, download, width, constraints.maxHeight);
      return;
    }
    // The gauge spans the full width, moved down if the upload's text is
    // taller than the sky over the handle, and the download sits under the
    // bowl, or under the upload if that reaches lower.
    final gaugeTop = math.max(0.0, uploadBottom - width * dipperRoomOverHandle);
    final downloadTop = math.max(
      gaugeTop + width * dipperRoomUnderBowl,
      uploadBottom,
    );
    gauge.layout(BoxConstraints.tight(Size(width, width * dipperBoxDepth)));
    size = constraints.constrain(
      Size(
        width,
        math.max(
          gaugeTop + width * dipperBoxDepth,
          downloadTop + download.size.height,
        ),
      ),
    );
    (upload.parentData! as _DipperSpeedParentData).offset = Offset.zero;
    (gauge.parentData! as _DipperSpeedParentData).offset = Offset(0, gaugeTop);
    (download.parentData! as _DipperSpeedParentData).offset = Offset(
      width - download.size.width,
      downloadTop,
    );
  }

  /// Fills a box of a set height, as on a desktop grid: the gauge as large
  /// as the height allows in the middle, short of the corners, the upload in
  /// the top left corner and the download in the bottom right one, where the
  /// asterism leaves the sky open.
  void _layoutFilled(
    RenderBox upload,
    RenderBox gauge,
    RenderBox download,
    double width,
    double height,
  ) {
    final span = math.max(
      0.0,
      math.min(width * _filledSpan, height / dipperBoxDepth),
    );
    gauge.layout(BoxConstraints.tight(Size(span, span * dipperBoxDepth)));
    size = constraints.constrain(Size(width, height));
    (upload.parentData! as _DipperSpeedParentData).offset = Offset.zero;
    (gauge.parentData! as _DipperSpeedParentData).offset = Offset(
      (size.width - span) / 2,
      (size.height - span * dipperBoxDepth) / 2,
    );
    (download.parentData! as _DipperSpeedParentData).offset = Offset(
      size.width - download.size.width,
      math.max(0.0, size.height - download.size.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
