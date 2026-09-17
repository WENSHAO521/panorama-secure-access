import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/models/state.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/list.dart';
import 'package:fl_clash/views/proxies/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key});

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<CommonScaffoldState> _scaffoldKey = GlobalKey();
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();
  bool _hasProviders = false;
  bool _isTab = false;

  List<Widget> _buildActions(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return [
      if (_isTab)
        IconButton(
          onPressed: () {
            _proxiesTabKey.currentState?.scrollToGroupSelected();
          },
          icon: const Icon(Icons.adjust, weight: 1),
        ),
      CommonPopupBox(
        targetBuilder: (open) {
          return IconButton(
            onPressed: () {
              final isMobile = ref.read(isMobileViewProvider);
              open(offset: Offset(0, isMobile ? 0 : 20));
            },
            icon: const Icon(Icons.more_vert),
          );
        },
        popup: CommonPopupMenu(
          items: [
            PopupMenuItemData(
              icon: Icons.tune,
              label: appLocalizations.settings,
              onPressed: () {
                showSheet(
                  context: context,
                  props: const SheetProps(
                    isScrollControlled: true,
                    blur: false,
                    backgroundColor: EditorialPalette.paper,
                  ),
                  builder: (_) {
                    // A pushed route doesn't inherit a Theme placed inside
                    // this screen's build() — wrap explicitly.
                    return Theme(
                      data: editorialLightTheme(context),
                      child: AdaptiveSheetScaffold(
                        flat: true,
                        body: const ProxiesSetting(),
                        title: appLocalizations.settings,
                      ),
                    );
                  },
                );
              },
            ),
            if (_hasProviders)
              PopupMenuItemData(
                icon: Icons.poll_outlined,
                label: appLocalizations.providers,
                onPressed: () {
                  showExtend(
                    context,
                    props: const ExtendProps(
                      blur: false,
                      backgroundColor: EditorialPalette.paper,
                    ),
                    builder: (_) {
                      return Theme(
                        data: editorialLightTheme(context),
                        child: const ProvidersView(),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    ];
  }

  Widget? _buildFAB() {
    return _isTab
        ? DelayTestButton(
            onClick: () async {
              await _proxiesTabKey.currentState?.delayTestCurrentGroup();
            },
          )
        : null;
  }

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(providersProvider.select((state) => state.isNotEmpty), (
      prev,
      next,
    ) {
      if (prev != next) {
        setState(() {
          _hasProviders = next;
        });
      }
    }, fireImmediately: true);
    ref.listenManual(
      proxiesStyleSettingProvider.select(
        (state) => state.type == ProxiesType.tab,
      ),
      (prev, next) {
        if (prev != next) {
          setState(() {
            _isTab = next;
          });
        }
      },
      fireImmediately: true,
    );
    ref.listenManual(
      currentPageLabelProvider.select((state) => state == PageLabel.proxies),
      (prev, next) {
        if (prev != next && next == false) {
          _scaffoldKey.currentState?.handleExitSearching();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxiesType = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.type),
    );
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    // Shell-only for now: the flat paper background + app bar match the
    // rest of the redesign, but the group/proxy list beneath it keeps its
    // current styling. That list's sticky-header and virtualized-scroll
    // math (see ListHeader/listHeaderHeight in list.dart and tab.dart)
    // is keyed to exact pixel heights of the existing cards — reskinning
    // it needs those constants reworked in lockstep, which is riskier
    // than this pass should take on for the app's most load-bearing
    // screen (proxy selection + delay testing).
    return Theme(
      data: editorialLightTheme(context),
      child: CommonScaffold(
        key: _scaffoldKey,
        flat: true,
        backgroundColor: EditorialPalette.paper,
        isLoading: isLoading,
        resizeToAvoidBottomInset: false,
        floatingActionButton: _buildFAB(),
        actions: _buildActions(context),
        title: context.appLocalizations.proxies,
        searchState: AppBarSearchState(onSearch: _onSearch),
        body: switch (proxiesType) {
          ProxiesType.tab => ProxiesTabView(key: _proxiesTabKey),
          ProxiesType.list => const ProxiesListView(),
        },
      ),
    );
  }
}
