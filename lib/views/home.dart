import 'dart:async';

import 'package:fl_clash/common/common.dart';
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

/// A pending connect/disconnect gives up waiting after this, and the view
/// falls back to the core's real state.
const _pendingTimeout = Duration(seconds: 20);

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

enum HomeConnectionState {
  notConnected,
  connecting,
  connected,
  disconnecting,
  suspended,
}

class _ConnectionHeader extends ConsumerStatefulWidget {
  const _ConnectionHeader();

  @override
  ConsumerState<_ConnectionHeader> createState() => _ConnectionHeaderState();
}

class _ConnectionHeaderState extends ConsumerState<_ConnectionHeader> {
  /// The state the user asked for and the core hasn't reached yet.
  bool? _target;
  Timer? _pendingTimer;

  @override
  void initState() {
    super.initState();
    ref.listenManual(isStartProvider, (_, isStart) {
      if (_target == isStart) {
        _clearPending();
      }
    });
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  void _clearPending() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    if (mounted && _target != null) {
      setState(() => _target = null);
    }
  }

  void _toggle() {
    final target = !ref.read(isStartProvider);
    setState(() => _target = target);
    _pendingTimer?.cancel();
    _pendingTimer = Timer(_pendingTimeout, _clearPending);
    debouncer.call(FunctionTag.updateStatus, () {
      globalState.container
          .read(setupActionProvider.notifier)
          .updateStatus(target, isInit: !ref.read(initProvider));
    }, duration: commonDuration);
  }

  HomeConnectionState _state(bool isStart, bool suspend) {
    final target = _target;
    if (target != null && target != isStart) {
      return target
          ? HomeConnectionState.connecting
          : HomeConnectionState.disconnecting;
    }
    if (isStart && suspend) {
      return HomeConnectionState.suspended;
    }
    return isStart
        ? HomeConnectionState.connected
        : HomeConnectionState.notConnected;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colors = context.colorScheme;
    final isStart = ref.watch(isStartProvider);
    final suspend = ref.watch(suspendProvider);
    final state = _state(isStart, suspend);
    final isPending =
        state == HomeConnectionState.connecting ||
        state == HomeConnectionState.disconnecting;

    final (IconData icon, Color color, String title) = switch (state) {
      HomeConnectionState.connected => (
        PanoramaIcons.connection.connected,
        colors.success,
        appLocalizations.connected,
      ),
      HomeConnectionState.suspended => (
        PanoramaIcons.status.partial,
        colors.warning,
        appLocalizations.suspended,
      ),
      HomeConnectionState.connecting => (
        PanoramaIcons.connection.connecting,
        colors.labelSecondary,
        appLocalizations.stateConnecting,
      ),
      HomeConnectionState.disconnecting => (
        PanoramaIcons.connection.connecting,
        colors.labelSecondary,
        appLocalizations.stateDisconnecting,
      ),
      HomeConnectionState.notConnected => (
        PanoramaIcons.connection.disconnected,
        colors.labelSecondary,
        appLocalizations.stateNotConnected,
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
          if (isStart && !isPending) ...[
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
            child: isStart && !isPending
                ? FilledButton.tonalIcon(
                    onPressed: _toggle,
                    icon: const Icon(Icons.power_settings_new),
                    label: Text(appLocalizations.disconnectAction),
                  )
                : FilledButton.icon(
                    onPressed: isPending ? null : _toggle,
                    icon: isPending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.power_settings_new),
                    label: Text(
                      isPending ? title : appLocalizations.connectAction,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile / node / mode
// ---------------------------------------------------------------------------

/// The node traffic actually leaves through for the main group: GLOBAL in
/// global mode, the first visible group in rule mode, following nested
/// groups down to a leaf. Null in direct mode or before groups load.
({String group, String node, String? testUrl})? _currentRoute(WidgetRef ref) {
  final mode = ref.watch(
    patchClashConfigProvider.select((state) => state.mode),
  );
  final groups = ref.watch(groupsProvider);
  final selectedMap = ref.watch(selectedMapProvider);
  final Group? main = switch (mode) {
    Mode.direct => null,
    Mode.global => groups.getGroup(GroupName.GLOBAL.name),
    Mode.rule =>
      groups
          .where((group) => group.hidden == false)
          .where((group) => group.name != GroupName.GLOBAL.name)
          .firstOrNull,
  };
  if (main == null) {
    return null;
  }
  final resolved = computeRealSelectedProxyState(
    main.name,
    groups: groups,
    selectedMap: selectedMap,
  );
  if (resolved.proxyName.isEmpty || resolved.proxyName == main.name) {
    return null;
  }
  return (
    group: main.name,
    node: resolved.proxyName,
    testUrl: resolved.testUrl,
  );
}

class _RouteSection extends ConsumerWidget {
  const _RouteSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final profile = ref.watch(currentProfileProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final route = _currentRoute(ref);
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
            height: 36,
            margin: const EdgeInsets.only(top: 8),
            child: CommonTabBar<Mode>(
              groupValue: mode,
              thumbColor: context.colorScheme.surface,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              children: {
                for (final item in Mode.values)
                  item: Text(
                    Intl.message(item.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        ListItem(
          title: Text(appLocalizations.systemProxy),
          trailing: Switch(
            value: systemProxy,
            onChanged: (value) => ref
                .read(networkSettingProvider.notifier)
                .update((state) => state.copyWith(systemProxy: value)),
          ),
        ),
        ListItem(
          title: Text(appLocalizations.tun),
          trailing: Switch(
            value: tun,
            onChanged: (value) => ref
                .read(patchClashConfigProvider.notifier)
                .update((state) => state.copyWith.tun(enable: value)),
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
