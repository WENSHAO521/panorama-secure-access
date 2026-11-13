import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/conflicts.dart';
import 'package:fl_clash/common/network_diagnosis.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkDiagnosisView extends ConsumerStatefulWidget {
  const NetworkDiagnosisView({super.key});

  @override
  ConsumerState<NetworkDiagnosisView> createState() =>
      _NetworkDiagnosisViewState();
}

class _NetworkDiagnosisViewState extends ConsumerState<NetworkDiagnosisView> {
  List<DiagnosisResult>? _results;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<NetworkObservations> _observe() async {
    final clash = ref.read(patchClashConfigProvider);
    final running = ref.read(runTimeProvider) != null;
    final coreStatus = ref.read(coreStatusProvider);
    final desktop = system.isDesktop;
    final port = clash.mixedPort;
    final systemProxyPort = await proxy?.readLoopbackProxyPort();
    final connected = running && coreStatus == CoreStatus.connected;
    final (dnsError, ipv4Error, ipv6Error, request) = await (
      probeDns(),
      probeTcp('1.1.1.1'),
      probeTcp('2606:4700:4700::1111'),
      connected
          ? probeProxyRequest(port, ref.read(realTestUrlProvider()))
          : Future.value((null, null)),
    ).wait;
    return NetworkObservations(
      desktop: desktop,
      running: running,
      coreStatus: coreStatus,
      mixedPort: port,
      mixedPortListening: await probePortListening(port),
      otherClients: desktop ? await findConflictingProcesses() : const [],
      systemProxyWanted: ref.read(networkSettingProvider).systemProxy,
      systemProxyReadable: proxy != null && !Platform.isWindows,
      systemProxyPort: systemProxyPort,
      systemProxyPortListening: systemProxyPort == null
          ? null
          : await probePortListening(systemProxyPort),
      tunEnabled: clash.tun.enable,
      tunAuthorized: desktop && clash.tun.enable
          ? await system.checkIsAdmin()
          : null,
      dnsError: dnsError,
      ipv4Error: ipv4Error,
      ipv6Error: ipv6Error,
      ipv6Enabled: clash.ipv6,
      proxyStatus: request.$1,
      proxyError: request.$2,
      canFlushDns: Platform.isWindows || Platform.isLinux,
    );
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      final results = gradeNetworkDiagnosis(await _observe());
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _repair(DiagnosisRepair repair) async {
    switch (repair) {
      case DiagnosisRepair.restartCore:
        await ref.read(coreActionProvider.notifier).restartCore();
      case DiagnosisRepair.switchPort:
        final free = await nextFreePort(
          ref.read(patchClashConfigProvider).mixedPort,
        );
        if (free != null) {
          ref
              .read(patchClashConfigProvider.notifier)
              .update((state) => state.copyWith(mixedPort: free));
        }
      case DiagnosisRepair.reapplySystemProxy:
        await systemProxyQueue?.apply(ref.read(proxyStateProvider));
      case DiagnosisRepair.clearStaleProxy:
        await systemProxyQueue?.recoverStale();
      case DiagnosisRepair.authorizeTun:
        await system.authorizeCore();
      case DiagnosisRepair.disableIpv6:
        ref
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith(ipv6: false));
      case DiagnosisRepair.flushDns:
        await flushDns();
    }
    await _run();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final results = _results;
    final problems = results
        ?.where((item) => item.level == DiagnosisLevel.failure)
        .length;
    return Scaffold(
      title: appLocalizations.networkDiagnosis,
      isLoading: _running,
      primaryAction: IconButtonData(
        glyph: AppGlyphs.refresh,
        onPressed: _run,
        tooltip: appLocalizations.networkDiagnosisRun,
        isLoading: _running,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (problems != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                problems == 0
                    ? appLocalizations.networkDiagnosisAllPassed
                    : appLocalizations.networkDiagnosisProblems(problems),
              ),
            ),
          if (results != null)
            generateSection(
              items: [
                for (final result in results)
                  _DiagnosisItem(
                    result: result,
                    onRepair: _running ? null : _repair,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DiagnosisItem extends StatelessWidget {
  final DiagnosisResult result;
  final void Function(DiagnosisRepair repair)? onRepair;

  const _DiagnosisItem({required this.result, required this.onRepair});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final (glyph, color) = switch (result.level) {
      DiagnosisLevel.ok => (AppGlyphs.checkCircle, colorScheme.primary),
      DiagnosisLevel.warning => (AppGlyphs.warning, colorScheme.tertiary),
      DiagnosisLevel.failure => (AppGlyphs.error, colorScheme.error),
      DiagnosisLevel.skipped => (AppGlyphs.removeCircle, colorScheme.outline),
    };
    final repair = result.repair;
    final detail = result.detail;
    return ListItem(
      leading: GlyphIcon(glyph, color: color),
      title: Text(result.check.label(appLocalizations)),
      subtitle: detail == null ? null : Text(detail),
      trailing: repair == null || onRepair == null
          ? null
          : TextButton(
              onPressed: () => onRepair!(repair),
              child: Text(repair.label(appLocalizations)),
            ),
    );
  }
}

extension on DiagnosisCheck {
  String label(AppLocalizations l) => switch (this) {
    DiagnosisCheck.core => l.diagnosisCore,
    DiagnosisCheck.mixedPort => l.diagnosisMixedPort,
    DiagnosisCheck.otherClients => l.diagnosisOtherClients,
    DiagnosisCheck.systemProxy => l.diagnosisSystemProxy,
    DiagnosisCheck.tunAuthorization => l.diagnosisTun,
    DiagnosisCheck.dns => l.diagnosisDns,
    DiagnosisCheck.ipv4 => l.diagnosisIpv4,
    DiagnosisCheck.ipv6 => l.diagnosisIpv6,
    DiagnosisCheck.proxyRequest => l.diagnosisProxyRequest,
  };
}

extension on DiagnosisRepair {
  String label(AppLocalizations l) => switch (this) {
    DiagnosisRepair.restartCore => l.repairRestartCore,
    DiagnosisRepair.switchPort => l.portInUseSwitch,
    DiagnosisRepair.reapplySystemProxy => l.repairReapplyProxy,
    DiagnosisRepair.clearStaleProxy => l.repairClearProxy,
    DiagnosisRepair.authorizeTun => l.repairAuthorizeTun,
    DiagnosisRepair.disableIpv6 => l.repairDisableIpv6,
    DiagnosisRepair.flushDns => l.repairFlushDns,
  };
}

class NetworkDiagnosisItem extends StatelessWidget {
  const NetworkDiagnosisItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.wrench),
      title: Text(context.appLocalizations.networkDiagnosis),
      widget: const NetworkDiagnosisView(),
    );
  }
}
