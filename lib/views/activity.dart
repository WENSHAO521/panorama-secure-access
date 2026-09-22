import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/views/connection/requests.dart';
import 'package:fl_clash/views/logs.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kSegmentBarHeight = 44.0;

/// Connections, Requests and Logs under one destination, switched by a
/// segmented control in the app bar. Only the selected view is built, so a
/// hidden tab never keeps polling the core.
class ActivityView extends ConsumerStatefulWidget {
  const ActivityView({super.key});

  @override
  ConsumerState<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends ConsumerState<ActivityView> {
  ActivityTab _tab = ActivityTab.connections;

  String _label(ActivityTab tab) {
    final appLocalizations = context.appLocalizations;
    return switch (tab) {
      ActivityTab.connections => appLocalizations.connections,
      ActivityTab.requests => appLocalizations.requests,
      ActivityTab.logs => appLocalizations.logs,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Logs is only offered while log capture is enabled, as before.
    final openLogs = ref.watch(
      appSettingProvider.select((state) => state.openLogs),
    );
    final tabs = [
      ActivityTab.connections,
      ActivityTab.requests,
      if (openLogs) ActivityTab.logs,
    ];
    final tab = tabs.contains(_tab) ? _tab : ActivityTab.connections;
    final colorScheme = context.colorScheme;
    return ScaffoldHeaderScope(
      title: context.appLocalizations.activity,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_kSegmentBarHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: CommonTabBar<ActivityTab>(
            groupValue: tab,
            thumbColor: colorScheme.surface,
            backgroundColor: colorScheme.surfaceContainerHighest,
            children: {
              for (final item in tabs)
                item: Text(
                  _label(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            },
            onValueChanged: (value) {
              if (value == null || value == _tab) {
                return;
              }
              setState(() {
                _tab = value;
              });
            },
          ),
        ),
      ),
      child: switch (tab) {
        ActivityTab.connections => const ConnectionsView(),
        ActivityTab.requests => const RequestsView(),
        ActivityTab.logs => const LogsView(),
      },
    );
  }
}
