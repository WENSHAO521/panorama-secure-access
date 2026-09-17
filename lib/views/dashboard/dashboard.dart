import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// "Direction C — editorial minimal" prototype: this screen alone, in
// isolation, is restyled to the redesign proposal's flat/ledger look
// (see EditorialPalette). It intentionally drops the drag-to-customize
// widget grid the classic dashboard had, in favour of a fixed layout
// that mirrors the design mockup — everything else in the app (nav
// rail, other screens' glass surfaces) is untouched for now.
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  void _handleToPage(PageLabel pageLabel) {
    globalState.container
        .read(currentPageLabelProvider.notifier)
        .toPage(pageLabel);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    return Theme(
      data: editorialLightTheme(context),
      child: CommonScaffold(
        backgroundColor: EditorialPalette.paper,
        appBar: AppBar(
          backgroundColor: EditorialPalette.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Text(
            appLocalizations.dashboard,
            style: editorialSerif(size: 20, weight: FontWeight.w600),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 3,
                margin: const EdgeInsets.only(bottom: 28),
                color: EditorialPalette.accent,
              ),
              const _StatusLine(),
              const SizedBox(height: 26),
              const _ModeRow(),
              const SizedBox(height: 10),
              const _Ledger(),
              const SizedBox(height: 28),
              _SubscriptionFooter(
                onOpenProfiles: () => _handleToPage(PageLabel.profiles),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends ConsumerWidget {
  const _StatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final coreStatus = ref.watch(coreStatusProvider);
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    final profile = ref.watch(currentProfileProvider);
    final selectedNode = profile != null && profile.currentGroupName != null
        ? profile.selectedMap[profile.currentGroupName]
        : null;
    final isStart = ref.watch(isStartProvider);
    final suspend = ref.watch(suspendProvider);
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );

    final (String statusText, Color dotColor) = switch (coreStatus) {
      CoreStatus.connected => (
        appLocalizations.connected,
        context.colorScheme.statusConnected,
      ),
      CoreStatus.connecting => (
        appLocalizations.connecting,
        context.colorScheme.statusWarning,
      ),
      CoreStatus.disconnected => (
        appLocalizations.disconnected,
        EditorialPalette.muted,
      ),
    };

    final captionParts = [
      Intl.message(mode.name),
      if (selectedNode != null && selectedNode.isNotEmpty) selectedNode,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: statusText,
                  style: editorialSerif(size: 22, weight: FontWeight.w600),
                ),
                TextSpan(
                  text: '  ·  ${captionParts.join('  ·  ')}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: EditorialPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Deliberately NOT reusing appLocalizations.connected/disconnected
        // here — that's the headline's word for coreStatus, a different
        // signal from isStart (the switch below), and the two can
        // legitimately disagree (e.g. core still shutting down after the
        // user flips the switch off). Showing uptime instead of a second,
        // possibly-contradictory status word sidesteps that entirely.
        if (isStart)
          Consumer(
            builder: (_, ref, _) {
              final runTime = ref.watch(runTimeProvider);
              return Text(
                suspend ? appLocalizations.suspended : utils.getTimeText(runTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: EditorialPalette.muted,
                ),
              );
            },
          ),
        const SizedBox(width: 8),
        Switch(
          value: isStart,
          activeTrackColor: EditorialPalette.accent,
          onChanged: hasProfile
              ? (value) {
                  globalState.container
                      .read(setupActionProvider.notifier)
                      .updateStatus(value, isInit: !ref.read(initProvider));
                }
              : null,
        ),
      ],
    );
  }
}

class _ModeRow extends ConsumerWidget {
  const _ModeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    return Row(
      children: [
        Text(
          appLocalizations.outboundMode,
          style: const TextStyle(fontSize: 13, color: EditorialPalette.muted),
        ),
        const SizedBox(width: 26),
        for (final item in Mode.values)
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: GestureDetector(
              onTap: () {
                globalState.container
                    .read(setupActionProvider.notifier)
                    .changeMode(item);
              },
              child: Container(
                padding: const EdgeInsets.only(bottom: 3),
                decoration: item == mode
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: EditorialPalette.accent,
                            width: 2,
                          ),
                        ),
                      )
                    : null,
                child: Text(
                  Intl.message(item.name),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: item == mode
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: item == mode
                        ? EditorialPalette.ink
                        : EditorialPalette.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Ledger extends ConsumerWidget {
  const _Ledger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final traffics = ref.watch(trafficsProvider).list;
    final lastTraffic = traffics.isEmpty ? const Traffic() : traffics.last;
    final totalTraffic = ref.watch(totalTrafficProvider);
    final localIp = ref.watch(localIpProvider);
    final networkDetection = ref.watch(networkDetectionProvider);
    final ipInfo = networkDetection.ipInfo;

    return Column(
      children: [
        LedgerRow(
          label: appLocalizations.networkSpeed,
          value: Text(
            lastTraffic.speedText,
            style: editorialSerif(size: 17, weight: FontWeight.w400),
          ),
        ),
        LedgerRow(
          label: appLocalizations.trafficUsage,
          value: Text(
            '${totalTraffic.up.traffic.show} ↑  ${totalTraffic.down.traffic.show} ↓',
            style: editorialSerif(size: 17, weight: FontWeight.w400),
          ),
        ),
        const _MemoryRow(),
        LedgerRow(
          label: appLocalizations.intranetIP,
          value: Text(
            localIp == null || localIp.isEmpty
                ? appLocalizations.noNetwork
                : localIp,
            style: editorialSerif(size: 17, weight: FontWeight.w400),
          ),
        ),
        LedgerRow(
          showDivider: false,
          label: appLocalizations.networkDetection,
          value: Text(
            ipInfo?.ip ??
                (networkDetection.isLoading
                    ? '···'
                    : appLocalizations.noNetwork),
            style: editorialSerif(size: 17, weight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

class _MemoryRow extends StatefulWidget {
  const _MemoryRow();

  @override
  State<_MemoryRow> createState() => _MemoryRowState();
}

class _MemoryRowState extends State<_MemoryRow>
    with WidgetsBindingObserver, ActivePollingMixin<_MemoryRow> {
  num _memory = 0;

  @override
  Duration get pollInterval => const Duration(seconds: 2);

  @override
  Future<void> poll(PollGuard isCurrent) async {
    final memory = await _readMemory();
    if (memory == null || !isCurrent() || !mounted) {
      return;
    }
    setState(() {
      _memory = memory;
    });
  }

  Future<num?> _readMemory() async {
    try {
      final rss = ProcessInfo.currentRss;
      final coreConnected =
          globalState.container.read(coreStatusProvider) ==
          CoreStatus.connected;
      if (system.isDesktop && coreConnected) {
        return await coreController.getMemory() + rss;
      }
      return rss;
    } catch (error) {
      commonPrint.log(
        'updateMemory error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final traffic = _memory.traffic;
    return LedgerRow(
      label: context.appLocalizations.memoryInfo,
      value: Text(
        '${traffic.value} ${traffic.unit}',
        style: editorialSerif(size: 17, weight: FontWeight.w400),
      ),
    );
  }
}

class _SubscriptionFooter extends ConsumerWidget {
  final VoidCallback onOpenProfiles;

  const _SubscriptionFooter({required this.onOpenProfiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final profile = ref.watch(currentProfileProvider);
    if (profile == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onOpenProfiles,
          child: Text(
            appLocalizations.profiles,
            style: const TextStyle(
              fontSize: 13,
              color: EditorialPalette.ink,
              decoration: TextDecoration.underline,
              decorationColor: EditorialPalette.ink,
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.only(top: 22),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: EditorialPalette.ink)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalizations.profiles,
                  style: const TextStyle(
                    fontSize: 13,
                    color: EditorialPalette.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: EditorialPalette.ink,
                  ),
                ),
                if (profile.subscriptionInfo != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 320,
                    child: SubscriptionInfoView(
                      subscriptionInfo: profile.subscriptionInfo,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onOpenProfiles,
            child: Text(
              appLocalizations.update,
              style: const TextStyle(
                fontSize: 13,
                color: EditorialPalette.ink,
                decoration: TextDecoration.underline,
                decorationColor: EditorialPalette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
