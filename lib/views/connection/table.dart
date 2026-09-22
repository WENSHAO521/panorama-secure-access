import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Columns of the desktop connections table (brief §77).
enum ConnectionColumn {
  process,
  source,
  destination,
  rule,
  proxy,
  upload,
  download,
  duration;

  /// Byte counts and ages read best largest-first.
  bool get sortsDescendingFirst =>
      this == upload || this == download || this == duration;
}

@immutable
class ConnectionSort {
  final ConnectionColumn column;
  final bool ascending;

  const ConnectionSort(this.column, {required this.ascending});

  /// Clicking a header: a new column starts in its natural direction, the
  /// same column flips, and a third click goes back to the core's order.
  static ConnectionSort? next(ConnectionSort? current, ConnectionColumn tap) {
    if (current == null || current.column != tap) {
      return ConnectionSort(tap, ascending: !tap.sortsDescendingFirst);
    }
    if (current.ascending == tap.sortsDescendingFirst) {
      return null;
    }
    return ConnectionSort(tap, ascending: !current.ascending);
  }

  @override
  bool operator ==(Object other) =>
      other is ConnectionSort &&
      other.column == column &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(column, ascending);
}

extension TrackerInfoTableExt on TrackerInfo {
  String get sourceText => _hostPort(metadata.sourceIP, metadata.sourcePort);

  String get destinationText => _hostPort(
    metadata.host.isNotEmpty ? metadata.host : metadata.destinationIP,
    metadata.destinationPort,
  );

  String get ruleText => rulePayload.isNotEmpty ? '$rule($rulePayload)' : rule;

  /// The node that carries the connection. mihomo lists the chain from the
  /// node outwards, so it is the first entry.
  String get proxyText => chains.isEmpty ? '' : chains.first;

  /// Group → … → node, the order a user picks them in.
  String get chainText => chains.reversed.join(' → ');
}

String _hostPort(String host, String port) {
  if (host.isEmpty) return '';
  if (port.isEmpty) return host;
  return host.contains(':') ? '[$host]:$port' : '$host:$port';
}

/// Compact age of a connection: 45s, 3m 12s, 2h 05m, 3d 4h.
String formatElapsed(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final s = d.inSeconds;
  if (s < 60) return '${s}s';
  if (s < 3600) {
    return '${d.inMinutes}m ${(s % 60).toString().padLeft(2, '0')}s';
  }
  if (d.inHours < 24) {
    return '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
  }
  return '${d.inDays}d ${d.inHours % 24}h';
}

List<TrackerInfo> sortConnections(
  List<TrackerInfo> connections,
  ConnectionSort? sort,
) {
  if (sort == null) return connections;
  int compare(TrackerInfo a, TrackerInfo b) => switch (sort.column) {
    ConnectionColumn.process => a.metadata.process.toLowerCase().compareTo(
      b.metadata.process.toLowerCase(),
    ),
    ConnectionColumn.source => a.sourceText.compareTo(b.sourceText),
    ConnectionColumn.destination => a.destinationText.toLowerCase().compareTo(
      b.destinationText.toLowerCase(),
    ),
    ConnectionColumn.rule => a.ruleText.compareTo(b.ruleText),
    ConnectionColumn.proxy => a.proxyText.compareTo(b.proxyText),
    ConnectionColumn.upload => a.upload.compareTo(b.upload),
    ConnectionColumn.download => a.download.compareTo(b.download),
    // Older connections have been open longer.
    ConnectionColumn.duration => b.start.compareTo(a.start),
  };
  final sorted = List.of(connections);
  // List.sort isn't stable; fall back to the core's order on ties so rows
  // don't jump around between refreshes.
  final index = {
    for (var i = 0; i < connections.length; i++) connections[i].id: i,
  };
  sorted.sort((a, b) {
    final c = sort.ascending ? compare(a, b) : compare(b, a);
    return c != 0 ? c : index[a.id]!.compareTo(index[b.id]!);
  });
  return sorted;
}

/// High-density connections table for wide layouts (brief §77). Narrower
/// layouts keep the card rows (§78: no horizontally squeezed table).
class ConnectionsTable extends StatefulWidget {
  /// Content width below which the flexible columns (process, destination,
  /// rule, proxy) drop under ~100 px each next to the fixed ones.
  static const double minWidth = 900;

  final List<TrackerInfo> connections;
  final ScrollController? controller;
  final void Function(TrackerInfo trackerInfo) onOpen;
  final void Function(TrackerInfo trackerInfo) onClose;
  final void Function(String keyword) onFilter;

  /// Clock for the Duration column; tests pin it.
  final DateTime Function() now;

  const ConnectionsTable({
    super.key,
    required this.connections,
    required this.onOpen,
    required this.onClose,
    required this.onFilter,
    this.controller,
    this.now = DateTime.now,
  });

  @override
  State<ConnectionsTable> createState() => _ConnectionsTableState();
}

class _ConnectionsTableState extends State<ConnectionsTable> {
  ConnectionSort? _sort;

  @override
  Widget build(BuildContext context) {
    final rows = sortConnections(widget.connections, _sort);
    final now = widget.now();
    return Column(
      children: [
        _HeaderRow(
          sort: _sort,
          onSort: (column) {
            setState(() => _sort = ConnectionSort.next(_sort, column));
          },
        ),
        Divider(height: 1, color: context.colorScheme.separator),
        Expanded(
          // Fixed row height: layout cost stays flat with thousands of rows.
          child: ListView.builder(
            controller: widget.controller,
            itemCount: rows.length,
            itemExtent: _ConnectionRow.height,
            itemBuilder: (context, index) {
              final trackerInfo = rows[index];
              return _ConnectionRow(
                key: ValueKey(trackerInfo.id),
                trackerInfo: trackerInfo,
                now: now,
                striped: index.isOdd,
                onOpen: widget.onOpen,
                onClose: widget.onClose,
                onFilter: widget.onFilter,
              );
            },
          ),
        ),
      ],
    );
  }
}

// Column layout shared by the header and the rows.
const _flex = {
  ConnectionColumn.process: 3,
  ConnectionColumn.destination: 5,
  ConnectionColumn.rule: 4,
  ConnectionColumn.proxy: 3,
};
// Fixed widths fit their longest usual value: "255.255.255.255:65535" in
// the monospace face, "1023.9MB", "23h 59m", each plus a sort arrow.
const _fixed = {
  ConnectionColumn.source: 172.0,
  ConnectionColumn.upload: 96.0,
  ConnectionColumn.download: 96.0,
  ConnectionColumn.duration: 80.0,
};
const _numeric = {
  ConnectionColumn.upload,
  ConnectionColumn.download,
  ConnectionColumn.duration,
};
const _actionWidth = 40.0;
const _cellPadding = EdgeInsets.symmetric(horizontal: 8);

Widget _cell(ConnectionColumn column, Widget child) {
  final fixed = _fixed[column];
  final padded = Padding(padding: _cellPadding, child: child);
  return fixed != null
      ? SizedBox(width: fixed, child: padded)
      : Expanded(flex: _flex[column]!, child: padded);
}

String _columnLabel(BuildContext context, ConnectionColumn column) {
  final l = context.appLocalizations;
  return switch (column) {
    ConnectionColumn.process => l.process,
    ConnectionColumn.source => l.source,
    ConnectionColumn.destination => l.destination,
    ConnectionColumn.rule => l.rule,
    ConnectionColumn.proxy => l.proxy,
    ConnectionColumn.upload => l.upload,
    ConnectionColumn.download => l.download,
    ConnectionColumn.duration => l.duration,
  };
}

class _HeaderRow extends StatelessWidget {
  final ConnectionSort? sort;
  final ValueChanged<ConnectionColumn> onSort;

  const _HeaderRow({required this.sort, required this.onSort});

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelMedium?.copyWith(
      color: context.colorScheme.labelSecondary,
    );
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (final column in ConnectionColumn.values)
              _cell(
                column,
                _HeaderCell(
                  label: _columnLabel(context, column),
                  style: style,
                  numeric: _numeric.contains(column),
                  sortedAscending: sort?.column == column
                      ? sort!.ascending
                      : null,
                  onTap: () => onSort(column),
                ),
              ),
            const SizedBox(width: _actionWidth),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final TextStyle? style;
  final bool numeric;
  final bool? sortedAscending;
  final VoidCallback onTap;

  const _HeaderCell({
    required this.label,
    required this.style,
    required this.numeric,
    required this.sortedAscending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = sortedAscending == null
        ? null
        : Icon(
            sortedAscending!
                ? PanoramaIcons.actions.previous
                : PanoramaIcons.actions.next,
            size: 14,
            color: style?.color,
          );
    final l = context.appLocalizations;
    return Semantics(
      button: true,
      label: label,
      value: switch (sortedAscending) {
        null => null,
        true => l.sortedAscending,
        false => l.sortedDescending,
      },
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisAlignment: numeric
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (arrow != null) ...[const SizedBox(width: 2), arrow],
          ],
        ),
      ),
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  static const double height = 34;

  final TrackerInfo trackerInfo;
  final DateTime now;
  final bool striped;
  final void Function(TrackerInfo) onOpen;
  final void Function(TrackerInfo) onClose;
  final void Function(String) onFilter;

  const _ConnectionRow({
    super.key,
    required this.trackerInfo,
    required this.now,
    required this.striped,
    required this.onOpen,
    required this.onClose,
    required this.onFilter,
  });

  List<PopupMenuItemData> _menu(BuildContext context) {
    final l = context.appLocalizations;
    final process = trackerInfo.metadata.process;
    final proxy = trackerInfo.proxyText;
    return [
      PopupMenuItemData(
        icon: PanoramaIcons.status.info,
        label: l.details(l.connection),
        onPressed: () => onOpen(trackerInfo),
      ),
      if (process.isNotEmpty)
        PopupMenuItemData(
          icon: PanoramaIcons.actions.filter,
          label: l.showOnly(process),
          onPressed: () => onFilter(process),
        ),
      if (proxy.isNotEmpty)
        PopupMenuItemData(
          icon: PanoramaIcons.actions.filter,
          label: l.showOnly(proxy),
          onPressed: () => onFilter(proxy),
        ),
      PopupMenuItemData(
        icon: PanoramaIcons.actions.copy,
        label: l.copyDestination,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: trackerInfo.destinationText));
        },
      ),
      PopupMenuItemData(
        danger: true,
        icon: PanoramaIcons.actions.closeConnection,
        label: l.closeConnection,
        onPressed: () => onClose(trackerInfo),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final text = textTheme.bodySmall?.copyWith(color: colorScheme.labelPrimary);
    final mono = text?.toJetBrainsMono;
    final secondaryMono = mono?.copyWith(color: colorScheme.labelSecondary);
    Widget value(
      String value, {
      TextStyle? style,
      String? tooltip,
      bool numeric = false,
    }) {
      final child = Text(
        value.isEmpty ? '—' : value,
        style: style ?? text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: numeric ? TextAlign.end : TextAlign.start,
      );
      return tooltip == null || tooltip.isEmpty
          ? child
          : Tooltip(
              message: tooltip,
              waitDuration: _tooltipDelay,
              child: child,
            );
    }

    final metadata = trackerInfo.metadata;
    return CommonPopupBox(
      popup: CommonPopupMenu(items: _menu(context)),
      targetBuilder: (open) => Material(
        color: striped ? colorScheme.surfaceContainerLow : Colors.transparent,
        child: InkWell(
          onTap: () => onOpen(trackerInfo),
          onSecondaryTapUp: (details) {
            open(offset: details.localPosition);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _cell(
                  ConnectionColumn.process,
                  value(metadata.process, tooltip: metadata.processPath),
                ),
                _cell(
                  ConnectionColumn.source,
                  value(trackerInfo.sourceText, style: secondaryMono),
                ),
                _cell(
                  ConnectionColumn.destination,
                  value(
                    trackerInfo.destinationText,
                    style: mono,
                    tooltip: [
                      trackerInfo.destinationText,
                      [
                        metadata.network,
                        if (metadata.host.isNotEmpty &&
                            metadata.destinationIP.isNotEmpty)
                          metadata.destinationIP,
                      ].join(' · '),
                    ].join('\n'),
                  ),
                ),
                _cell(
                  ConnectionColumn.rule,
                  value(trackerInfo.ruleText, tooltip: trackerInfo.ruleText),
                ),
                _cell(
                  ConnectionColumn.proxy,
                  value(trackerInfo.proxyText, tooltip: trackerInfo.chainText),
                ),
                _cell(
                  ConnectionColumn.upload,
                  value(
                    trackerInfo.upload.traffic.show,
                    style: mono,
                    numeric: true,
                  ),
                ),
                _cell(
                  ConnectionColumn.download,
                  value(
                    trackerInfo.download.traffic.show,
                    style: mono,
                    numeric: true,
                  ),
                ),
                _cell(
                  ConnectionColumn.duration,
                  value(
                    formatElapsed(now.difference(trackerInfo.start)),
                    style: secondaryMono,
                    numeric: true,
                  ),
                ),
                SizedBox(
                  width: _actionWidth,
                  child: IconButton(
                    tooltip: context.appLocalizations.closeConnection,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    icon: Icon(PanoramaIcons.actions.closeConnection),
                    onPressed: () => onClose(trackerInfo),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _tooltipDelay = Duration(milliseconds: 500);
