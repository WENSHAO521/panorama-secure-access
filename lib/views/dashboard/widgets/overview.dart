import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final coreStatus = ref.watch(coreStatusProvider);
    final isStart = ref.watch(isStartProvider);
    final runTime = ref.watch(runTimeProvider);
    final profile = ref.watch(currentProfileProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final tunEnabled = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    final traffics = ref.watch(trafficsProvider).list;
    final currentTraffic = traffics.safeLast(const Traffic());
    final colorScheme = context.colorScheme;
    final status = _DashboardConnectionStatus.fromCoreStatus(
      context,
      coreStatus,
    );

    void updateConnection() {
      debouncer.call(FunctionTag.updateStatus, () {
        ref
            .read(setupActionProvider.notifier)
            .updateStatus(!isStart, isInit: !ref.read(initProvider));
      }, duration: commonDuration);
    }

    void updateSystemProxy(bool value) {
      ref
          .read(networkSettingProvider.notifier)
          .update((state) => state.copyWith(systemProxy: value));
    }

    void updateTun(bool value) {
      ref
          .read(patchClashConfigProvider.notifier)
          .update(
            (state) => state.copyWith(tun: state.tun.copyWith(enable: value)),
          );
    }

    void updateMode(Mode value) {
      ref.read(setupActionProvider.notifier).changeMode(value);
    }

    void openProfiles() {
      ref.read(currentPageLabelProvider.notifier).toProfiles();
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        final isCompact = constraints.maxWidth < 820;
        final content = _DashboardOverviewContent(
          appLocalizations: appLocalizations,
          colorScheme: colorScheme,
          coreStatus: coreStatus,
          connectionStatus: status,
          isStart: isStart,
          runTime: runTime,
          hasProfile: profile != null,
          profileName: profile?.realLabel ?? appLocalizations.profile,
          mode: mode,
          systemProxy: systemProxy,
          tunEnabled: tunEnabled,
          traffics: traffics,
          currentTraffic: currentTraffic,
          onConnectionPressed: updateConnection,
          onOpenProfiles: openProfiles,
          onModeChanged: updateMode,
          onSystemProxyChanged: updateSystemProxy,
          onTunChanged: updateTun,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 20 : 38,
            isCompact ? 24 : 34,
            isCompact ? 20 : 38,
            isCompact ? 36 : 44,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(content: content, compact: isCompact),
              SizedBox(height: isCompact ? 30 : 38),
              isCompact
                  ? _CompactDashboardOverview(content: content)
                  : _DesktopDashboardOverview(content: content),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardOverviewContent {
  final AppLocalizations appLocalizations;
  final ColorScheme colorScheme;
  final CoreStatus coreStatus;
  final _DashboardConnectionStatus connectionStatus;
  final bool isStart;
  final int? runTime;
  final bool hasProfile;
  final String profileName;
  final Mode mode;
  final bool systemProxy;
  final bool tunEnabled;
  final List<Traffic> traffics;
  final Traffic currentTraffic;
  final VoidCallback onConnectionPressed;
  final VoidCallback onOpenProfiles;
  final ValueChanged<Mode> onModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;
  final ValueChanged<bool> onTunChanged;

  const _DashboardOverviewContent({
    required this.appLocalizations,
    required this.colorScheme,
    required this.coreStatus,
    required this.connectionStatus,
    required this.isStart,
    required this.runTime,
    required this.hasProfile,
    required this.profileName,
    required this.mode,
    required this.systemProxy,
    required this.tunEnabled,
    required this.traffics,
    required this.currentTraffic,
    required this.onConnectionPressed,
    required this.onOpenProfiles,
    required this.onModeChanged,
    required this.onSystemProxyChanged,
    required this.onTunChanged,
  });
}

class _DashboardHeader extends StatelessWidget {
  final _DashboardOverviewContent content;
  final bool compact;

  const _DashboardHeader({required this.content, required this.compact});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = content.colorScheme;
    final appLocalizations = content.appLocalizations;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          label: appLocalizations.dashboardOverviewEyebrow,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          appLocalizations.dashboardOverviewTitle,
          style: textTheme.displaySmall?.copyWith(
            color: colorScheme.onSurface,
            fontSize: compact ? 32 : 46,
            fontWeight: FontWeight.w700,
            height: 1.05,
            letterSpacing: compact ? -0.8 : -1.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          appLocalizations.dashboardOverviewSubtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
    if (compact) {
      return copy;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: copy),
        const SizedBox(width: 32),
        SizedBox(
          width: 180,
          child: Text(
            appLocalizations.dashboardOverviewTagline,
            textAlign: TextAlign.right,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopDashboardOverview extends StatelessWidget {
  final _DashboardOverviewContent content;

  const _DesktopDashboardOverview({required this.content});

  @override
  Widget build(BuildContext context) {
    final dividerColor = content.colorScheme.outlineVariant.withValues(
      alpha: 0.72,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _ConnectionPane(content: content)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(width: 1, color: dividerColor),
          ),
          Expanded(flex: 7, child: _RoutingAndTrafficPane(content: content)),
        ],
      ),
    );
  }
}

class _CompactDashboardOverview extends StatelessWidget {
  final _DashboardOverviewContent content;

  const _CompactDashboardOverview({required this.content});

  @override
  Widget build(BuildContext context) {
    final dividerColor = content.colorScheme.outlineVariant.withValues(
      alpha: 0.72,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConnectionPane(content: content, compact: true),
        const SizedBox(height: 30),
        Divider(color: dividerColor, height: 1),
        const SizedBox(height: 28),
        _RoutingAndTrafficPane(content: content, compact: true),
      ],
    );
  }
}

class _ConnectionPane extends StatelessWidget {
  final _DashboardOverviewContent content;
  final bool compact;

  const _ConnectionPane({required this.content, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = content.colorScheme;
    final appLocalizations = content.appLocalizations;
    final canToggle =
        content.hasProfile && content.coreStatus != CoreStatus.connecting;
    final runtime = content.runTime == null
        ? '--:--:--'
        : utils.getTimeText(content.runTime);
    final stateText = content.connectionStatus.label;

    return Semantics(
      label: '${appLocalizations.connection}: $stateText',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            label: appLocalizations.connection,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusDot(color: content.connectionStatus.color),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stateText,
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.dashboardStatusDescription,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            height: 1,
          ),
          const SizedBox(height: 18),
          _DetailRow(
            label: appLocalizations.dashboardRoute,
            value: content.profileName,
            onTap: content.onOpenProfiles,
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          _DetailRow(
            label: appLocalizations.outboundMode,
            value: _modeLabel(appLocalizations, content.mode),
          ),
          _DetailRow(label: appLocalizations.dashboardUptime, value: runtime),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: content.onOpenProfiles,
              icon: const Icon(Icons.alt_route_rounded, size: 19),
              label: Text(appLocalizations.dashboardChangeRoute),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.statusConnected,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              appLocalizations.dashboardChangeRouteDesc,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: canToggle ? content.onConnectionPressed : null,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: Text(
                content.isStart
                    ? appLocalizations.stop
                    : appLocalizations.start,
              ),
            ),
          ),
          if (!compact) const Spacer(),
        ],
      ),
    );
  }
}

class _RoutingAndTrafficPane extends StatelessWidget {
  final _DashboardOverviewContent content;
  final bool compact;

  const _RoutingAndTrafficPane({required this.content, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final dividerColor = content.colorScheme.outlineVariant.withValues(
      alpha: 0.72,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrafficPane(content: content, compact: compact),
        SizedBox(height: compact ? 28 : 30),
        Divider(color: dividerColor, height: 1),
        SizedBox(height: compact ? 28 : 26),
        _RoutingPane(content: content),
      ],
    );
  }
}

class _RoutingPane extends StatelessWidget {
  final _DashboardOverviewContent content;

  const _RoutingPane({required this.content});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = content.appLocalizations;
    final colorScheme = content.colorScheme;
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          label: appLocalizations.outboundMode,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 18),
        _ModeSelector(content: content),
        const SizedBox(height: 26),
        Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            _ConnectionOption(
              label: appLocalizations.systemProxy,
              value: content.systemProxy,
              onChanged: content.onSystemProxyChanged,
            ),
            _ConnectionOption(
              label: appLocalizations.tun,
              value: content.tunEnabled,
              onChanged: content.onTunChanged,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          appLocalizations.dashboardLastThirtyMinutes,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final _DashboardOverviewContent content;

  const _ModeSelector({required this.content});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = content.appLocalizations;
    final modes = <(Mode, String)>[
      (Mode.rule, appLocalizations.rule),
      (Mode.global, appLocalizations.global),
      (Mode.direct, appLocalizations.direct),
    ];
    return Row(
      children: [
        for (var index = 0; index < modes.length; index++)
          Expanded(
            child: _ModeButton(
              label: modes[index].$2,
              selected: content.mode == modes[index].$1,
              isFirst: index == 0,
              isLast: index == modes.length - 1,
              onPressed: () => content.onModeChanged(modes[index].$1),
            ),
          ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final borderRadius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(4) : Radius.zero,
      right: isLast ? const Radius.circular(4) : Radius.zero,
    );
    return Padding(
      padding: EdgeInsets.only(left: isFirst ? 0 : 1),
      child: Material(
        color: selected
            ? colorScheme.statusConnected.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? colorScheme.statusConnected
                    : colorScheme.outlineVariant,
              ),
              borderRadius: borderRadius,
            ),
            child: Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: selected
                    ? colorScheme.statusConnected
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConnectionOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _TrafficPane extends StatelessWidget {
  final _DashboardOverviewContent content;
  final bool compact;

  const _TrafficPane({required this.content, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = content.colorScheme;
    final downColor = colorScheme.statusConnected;
    final upColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.58);
    final downText = '${content.currentTraffic.down.traffic.show}/s';
    final upText = '${content.currentTraffic.up.traffic.show}/s';
    final chartHeight = compact ? 132.0 : 176.0;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SectionLabel(
                label: content.appLocalizations.dashboardNetworkTraffic,
                color: colorScheme.onSurfaceVariant,
              ),
              const Spacer(),
              Text(
                content.appLocalizations.dashboardLastThirtyMinutes,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: CustomPaint(
              painter: _TrafficGridPainter(
                color: colorScheme.outlineVariant.withValues(alpha: 0.48),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LineChart(
                    points: _trafficPoints(content.traffics, (traffic) {
                      return traffic.down;
                    }),
                    color: downColor,
                    duration: commonDuration,
                    gradient: true,
                  ),
                  LineChart(
                    points: _trafficPoints(content.traffics, (traffic) {
                      return traffic.up;
                    }),
                    color: upColor,
                    duration: commonDuration,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: compact ? 20 : 32,
            runSpacing: 10,
            children: [
              _TrafficMetric(
                color: downColor,
                label: content.appLocalizations.download,
                value: downText,
              ),
              _TrafficMetric(
                color: upColor,
                label: content.appLocalizations.upload,
                value: upText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TrafficMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TrafficGridPainter extends CustomPainter {
  final Color color;

  const _TrafficGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var index = 1; index < 5; index++) {
      final y = size.height * index / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var index = 1; index < 7; index++) {
      final x = size.width * index / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrafficGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

String _modeLabel(AppLocalizations appLocalizations, Mode mode) {
  return switch (mode) {
    Mode.rule => appLocalizations.rule,
    Mode.global => appLocalizations.global,
    Mode.direct => appLocalizations.direct,
  };
}

List<Point> _trafficPoints(
  List<Traffic> traffics,
  num Function(Traffic traffic) valueOf,
) {
  return [
    const Point(0, 0),
    const Point(1, 0),
    ...traffics.asMap().entries.map(
      (entry) =>
          Point((entry.key + 2).toDouble(), valueOf(entry.value).toDouble()),
    ),
  ];
}

class _DashboardConnectionStatus {
  final Color color;
  final String label;

  const _DashboardConnectionStatus({required this.color, required this.label});

  factory _DashboardConnectionStatus.fromCoreStatus(
    BuildContext context,
    CoreStatus coreStatus,
  ) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    return switch (coreStatus) {
      CoreStatus.connected => _DashboardConnectionStatus(
        color: colorScheme.statusConnected,
        label: appLocalizations.connected,
      ),
      CoreStatus.connecting => _DashboardConnectionStatus(
        color: colorScheme.statusWarning,
        label: appLocalizations.connecting,
      ),
      CoreStatus.disconnected => _DashboardConnectionStatus(
        color: colorScheme.onSurfaceVariant,
        label: appLocalizations.disconnected,
      ),
    };
  }
}
