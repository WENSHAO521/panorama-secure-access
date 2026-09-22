import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/on_demand.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rules.dart';

// The entries that used to live on a separate "Advanced configuration"
// page. Settings now lists them directly under Connection and Profiles
// (brief §22); each one opens the same page as before.

class NetworkSettingsItem extends StatelessWidget {
  const NetworkSettingsItem({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ListItem.open(
      title: Text(appLocalizations.network),
      subtitle: Text(appLocalizations.networkDesc),
      leading: Icon(PanoramaIcons.settings.network),
      delegate: OpenDelegate(
        blur: false,
        widget: BaseScaffold(
          title: appLocalizations.network,
          body: const NetworkListView(),
        ),
      ),
    );
  }
}

class OnDemandSettingsItem extends StatelessWidget {
  const OnDemandSettingsItem({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ListItem.open(
      title: Text(appLocalizations.onDemand),
      subtitle: Text(appLocalizations.onDemandDesc),
      leading: Icon(
        PanoramaIcons.settings.onDemand,
        fontWeight: FontWeight.w900,
      ),
      delegate: const OpenDelegate(widget: OnDemandView(), blur: false),
    );
  }
}

class DnsSettingsItem extends StatelessWidget {
  const DnsSettingsItem({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ListItem.open(
      title: const Text('DNS'),
      subtitle: Text(appLocalizations.dnsDesc),
      leading: Icon(PanoramaIcons.settings.dns),
      delegate: OpenDelegate(
        widget: BaseScaffold(
          title: 'DNS',
          actions: [
            Consumer(
              builder: (_, ref, _) {
                return IconButton(
                  onPressed: () async {
                    final res = await globalState.showMessage(
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
                  icon: Icon(PanoramaIcons.actions.reset),
                );
              },
            ),
          ],
          body: const DnsListView(),
        ),
        blur: false,
      ),
    );
  }
}

class AddedRulesSettingsItem extends StatelessWidget {
  const AddedRulesSettingsItem({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ListItem.open(
      title: Text(appLocalizations.addedRules),
      subtitle: Text(appLocalizations.controlGlobalAddedRules),
      leading: Icon(PanoramaIcons.settings.addedRules),
      delegate: const OpenDelegate(widget: AddedRulesView(), blur: false),
    );
  }
}

class ScriptsSettingsItem extends StatelessWidget {
  const ScriptsSettingsItem({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ListItem.open(
      title: Text(appLocalizations.script),
      subtitle: Text(appLocalizations.overrideScript),
      leading: Icon(
        PanoramaIcons.settings.scripts,
        fontWeight: FontWeight.w900,
      ),
      delegate: const OpenDelegate(widget: ScriptsView(), blur: false),
    );
  }
}
