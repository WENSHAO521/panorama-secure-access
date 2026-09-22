import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fixed, non-removable connection-state summary shown above the
/// customizable dashboard grid (see [DashboardView]). The dashboard grid
/// itself stays exactly as it was — this doesn't replace or gate any of
/// its widgets — it only makes "am I connected, and to what" the first
/// thing on Home instead of something you find inside the toolbar/FAB,
/// per the design spec's Home hierarchy. Deliberately plain content-layer
/// styling (no [GlassSurface], no card) — this is status text, not chrome.
class ConnectionStatusHeader extends ConsumerWidget {
  const ConnectionStatusHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coreStatus = ref.watch(coreStatusProvider);
    final profile = ref.watch(currentProfileProvider);
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;

    final (String statusText, Color statusColor, IconData statusIcon) =
        switch (coreStatus) {
          CoreStatus.connected => (
            appLocalizations.connected,
            colorScheme.statusConnected,
            AppIcons.connected,
          ),
          CoreStatus.connecting => (
            appLocalizations.connecting,
            colorScheme.statusWarning,
            AppIcons.connecting,
          ),
          CoreStatus.disconnected => (
            appLocalizations.disconnected,
            colorScheme.onSurfaceVariant,
            AppIcons.disconnected,
          ),
        };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Semantics(
        label: '${appLocalizations.coreStatus}：$statusText',
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: context.title2Style?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile != null)
                    Text(
                      profile.realLabel,
                      style: context.subheadlineStyle?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
