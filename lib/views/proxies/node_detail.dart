import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/network_insight/identity.dart';
import 'package:fl_clash/features/network_insight/service_check/region.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/network_insight.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Long-press (touch) or right-click (desktop) on a proxy card.
Future<void> showNodeDetail(BuildContext context, Proxy proxy) {
  return showSheet(
    context: context,
    props: const SheetProps(isScrollControlled: true),
    builder: (_) => NodeDetailSheet(proxy: proxy),
  );
}

/// What one node can do, measured through a probe pinned to it
/// (brief §48-53). Testing never changes the user's selection.
class NodeDetailSheet extends ConsumerWidget {
  final Proxy proxy;

  const NodeDetailSheet({super.key, required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final report = ref.watch(
      nodeDiagnosticsProvider.select((state) => state[proxy.name]),
    );
    final notifier = ref.read(nodeDiagnosticsProvider.notifier);
    final isRunning = report?.isRunning ?? false;
    final checkedAt = report?.checkedAt;
    final isStale =
        checkedAt != null &&
        DateTime.now().difference(checkedAt) > nodeReportTtl;

    return AdaptiveSheetScaffold(
      title: proxy.name,
      actions: [
        IconButtonData(
          icon: PanoramaIcons.actions.copy,
          onPressed: () => Clipboard.setData(ClipboardData(text: proxy.name)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListItem(
            title: Text(appLocalizations.proxyType),
            trailing: Text(proxy.type, style: context.textTheme.bodyMedium),
          ),
          ListItem(
            title: Text(appLocalizations.delay),
            trailing: Text(
              report?.delayMs != null ? '${report!.delayMs} ms' : '—',
              style: context.textTheme.bodyMedium,
            ),
          ),
          ListItem(
            title: Text(appLocalizations.exitIp),
            subtitle: _ExitAddresses(report: report),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                if (isRunning)
                  TextButton(
                    onPressed: notifier.cancel,
                    child: Text(appLocalizations.cancel),
                  )
                else
                  FilledButton.tonal(
                    onPressed: () => notifier.test(proxy.name),
                    child: Text(appLocalizations.testNode),
                  ),
                const SizedBox(width: 12),
                if (isRunning)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (checkedAt != null)
                  Flexible(
                    child: Text(
                      isStale
                          ? appLocalizations.staleResult
                          : appLocalizations.checkedAt(
                              DateFormat.Hms().format(checkedAt),
                            ),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.labelSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              report?.error == 'notConnected'
                  ? appLocalizations.nodeTestNotConnected
                  : report?.error ?? appLocalizations.nodeTestTip,
              style: context.textTheme.bodySmall?.copyWith(
                color: report?.error != null
                    ? context.colorScheme.danger
                    : context.colorScheme.labelSecondary,
              ),
            ),
          ),
          if (report != null && report.services.isNotEmpty) ...[
            const Divider(height: 16),
            ListHeader(
              title: appLocalizations.serviceAvailability,
              subTitle: isRunning
                  ? null
                  : appLocalizations.servicesAvailable(
                      '${report.availableCount}',
                      '${report.services.length}',
                    ),
            ),
            for (final result in report.services)
              PanoramaServiceRow(result: result),
          ],
        ],
      ),
    );
  }
}

class _ExitAddresses extends StatelessWidget {
  final NodeReport? report;

  const _ExitAddresses({required this.report});

  String _line(IpFamilyProbe probe, String unavailable) {
    final ip = probe.exitIp;
    if (ip == null) {
      return '${probe.family == IpFamily.ipv4 ? 'IPv4' : 'IPv6'}  $unavailable';
    }
    final region = probe.regionCode;
    return region == null ? ip : '$ip  ${regionFlag(region)} $region';
  }

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    final ipv4 = report?.ipv4;
    final ipv6 = report?.ipv6;
    if (ipv4 == null && ipv6 == null) {
      return const Text('—');
    }
    final unavailable = context.appLocalizations.notAvailable;
    return SelectableText(
      [
        if (ipv4 != null) _line(ipv4, unavailable),
        if (ipv6 != null) _line(ipv6, unavailable),
      ].join('\n'),
      style: context.textTheme.bodyMedium?.toJetBrainsMono.copyWith(
        color: context.colorScheme.labelSecondary,
        fontFamilyFallback: [FontFamily.twEmoji.value],
      ),
    );
  }
}
