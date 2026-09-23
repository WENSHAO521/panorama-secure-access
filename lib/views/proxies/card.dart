import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/common.dart';
import 'package:fl_clash/views/proxies/node_detail.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProxyCard extends StatelessWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
  });

  Measure get measure => globalState.measure;

  void _handleTestCurrentDelay() {
    proxyDelayTest(proxy, testUrl);
  }

  Widget _buildDelayText() {
    return SizedBox(
      height: measure.labelSmallHeight,
      child: Consumer(
        builder: (context, ref, _) {
          final delay = ref.watch(
            delayProvider(proxyName: proxy.name, testUrl: testUrl),
          );
          return FadeThroughBox(
            alignment: type == ProxyCardType.expand
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: delay == 0 || delay == null
                ? SizedBox(
                    height: measure.labelSmallHeight,
                    width: measure.labelSmallHeight,
                    child: delay == 0
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : IconButton(
                            icon: Icon(PanoramaIcons.network.quickTest),
                            iconSize: globalState.measure.labelSmallHeight,
                            padding: EdgeInsets.zero,
                            onPressed: _handleTestCurrentDelay,
                          ),
                  )
                : GestureDetector(
                    onTap: _handleTestCurrentDelay,
                    child: Text(
                      delay > 0 ? '$delay ms' : 'Timeout',
                      style: context.textTheme.labelSmall?.copyWith(
                        overflow: TextOverflow.ellipsis,
                        color: utils.getDelayColor(delay),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildProxyNameText(BuildContext context) {
    if (type == ProxyCardType.min) {
      return SizedBox(
        height: measure.bodyMediumHeight * 1,
        child: EmojiText(
          proxy.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.toSoftBold,
        ),
      );
    } else {
      return SizedBox(
        height: measure.bodyMediumHeight * 2,
        child: EmojiText(
          proxy.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.toSoftBold,
        ),
      );
    }
  }

  Future<void> _changeProxy(WidgetRef ref) async {
    final isComputedSelected = groupType.isComputedSelected;
    final isSelector = groupType == GroupType.Selector;
    final ref = globalState.container;
    if (isComputedSelected || isSelector) {
      final currentProxyName = ref.read(proxyNameProvider(groupName));
      final nextProxyName = switch (isComputedSelected) {
        true => currentProxyName == proxy.name ? '' : proxy.name,
        false => proxy.name,
      };
      ref
          .read(profilesActionProvider.notifier)
          .updateCurrentSelectedMap(groupName, nextProxyName);
      ref
          .read(proxiesActionProvider.notifier)
          .changeProxyDebounce(groupName, nextProxyName);
      return;
    }
    globalState.showNotifier(currentAppLocalizations.notSelectedTip);
  }

  /// Brief §48: latency, a node-only service test, details, copy. Opens on
  /// long press (touch) and right click (desktop).
  List<PopupMenuItemData> _nodeMenu(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return [
      PopupMenuItemData(
        icon: PanoramaIcons.network.ping,
        label: appLocalizations.delayTest,
        onPressed: _handleTestCurrentDelay,
      ),
      PopupMenuItemData(
        icon: PanoramaIcons.network.check,
        label: appLocalizations.testNode,
        onPressed: () => showNodeDetail(context, proxy, startTest: true),
      ),
      PopupMenuItemData(
        icon: PanoramaIcons.status.info,
        label: appLocalizations.nodeDetails,
        onPressed: () => showNodeDetail(context, proxy),
      ),
      PopupMenuItemData(
        icon: PanoramaIcons.actions.copy,
        label: appLocalizations.copyName,
        onPressed: () => Clipboard.setData(ClipboardData(text: proxy.name)),
      ),
    ];
  }

  Widget _buildRow(BuildContext context, Widget delayText) {
    final secondary = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.labelSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmojiText(
                  proxy.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.toSoftBold,
                ),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, _) {
                    final report = ref.watch(
                      nodeDiagnosticsProvider.select(
                        (state) => state[proxy.name],
                      ),
                    );
                    final capability = nodeCapabilityText(
                      context.appLocalizations,
                      NodeCapability.of(report),
                    );
                    return Text(
                      [proxy.type, ?capability].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondary,
                    );
                  },
                ),
              ],
            ),
          ),
          if (groupType.isComputedSelected)
            _ProxyComputedMark(groupName: groupName, proxy: proxy),
          const SizedBox(width: 8),
          delayText,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final measure = globalState.measure;
    final delayText = _buildDelayText();
    final isRow = type == ProxyCardType.row;
    final content = isRow
        ? _buildRow(context, delayText)
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProxyNameText(context),
                const SizedBox(height: 8),
                if (type == ProxyCardType.expand) ...[
                  SizedBox(
                    height: measure.bodySmallHeight,
                    child: _ProxyDesc(proxy: proxy),
                  ),
                  const SizedBox(height: 6),
                  delayText,
                ] else
                  SizedBox(
                    height: measure.bodySmallHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 1,
                          child: TooltipText(
                            text: Text(
                              proxy.type,
                              style: context.textTheme.bodySmall?.copyWith(
                                overflow: TextOverflow.ellipsis,
                                color: context
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.opacity80,
                              ),
                            ),
                          ),
                        ),
                        delayText,
                      ],
                    ),
                  ),
              ],
            ),
          );
    return LayoutBuilder(
      builder: (context, constraints) => CommonPopupBox(
        popup: CommonPopupMenu(items: _nodeMenu(context)),
        targetBuilder: (open) => Stack(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final selectedProxyName = ref.watch(
                  selectedProxyNameProvider(groupName),
                );
                return GestureDetector(
                  onSecondaryTapUp: (details) {
                    open(offset: details.localPosition);
                  },
                  child: CommonCard(
                    key: key,
                    onPressed: () {
                      _changeProxy(ref);
                    },
                    onLongPress: () {
                      open(offset: Offset(constraints.maxWidth, 0));
                    },
                    isSelected: selectedProxyName == proxy.name,
                    child: child!,
                  ),
                );
              },
              child: content,
            ),
            if (groupType.isComputedSelected && !isRow)
              Positioned(
                top: 0,
                right: 0,
                child: _ProxyComputedMark(groupName: groupName, proxy: proxy),
              ),
          ],
        ),
      ),
    );
  }
}

/// "AI 3/3  ·  Streaming JP" for a tested node; null when untested.
/// Counts rather than ✓/✗ glyphs, which not every UI font has.
String? nodeCapabilityText(AppLocalizations l, NodeCapability? capability) {
  if (capability == null) return null;
  final parts = [
    if (capability.aiChecked > 0)
      '${l.categoryAi} ${capability.aiAvailable}/${capability.aiChecked}',
    if (capability.streamingChecked > 0)
      '${l.categoryStreaming} ${capability.streamingUsable == 0 ? '0/${capability.streamingChecked}' : capability.streamingRegion ?? '${capability.streamingUsable}/${capability.streamingChecked}'}',
  ];
  return parts.isEmpty ? null : parts.join('  ·  ');
}

class _ProxyDesc extends ConsumerWidget {
  final Proxy proxy;

  const _ProxyDesc({required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desc = ref.watch(proxyDescProvider(proxy));
    return EmojiText(
      desc,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textTheme.bodySmall?.color?.opacity80,
      ),
    );
  }
}

class _ProxyComputedMark extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;

  const _ProxyComputedMark({required this.groupName, required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyName = ref.watch(proxyNameProvider(groupName));
    if (proxyName != proxy.name) {
      return const SizedBox();
    }
    return Container(
      alignment: Alignment.topRight,
      margin: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: const SelectIcon(),
      ),
    );
  }
}
