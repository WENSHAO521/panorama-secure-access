import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _badgeSize = 48.0;
const _barHeight = 8.0;
const _barGradient = LinearGradient(
  colors: [Color(0xFF6A5CF0), Color(0xFF19C8DC)],
);

/// Floats the background download status above the page content.
class UpdateCardHost extends ConsumerWidget {
  const UpdateCardHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final visible = state != null && state.cardVisible;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: visible
          ? UpdateCard(key: const ValueKey('update-card'), state: state)
          : const SizedBox.shrink(key: ValueKey('update-hidden')),
    );
  }
}

class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key, required this.state});

  final UpdateState state;

  String _title(AppLocalizations appLocalizations) {
    return switch (state.stage) {
      UpdateStage.available => appLocalizations.discoverNewVersion,
      UpdateStage.downloading => appLocalizations.updateDownloading,
      UpdateStage.verifying => appLocalizations.updateVerifying,
      UpdateStage.ready => appLocalizations.updateReady,
      UpdateStage.failed => appLocalizations.updateFailed,
    };
  }

  String _subtitle(AppLocalizations appLocalizations) {
    final size = state.total > 0 ? state.total : state.asset.size;
    return switch (state.stage) {
      UpdateStage.failed => appLocalizations.updateRetryHint,
      UpdateStage.downloading => '${state.version} · ${_percent()}',
      UpdateStage.verifying => state.version,
      _ => size > 0 ? '${state.version} · ${_bytes(size)}' : state.version,
    };
  }

  String _percent() {
    return '${((state.progress ?? 0) * 100).floor()}%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final appLocalizations = context.appLocalizations;
    final controller = ref.read(updateControllerProvider.notifier);
    final showBar =
        state.stage != UpdateStage.available &&
        state.stage != UpdateStage.failed;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      elevation: 6,
      shadowColor: colorScheme.shadow,
      shape: AppShape.lg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _UpdateBadge(stage: state.stage, progress: state.progress),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(appLocalizations),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(appLocalizations),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: state.stage == UpdateStage.failed
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: appLocalizations.close,
                  onPressed: controller.hide,
                  icon: const GlyphIcon(AppGlyphs.close),
                ),
              ],
            ),
            if (showBar) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, right: 8),
                child: _UpdateBar(progress: state.progress),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: _UpdateStats(state: state),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(commonActionProvider.notifier)
                          .showReleaseNotes(state.tag, state.body);
                    },
                    child: Text(appLocalizations.updateWhatsNew),
                  ),
                  _UpdateAction(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateAction extends ConsumerWidget {
  const _UpdateAction({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final controller = ref.read(updateControllerProvider.notifier);
    return switch (state.stage) {
      UpdateStage.available => FilledButton.icon(
        onPressed: controller.start,
        icon: const GlyphIcon(AppGlyphs.cloudDownload, fill: 1),
        label: Text(appLocalizations.updateNow),
      ),
      UpdateStage.downloading || UpdateStage.verifying => FilledButton.tonal(
        onPressed: state.stage == UpdateStage.downloading
            ? controller.cancel
            : null,
        child: Text(appLocalizations.cancel),
      ),
      UpdateStage.ready => FilledButton.icon(
        onPressed: controller.install,
        icon: const GlyphIcon(AppGlyphs.check, fill: 1),
        label: Text(appLocalizations.installNow),
      ),
      UpdateStage.failed => FilledButton.icon(
        onPressed: controller.start,
        icon: const GlyphIcon(AppGlyphs.refresh, fill: 1),
        label: Text(appLocalizations.retry),
      ),
    };
  }
}

class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge({required this.stage, required this.progress});

  final UpdateStage stage;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final failed = stage == UpdateStage.failed;
    final ready = stage == UpdateStage.ready;
    final busy =
        stage == UpdateStage.downloading || stage == UpdateStage.verifying;
    final glyph = failed
        ? AppGlyphs.close
        : ready
        ? AppGlyphs.check
        : AppGlyphs.cloudDownload;
    final background = failed
        ? colorScheme.errorContainer
        : ready
        ? colorScheme.primary
        : colorScheme.primaryContainer;
    final foreground = failed
        ? colorScheme.onErrorContainer
        : ready
        ? colorScheme.onPrimary
        : colorScheme.onPrimaryContainer;
    return SizedBox.square(
      dimension: _badgeSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (busy)
            SizedBox.square(
              dimension: _badgeSize,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _badgeSize - 12,
            height: _badgeSize - 12,
            decoration: ShapeDecoration(
              color: background,
              shape: AppShape.full,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: GlyphIcon(
                  glyph,
                  key: ValueKey(glyph),
                  size: 20,
                  color: foreground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateBar extends StatelessWidget {
  const _UpdateBar({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final value = progress;
    if (value == null) {
      return const LinearProgressIndicator(minHeight: _barHeight);
    }
    return SizedBox(
      height: _barHeight,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: AppShape.full,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          builder: (_, animated, _) {
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: animated.clamp(0.04, 1.0),
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: AppShape.full,
                    gradient: _barGradient,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UpdateStats extends StatelessWidget {
  const _UpdateStats({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final total = state.total > 0 ? state.total : state.asset.size;
    final received = state.stage == UpdateStage.ready ? total : state.received;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          total > 0
              ? '${_bytes(received)} / ${_bytes(total)}'
              : _bytes(received),
          style: style,
        ),
        if (state.stage == UpdateStage.downloading && state.speed > 0)
          Text('${_bytes(state.speed.round())}/s', style: style),
      ],
    );
  }
}

String _bytes(int value) {
  final show = value.traffic;
  return '${show.value} ${show.unit}';
}
