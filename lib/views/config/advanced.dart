import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/on_demand.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:fl_clash/widgets/editorial.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rules.dart';

class AdvancedConfigView extends StatelessWidget {
  const AdvancedConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final List<Widget> items = [
      ListItem.open(
        title: Text(appLocalizations.network),
        subtitle: Text(appLocalizations.networkDesc),
        leading: const Icon(Icons.vpn_key),
        delegate: OpenDelegate(
          blur: false,
          backgroundColor: EditorialPalette.paper,
          widget: Theme(
            data: editorialLightTheme(context),
            child: BaseScaffold(
              flat: true,
              backgroundColor: EditorialPalette.paper,
              title: appLocalizations.network,
              body: const NetworkListView(),
            ),
          ),
        ),
      ),
      ListItem.open(
        title: Text(appLocalizations.onDemand),
        subtitle: Text(appLocalizations.onDemandDesc),
        leading: const Icon(Icons.ssid_chart, fontWeight: FontWeight.w900),
        delegate: const OpenDelegate(
          widget: OnDemandView(),
          blur: false,
          backgroundColor: EditorialPalette.paper,
        ),
      ),
      ListItem.open(
        title: const Text('DNS'),
        subtitle: Text(appLocalizations.dnsDesc),
        leading: const Icon(Icons.dns),
        delegate: OpenDelegate(
          widget: Theme(
            data: editorialLightTheme(context),
            child: BaseScaffold(
              flat: true,
              backgroundColor: EditorialPalette.paper,
              title: 'DNS',
              actions: [
                Consumer(
                  builder: (_, ref, _) {
                    return IconButton(
                      onPressed: () async {
                        final res = await globalState.showMessage(
                          flat: true,
                          title: appLocalizations.reset,
                          message: TextSpan(text: appLocalizations.resetTip),
                        );
                        if (res != true) {
                          return;
                        }
                        ref
                            .read(patchClashConfigProvider.notifier)
                            .update((state) => state.copyWith(dns: defaultDns));
                      },
                      tooltip: appLocalizations.reset,
                      icon: const Icon(Icons.replay),
                    );
                  },
                ),
              ],
              body: const DnsListView(),
            ),
          ),
          blur: false,
          backgroundColor: EditorialPalette.paper,
        ),
      ),
      ListItem.open(
        title: Text(appLocalizations.addedRules),
        subtitle: Text(appLocalizations.controlGlobalAddedRules),
        leading: const Icon(Icons.library_books),
        delegate: const OpenDelegate(
          widget: AddedRulesView(),
          blur: false,
          backgroundColor: EditorialPalette.paper,
        ),
      ),
      ListItem.open(
        title: Text(appLocalizations.script),
        subtitle: Text(appLocalizations.overrideScript),
        leading: const Icon(Icons.rocket, fontWeight: FontWeight.w900),
        delegate: const OpenDelegate(
          widget: ScriptsView(),
          blur: false,
          backgroundColor: EditorialPalette.paper,
        ),
      ),
    ];
    return Theme(
      data: editorialLightTheme(context),
      child: BaseScaffold(
        flat: true,
        backgroundColor: EditorialPalette.paper,
        title: appLocalizations.advancedConfig,
        body: generateListView(
          items
              .separated(
                const Divider(height: 0, color: EditorialPalette.hairline),
              )
              .toList(),
        ),
      ),
    );
  }
}
