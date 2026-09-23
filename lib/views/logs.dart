import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class LogsView extends ConsumerStatefulWidget {
  const LogsView({super.key});

  @override
  ConsumerState<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends ConsumerState<LogsView> {
  final _logsStateNotifier = ValueNotifier<LogsState>(const LogsState());
  late ScrollController _scrollController;

  List<Log> _logs = [];

  /// Paused: the view keeps what it shows and counts what arrives (§80).
  final _paused = ValueNotifier<bool>(false);
  final _pendingLines = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _logs = ref.read(logsProvider).list;
    _scrollController = ScrollController(initialScrollOffset: double.maxFinite);
    _logsStateNotifier.value = _logsStateNotifier.value.copyWith(logs: _logs);
    ref.listenManual(logsProvider.select((state) => VM(state.list)), (
      prev,
      next,
    ) {
      if (prev != next) {
        final isEquality = logListEquality.equals(prev?.a, next.a);
        if (!isEquality) {
          _logs = next.a;
          if (_paused.value) {
            _pendingLines.value++;
            return;
          }
          updateLogsThrottler();
        }
      }
    });
  }

  void _togglePause() {
    _paused.value = !_paused.value;
    _pendingLines.value = 0;
    if (!_paused.value) {
      updateLogsThrottler();
    }
  }

  Future<void> _copyAll() async {
    final text = _logsStateNotifier.value.list.map(logLineText).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      context.showNotifier(context.appLocalizations.copySuccess);
    }
  }

  void _clear() {
    final notifier = ref.read(logsProvider.notifier);
    notifier.value = notifier.value.copyWith()..clear();
    _pendingLines.value = 0;
    _logs = const [];
    _logsStateNotifier.value = _logsStateNotifier.value.copyWith(logs: _logs);
  }

  List<Widget> _buildActions() {
    final appLocalizations = context.appLocalizations;
    return [
      ValueListenableBuilder<bool>(
        valueListenable: _paused,
        builder: (context, paused, _) => IconButton(
          tooltip: paused ? appLocalizations.resume : appLocalizations.pause,
          isSelected: paused,
          onPressed: _togglePause,
          icon: Icon(
            paused ? PanoramaIcons.actions.resume : PanoramaIcons.actions.pause,
          ),
        ),
      ),
      CommonPopupBox(
        popup: CommonPopupMenu(
          items: [
            PopupMenuItemData(
              icon: PanoramaIcons.actions.copy,
              label: appLocalizations.copyAll,
              onPressed: _copyAll,
            ),
            PopupMenuItemData(
              icon: PanoramaIcons.actions.saveAs,
              label: appLocalizations.exportLogs,
              onPressed: _handleExport,
            ),
            PopupMenuItemData(
              danger: true,
              icon: PanoramaIcons.actions.clearAll,
              label: appLocalizations.clearLogs,
              onPressed: _clear,
            ),
          ],
        ),
        targetBuilder: (open) => IconButton(
          tooltip: appLocalizations.more,
          onPressed: () => open(),
          icon: Icon(PanoramaIcons.actions.more),
        ),
      ),
    ];
  }

  void _onSearch(String value) {
    _logsStateNotifier.value = _logsStateNotifier.value.copyWith(query: value);
  }

  void _onKeywordsUpdate(List<String> keywords) {
    _logsStateNotifier.value = _logsStateNotifier.value.copyWith(
      keywords: keywords,
    );
  }

  @override
  void dispose() {
    _paused.dispose();
    _pendingLines.dispose();
    _logsStateNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.safeRun<bool>(() async {
      return globalState.container.read(logsProvider.notifier).exportLogs();
    }, title: appLocalizations.exportLogs);
    if (res != true) return;
    globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.exportSuccess),
    );
  }

  void updateLogsThrottler() {
    throttler.call(FunctionTag.logs, () {
      if (!mounted) {
        return;
      }
      final isEquality = logListEquality.equals(
        _logs,
        _logsStateNotifier.value.logs,
      );
      if (isEquality) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _logsStateNotifier.value = _logsStateNotifier.value.copyWith(
            logs: _logs,
          );
        }
      });
    }, duration: commonDuration);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final header = ScaffoldHeaderScope.maybeOf(context);
    return CommonScaffold(
      actions: _buildActions(),
      onKeywordsUpdate: _onKeywordsUpdate,
      searchState: AppBarSearchState(onSearch: _onSearch),
      title: header?.title ?? appLocalizations.logs,
      appBarBottom: header?.bottom,
      floatingActionButton: ValueListenableBuilder(
        valueListenable: _logsStateNotifier,
        builder: (_, state, _) {
          final autoScrollToEnd = state.autoScrollToEnd;
          return FadeRotationScaleBox(
            child: FloatingActionButton(
              key: ValueKey(autoScrollToEnd),
              tooltip: autoScrollToEnd
                  ? context.appLocalizations.stopFollowing
                  : context.appLocalizations.followNewLines,
              onPressed: () {
                _logsStateNotifier.value = _logsStateNotifier.value.copyWith(
                  autoScrollToEnd: !_logsStateNotifier.value.autoScrollToEnd,
                );
              },
              child: autoScrollToEnd
                  ? Icon(PanoramaIcons.actions.stopFollowing)
                  : Icon(PanoramaIcons.actions.follow),
            ),
          );
        },
      ),
      body: ValueListenableBuilder<LogsState>(
        valueListenable: _logsStateNotifier,
        builder: (context, state, _) {
          final logs = state.list;
          if (logs.isEmpty) {
            return NullStatus(
              illustration: const LogEmptyIllustration(),
              label: appLocalizations.nullTip(appLocalizations.logs),
            );
          }
          final items = logs
              .map<Widget>(
                (log) => LogLine(
                  key: Key(log.dateTime),
                  log: log,
                  onLevel: (value) {
                    context.commonScaffoldState?.addKeyword(value);
                  },
                ),
              )
              .toList();
          // A console: solid surface, no glass (brief §81).
          final console = Align(
            alignment: Alignment.topCenter,
            child: ScrollToEndBox(
              onCancelToEnd: () {
                _logsStateNotifier.value = _logsStateNotifier.value.copyWith(
                  autoScrollToEnd: false,
                );
              },
              controller: _scrollController,
              enable: state.autoScrollToEnd,
              dataSource: logs,
              child: CommonScrollBar(
                controller: _scrollController,
                child: SuperListView.builder(
                  physics: const NextClampingScrollPhysics(),
                  reverse: true,
                  shrinkWrap: true,
                  controller: _scrollController,
                  itemBuilder: (_, index) {
                    return items[index];
                  },
                  itemCount: items.length,
                ),
              ),
            ),
          );
          return ColoredBox(
            color: context.colorScheme.backgroundPrimary,
            child: Column(
              children: [
                _PausedBanner(
                  paused: _paused,
                  pendingLines: _pendingLines,
                  onResume: _togglePause,
                ),
                Expanded(child: console),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  final ValueListenable<bool> paused;
  final ValueListenable<int> pendingLines;
  final VoidCallback onResume;

  const _PausedBanner({
    required this.paused,
    required this.pendingLines,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: paused,
      builder: (context, isPaused, _) {
        if (!isPaused) return const SizedBox.shrink();
        final colorScheme = context.colorScheme;
        return Material(
          color: colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                Icon(
                  PanoramaIcons.actions.pause,
                  size: 16,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: pendingLines,
                    builder: (context, count, _) => Text(
                      context.appLocalizations.pausedNewLines(count),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onResume,
                  child: Text(context.appLocalizations.resume),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A log line split for the console columns (brief §80): time, level,
/// module and message. mihomo starts most lines with the module in
/// brackets ("[TCP] …", "[DNS] …"); lines without one have no module.
typedef LogLineParts = ({String time, String module, String message});

final _modulePrefix = RegExp(r'^\[([A-Za-z][\w-]{0,15})\]\s*');

LogLineParts splitLogLine(Log log) {
  final match = _modulePrefix.firstMatch(log.payload);
  // dateTime is "yyyy-MM-dd HH:mm:ss"; the date is in the tooltip.
  final time = log.dateTime.length >= 19
      ? log.dateTime.substring(11, 19)
      : log.dateTime;
  return (
    time: time,
    module: match?.group(1) ?? '',
    message: match == null ? log.payload : log.payload.substring(match.end),
  );
}

String logLevelTag(LogLevel level) => switch (level) {
  LogLevel.debug => 'DBG',
  LogLevel.info => 'INF',
  LogLevel.warning => 'WRN',
  LogLevel.error => 'ERR',
  LogLevel.silent => 'SIL',
};

/// One line as copied or exported to the clipboard.
String logLineText(Log log) {
  final parts = splitLogLine(log);
  return [
    log.dateTime,
    logLevelTag(log.logLevel),
    if (parts.module.isNotEmpty) '[${parts.module}]',
    parts.message,
  ].join(' ');
}

class LogLine extends StatelessWidget {
  /// Below this width the meta columns sit above the message.
  static const double compactWidth = 600;

  final Log log;
  final ValueChanged<String>? onLevel;

  const LogLine({super.key, required this.log, this.onLevel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final base = context.textTheme.bodySmall?.toJetBrainsMono;
    final meta = base?.copyWith(color: colorScheme.labelSecondary);
    final levelColor = switch (log.logLevel) {
      LogLevel.info => colorScheme.primary,
      _ => log.logLevel.color(context) ?? colorScheme.labelSecondary,
    };
    final messageColor = switch (log.logLevel) {
      LogLevel.warning || LogLevel.error => levelColor,
      LogLevel.debug || LogLevel.silent => colorScheme.labelSecondary,
      LogLevel.info => colorScheme.labelPrimary,
    };
    final parts = splitLogLine(log);
    final time = Tooltip(
      message: log.dateTime,
      waitDuration: const Duration(milliseconds: 500),
      child: Text(parts.time, style: meta),
    );
    final level = Semantics(
      button: onLevel != null,
      label: log.logLevel.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onLevel == null ? null : () => onLevel!(log.logLevel.name),
        borderRadius: BorderRadius.circular(4),
        child: Text(
          logLevelTag(log.logLevel),
          style: base?.copyWith(color: levelColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
    final module = Text(
      parts.module,
      style: meta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final message = SelectableText(
      parts.message,
      style: base?.copyWith(color: messageColor),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < compactWidth;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        time,
                        const SizedBox(width: 10),
                        level,
                        const SizedBox(width: 10),
                        Flexible(child: module),
                      ],
                    ),
                    const SizedBox(height: 2),
                    message,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 72, child: time),
                    SizedBox(width: 40, child: level),
                    SizedBox(width: 72, child: module),
                    Expanded(child: message),
                  ],
                ),
        );
      },
    );
  }
}
