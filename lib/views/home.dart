import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/adaptive/panorama_breakpoints.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/network_insight/service_check/region.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/network_insight.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _maxContentWidth = 640.0;

/// The first thing users see: whether they're connected, through what, and
/// one control to change it (brief §23-25). Sections, not a card wall;
/// nothing animates once connected.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );
    return CommonScaffold(
      title: context.appLocalizations.home,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = ((constraints.maxWidth - _maxContentWidth) / 2).clamp(
            0.0,
            double.infinity,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 24),
            children: hasProfile
                ? [
                    const _ConnectionHeader(),
                    const Divider(height: 32),
                    const _RouteSection(),
                    const Divider(height: 24),
                    const _NetworkSection(),
                    if (system.isDesktop) ...[
                      const Divider(height: 24),
                      const _OptionsSection(),
                    ],
                  ]
                : const [_NoProfile()],
          );
        },
      ),
    );
  }
}

void _goTo(PageLabel label) {
  globalState.container.read(currentPageLabelProvider.notifier).toPage(label);
}

/// Network Insight is a sidebar destination on desktop but lives under
/// Settings > More on mobile, so open it as a page when it isn't in the
/// current navigation.
void _openNetworkInsight(BuildContext context, WidgetRef ref) {
  final items = ref.read(currentNavigationItemsStateProvider).value;
  if (items.any((item) => item.label == PageLabel.networkInsight)) {
    _goTo(PageLabel.networkInsight);
    return;
  }
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const NetworkInsightView()));
}

// ---------------------------------------------------------------------------
// Connection status + main control
// ---------------------------------------------------------------------------

class _ConnectionHeader extends ConsumerWidget {
  const _ConnectionHeader();

  void _toggle(WidgetRef ref) {
    ref.read(connectionRequestProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colors = context.colorScheme;
    final state = ref.watch(connectionPhaseProvider);
    final isStart = ref.watch(isStartProvider);
    final isPending = state.isPending;

    final (IconData icon, Color color, String title) = switch (state) {
      ConnectionPhase.connected => (
        PanoramaIcons.connection.connected,
        colors.success,
        appLocalizations.connected,
      ),
      ConnectionPhase.suspended => (
        PanoramaIcons.status.partial,
        colors.warning,
        appLocalizations.suspended,
      ),
      ConnectionPhase.connecting => (
        PanoramaIcons.connection.connecting,
        colors.labelSecondary,
        appLocalizations.stateConnecting,
      ),
      ConnectionPhase.disconnecting => (
        PanoramaIcons.connection.connecting,
        colors.labelSecondary,
        appLocalizations.stateDisconnecting,
      ),
      ConnectionPhase.notConnected => (
        PanoramaIcons.connection.disconnected,
        colors.labelSecondary,
        appLocalizations.stateNotConnected,
      ),
      ConnectionPhase.error => (
        PanoramaIcons.connection.error,
        colors.danger,
        appLocalizations.coreStopped,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(title, style: context.textTheme.headlineSmall),
                ),
              ),
            ],
          ),
          if (isStart && !isPending && state != ConnectionPhase.error) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Consumer(
                builder: (_, ref, _) {
                  final runTime = ref.watch(runTimeProvider);
                  return Text(
                    appLocalizations.connectedFor(utils.getTimeText(runTime)),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.labelSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: switch (state) {
              ConnectionPhase.error => FilledButton.icon(
                onPressed: () =>
                    ref.read(coreActionProvider.notifier).restartCore(),
                icon: Icon(PanoramaIcons.actions.reset),
                label: Text(appLocalizations.restart),
              ),
              _ when isStart && !isPending => FilledButton.tonalIcon(
                onPressed: () => _toggle(ref),
                icon: Icon(PanoramaIcons.connection.power),
                label: Text(appLocalizations.disconnectAction),
              ),
              _ => FilledButton.icon(
                onPressed: isPending ? null : () => _toggle(ref),
                icon: isPending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(PanoramaIcons.connection.power),
                label: Text(isPending ? title : appLocalizations.connectAction),
              ),
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile / node / mode
// ---------------------------------------------------------------------------

class _RouteSection extends ConsumerWidget {
  const _RouteSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentHeight =
        PanoramaLayoutClass.of(context) == PanoramaLayoutClass.compact
        ? 48.0
        : 28.0;
    final appLocalizations = context.appLocalizations;
    final profile = ref.watch(currentProfileProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final route = ref.watch(currentRouteProvider);
    final delay = route == null
        ? null
        : ref.watch(
            delayProvider(proxyName: route.node, testUrl: route.testUrl),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListItem(
          title: Text(appLocalizations.profile),
          subtitle: Text(profile?.realLabel ?? '—'),
          onTap: () => _goTo(PageLabel.profiles),
        ),
        ListItem(
          title: Text(appLocalizations.currentNode),
          // EmojiText builds a RichText, which doesn't inherit the ambient
          // text style, so it needs the subtitle style explicitly.
          subtitle: EmojiText(
            route == null
                ? (mode == Mode.direct ? appLocalizations.direct : '—')
                : '${route.node}  ·  ${route.group}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.labelSecondary,
            ),
          ),
          trailing: delay == null || delay == 0 ? null : _Latency(delay: delay),
          onTap: () => _goTo(PageLabel.proxies),
        ),
        ListItem(
          title: Text(appLocalizations.outboundMode),
          subtitle: Container(
            margin: const EdgeInsets.only(top: 8),
            child: CommonTabBar<Mode>(
              groupValue: mode,
              thumbColor: context.colorScheme.surface,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              children: {
                for (final item in Mode.values)
                  item: SizedBox(
                    // Touch layouts get 48 px segments (§99).
                    height: segmentHeight,
                    child: Center(
                      child: Text(
                        Intl.message(item.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              },
              onValueChanged: (value) {
                if (value == null || value == mode) {
                  return;
                }
                globalState.container
                    .read(setupActionProvider.notifier)
                    .changeMode(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Latency extends StatelessWidget {
  final int delay;

  const _Latency({required this.delay});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final (String text, Color color) = switch (delay) {
      < 0 => (context.appLocalizations.timeout, colors.latencyPoor),
      < 600 => ('$delay ms', colors.latencyGood),
      _ => ('$delay ms', colors.latencyMedium),
    };
    return Text(
      text,
      style: context.textTheme.bodyMedium?.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Network: exit IP, services, speed
// ---------------------------------------------------------------------------

class _NetworkSection extends ConsumerWidget {
  const _NetworkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final isStart = ref.watch(isStartProvider);
    // The dashboard's existing IP lookup: it only runs while the user keeps
    // the network-detection widget enabled (their opt-out), so Home shows
    // "—" rather than starting lookups of its own.
    final ipInfo = ref.watch(
      networkDetectionProvider.select((state) => state.ipInfo),
    );
    final services = ref.watch(serviceAvailabilityProvider);
    final region = normalizeRegionCode(ipInfo?.countryCode);
    final exitDetails = [
      ?ipInfo?.countryName,
      if (ipInfo?.asn != null) 'AS${ipInfo!.asn}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListHeader(title: appLocalizations.network),
        ListItem(
          title: Text(appLocalizations.exitIp),
          subtitle: ipInfo == null
              ? const Text('—')
              : Text(
                  [
                    '${region == null ? '' : '${regionFlag(region)} '}'
                        '${ipInfo.ip}',
                    if (exitDetails.isNotEmpty) exitDetails,
                  ].join('\n'),
                  style: TextStyle(
                    fontFamilyFallback: [FontFamily.twEmoji.value],
                  ),
                ),
          onTap: () => _openNetworkInsight(context, ref),
        ),
        ListItem(
          title: Text(appLocalizations.servicesLabel),
          subtitle: Text(
            services.checkedCount == 0
                ? appLocalizations.statusNotChecked
                : appLocalizations.servicesAvailable(
                    '${services.availableCount}',
                    '${services.results.length}',
                  ),
          ),
          onTap: () => _openNetworkInsight(context, ref),
        ),
        if (isStart)
          ListItem(
            title: Text(appLocalizations.networkSpeed),
            subtitle: Consumer(
              builder: (_, ref, _) {
                final traffics = ref.watch(trafficsProvider).list;
                final last = traffics.isEmpty ? const Traffic() : traffics.last;
                return Text(
                  last.speedText,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop quick options
// ---------------------------------------------------------------------------

class _OptionsSection extends ConsumerWidget {
  const _OptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final tun = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListHeader(title: appLocalizations.options),
        // One node per row, so the switch is read with its label.
        MergeSemantics(
          child: ListItem(
            title: Text(appLocalizations.systemProxy),
            trailing: Switch(
              value: systemProxy,
              onChanged: (value) => ref
                  .read(networkSettingProvider.notifier)
                  .update((state) => state.copyWith(systemProxy: value)),
            ),
          ),
        ),
        MergeSemantics(
          child: ListItem(
            title: Text(appLocalizations.tun),
            trailing: Switch(
              value: tun,
              onChanged: (value) => ref
                  .read(patchClashConfigProvider.notifier)
                  .update((state) => state.copyWith.tun(enable: value)),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// No profile yet
// ---------------------------------------------------------------------------

class _NoProfile extends StatelessWidget {
  const _NoProfile();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
      child: Column(
        children: [
          Icon(
            PanoramaIcons.navigation.profiles,
            size: 40,
            color: context.colorScheme.labelSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            appLocalizations.nullProfileDesc,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _goTo(PageLabel.profiles),
            icon: Icon(PanoramaIcons.actions.add),
            label: Text(appLocalizations.addProfile),
          ),
        ],
      ),
    );
  }
}
