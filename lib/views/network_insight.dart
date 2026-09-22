import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/features/network_insight/dns.dart';
import 'package:fl_clash/features/network_insight/identity.dart';
import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:fl_clash/features/network_insight/service_check/region.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Current network intelligence: exit IPs, IPv4/IPv6 reachability, which
/// services work through this route, local interfaces and diagnostics.
///
/// Laid out as plain sections with dividers — no glass, no card grid
/// (brief §9, §129). Identity refreshes when the page is shown and on
/// network events while it's visible; services are only checked when the
/// user asks (brief §45, §106-107).
const _maxContentWidth = 760.0;

class NetworkInsightView extends ConsumerStatefulWidget {
  const NetworkInsightView({super.key});

  @override
  ConsumerState<NetworkInsightView> createState() => _NetworkInsightViewState();
}

class _NetworkInsightViewState extends ConsumerState<NetworkInsightView> {
  bool _isActive = false;
  bool _isStale = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual(checkIpNumProvider, (_, _) {
      if (_isActive) {
        _refreshIdentity();
      } else {
        _isStale = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isActive = PageActivityScope.isActiveOf(context);
    if (isActive && !_isActive && _isStale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshIdentity();
        }
      });
    }
    _isActive = isActive;
  }

  void _refreshIdentity() {
    _isStale = false;
    ref.read(networkInsightIdentityProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final isLoading = ref.watch(
      networkInsightIdentityProvider.select((state) => state.isLoading),
    );
    return CommonScaffold(
      title: appLocalizations.networkInsight,
      actions: [
        IconButton(
          tooltip: appLocalizations.networkIdentity,
          onPressed: isLoading ? null : _refreshIdentity,
          icon: Icon(PanoramaIcons.actions.refresh),
        ),
      ],
      // Rows pair a label with a value at the far edge; on a wide window
      // that puts them a screen apart. Cap the column and centre it with
      // padding, so the scrollbar still sits at the window edge.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = ((constraints.maxWidth - _maxContentWidth) / 2).clamp(
            0.0,
            double.infinity,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 24),
            children: const [
              _IdentitySection(),
              Divider(height: 24),
              _ServicesSection(),
              Divider(height: 24),
              _InterfacesSection(),
              Divider(height: 24),
              _DnsSection(),
              Divider(height: 24),
              _DiagnosticsSection(),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Network identity
// ---------------------------------------------------------------------------

class _IdentitySection extends ConsumerWidget {
  const _IdentitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final state = ref.watch(networkInsightIdentityProvider);
    final identity = state.identity;
    final checkedAt = identity?.checkedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListHeader(
          title: appLocalizations.networkIdentity,
          subTitle: checkedAt == null
              ? null
              : appLocalizations.checkedAt(DateFormat.Hms().format(checkedAt)),
          actions: [
            if (state.isLoading)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        _FamilyRow(
          label: appLocalizations.publicIPv4,
          probe: identity?.ipv4,
          identity: identity,
          isLoading: state.isLoading,
        ),
        _FamilyRow(
          label: appLocalizations.publicIPv6,
          probe: identity?.ipv6,
          identity: identity,
          isLoading: state.isLoading,
        ),
        ListItem(
          title: Text(appLocalizations.networkType),
          subtitle: Text(_connectionLabel(context, identity)),
        ),
        if (identity != null &&
            (identity.localIPv4.isNotEmpty || identity.localIPv6.isNotEmpty))
          ListItem(
            title: Text(appLocalizations.localAddresses),
            subtitle: _TechnicalText(
              [...identity.localIPv4, ...identity.localIPv6].join('\n'),
            ),
          ),
      ],
    );
  }

  String _connectionLabel(BuildContext context, NetworkIdentity? identity) {
    final appLocalizations = context.appLocalizations;
    final kinds = identity?.connectionKinds ?? const {};
    if (kinds.isEmpty) {
      return '—';
    }
    return kinds
        .map(
          (kind) => switch (kind) {
            ConnectionKind.wifi => appLocalizations.connectionWifi,
            ConnectionKind.ethernet => appLocalizations.connectionEthernet,
            ConnectionKind.mobile => appLocalizations.connectionMobile,
            ConnectionKind.vpn => appLocalizations.connectionVpn,
            ConnectionKind.none => appLocalizations.noNetwork,
            ConnectionKind.other => appLocalizations.other,
          },
        )
        .join(' · ');
  }
}

class _FamilyRow extends StatelessWidget {
  final String label;
  final IpFamilyProbe? probe;
  final NetworkIdentity? identity;
  final bool isLoading;

  const _FamilyRow({
    required this.label,
    required this.probe,
    required this.identity,
    required this.isLoading,
  });

  /// Location and network details from the lookup service, attached to the
  /// family whose exit address the lookup actually saw.
  String? _details() {
    final publicIp = identity?.publicIp;
    final exitIp = probe?.exitIp;
    final regionCode = normalizeRegionCode(publicIp?.countryCode);
    if (publicIp == null || exitIp == null || publicIp.ip != exitIp) {
      final code = probe?.regionCode;
      return code == null ? null : '${regionFlag(code)} $code';
    }
    final place = [
      publicIp.countryName ?? regionCode,
      publicIp.city,
    ].whereType<String>().toSet().join(' · ');
    final network = [
      publicIp.isp ?? publicIp.organization,
      if (publicIp.asn != null) 'AS${publicIp.asn}',
    ].whereType<String>().join(' · ');
    return [
      if (regionCode != null) '${regionFlag(regionCode)} $place' else place,
      network,
    ].where((part) => part.trim().isNotEmpty).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final probe = this.probe;
    final Widget subtitle;
    if (probe == null) {
      subtitle = Text(isLoading ? appLocalizations.statusChecking : '—');
    } else if (!probe.isAvailable) {
      subtitle = _StatusLabel(
        icon: PanoramaIcons.status.notChecked,
        color: context.colorScheme.labelSecondary,
        text: probe.status == IpFamilyStatus.timeout
            ? appLocalizations.timeout
            : appLocalizations.notAvailable,
      );
    } else {
      final details = _details();
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TechnicalText(probe.exitIp!),
          if (details != null && details.isNotEmpty)
            Text(
              details,
              style: TextStyle(fontFamilyFallback: [FontFamily.twEmoji.value]),
            ),
        ],
      );
    }
    return ListItem(title: Text(label), subtitle: subtitle);
  }
}

// ---------------------------------------------------------------------------
// Service availability
// ---------------------------------------------------------------------------

class _ServicesSection extends ConsumerWidget {
  const _ServicesSection();

  String _categoryLabel(BuildContext context, ServiceCategory category) {
    final appLocalizations = context.appLocalizations;
    return switch (category) {
      ServiceCategory.ai => appLocalizations.categoryAi,
      ServiceCategory.streaming => appLocalizations.categoryStreaming,
      ServiceCategory.social => appLocalizations.categorySocial,
      ServiceCategory.regional => appLocalizations.categoryRegional,
      ServiceCategory.connectivity => appLocalizations.categoryConnectivity,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final state = ref.watch(serviceAvailabilityProvider);
    final notifier = ref.read(serviceAvailabilityProvider.notifier);
    final checked = state.checkedCount;
    final byCategory = <ServiceCategory, List<ServiceCheckResult>>{};
    for (final result in state.results) {
      byCategory.putIfAbsent(result.category, () => []).add(result);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListHeader(
          title: appLocalizations.serviceAvailability,
          subTitle: checked == 0
              ? null
              : appLocalizations.servicesAvailable(
                  '${state.availableCount}',
                  '${state.results.length}',
                ),
          actions: [
            state.isChecking
                ? TextButton(
                    onPressed: notifier.cancel,
                    child: Text(appLocalizations.cancel),
                  )
                : FilledButton.tonal(
                    onPressed: notifier.checkAll,
                    child: Text(appLocalizations.checkAll),
                  ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '${appLocalizations.serviceCheckPrivacyTip} '
            '${appLocalizations.detectionTip}',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.labelSecondary,
            ),
          ),
        ),
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _categoryLabel(context, entry.key),
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.labelSecondary,
              ),
            ),
          ),
          for (final result in entry.value)
            PanoramaServiceRow(
              result: result,
              onCheck: result.status == ServiceCheckStatus.checking
                  ? null
                  : () => notifier.check(result.serviceId),
            ),
        ],
      ],
    );
  }
}

/// One service: name on the left, status icon + text + region on the
/// right. Tapping re-checks just this service.
class PanoramaServiceRow extends StatelessWidget {
  final ServiceCheckResult result;
  final VoidCallback? onCheck;

  const PanoramaServiceRow({super.key, required this.result, this.onCheck});

  @override
  Widget build(BuildContext context) {
    final presentation = ServiceStatusPresentation.of(context, result);
    final note = presentation.note;
    return ListItem(
      title: Text(result.serviceName),
      subtitle: note == null ? null : Text(note),
      minVerticalPadding: 8,
      onTap: onCheck,
      trailing: result.status == ServiceCheckStatus.checking
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(presentation.label),
              ],
            )
          : _StatusLabel(
              icon: presentation.icon,
              color: presentation.color,
              text: presentation.label,
            ),
    );
  }
}

/// How a result reads on screen. Colour is never the only signal: every
/// state has its own icon and text (brief §39, §100).
class ServiceStatusPresentation {
  final IconData icon;
  final Color color;

  /// e.g. "Available · 🇯🇵 JP"
  final String label;

  /// Secondary line: a localized note ("Originals only") or technical
  /// detail ("HTTP 429").
  final String? note;

  const ServiceStatusPresentation({
    required this.icon,
    required this.color,
    required this.label,
    this.note,
  });

  factory ServiceStatusPresentation.of(
    BuildContext context,
    ServiceCheckResult result,
  ) {
    final appLocalizations = context.appLocalizations;
    final colors = context.colorScheme;
    const icons = PanoramaIcons.status;
    final (IconData icon, Color color, String text) = switch (result.status) {
      ServiceCheckStatus.pending => (
        icons.notChecked,
        colors.labelTertiary,
        appLocalizations.statusNotChecked,
      ),
      ServiceCheckStatus.checking => (
        icons.notChecked,
        colors.labelSecondary,
        appLocalizations.statusChecking,
      ),
      ServiceCheckStatus.available => (
        icons.ok,
        colors.success,
        appLocalizations.statusAvailable,
      ),
      ServiceCheckStatus.regional => (
        icons.ok,
        colors.success,
        appLocalizations.statusRegional,
      ),
      ServiceCheckStatus.limited => (
        icons.partial,
        colors.warning,
        appLocalizations.statusLimited,
      ),
      ServiceCheckStatus.blocked => (
        icons.blocked,
        colors.danger,
        appLocalizations.statusBlocked,
      ),
      ServiceCheckStatus.unsupportedRegion => (
        icons.blocked,
        colors.danger,
        appLocalizations.statusUnsupportedRegion,
      ),
      ServiceCheckStatus.ipRestricted => (
        icons.blocked,
        colors.danger,
        appLocalizations.statusIpRestricted,
      ),
      ServiceCheckStatus.timeout => (
        icons.failed,
        colors.labelSecondary,
        appLocalizations.timeout,
      ),
      ServiceCheckStatus.networkError => (
        icons.failed,
        colors.labelSecondary,
        appLocalizations.statusNetworkError,
      ),
      ServiceCheckStatus.parseError => (
        icons.failed,
        colors.labelSecondary,
        appLocalizations.statusParseError,
      ),
      ServiceCheckStatus.unknown => (
        icons.unknown,
        colors.labelSecondary,
        appLocalizations.unknown,
      ),
    };
    final region = result.regionCode;
    final showRegion = region != null && result.status.isDone;
    final message = result.message;
    final note = switch (message) {
      null => null,
      serviceNoteOriginalsOnly => appLocalizations.originalsOnly,
      serviceNoteComingSoon => appLocalizations.comingSoon,
      _ => result.status.isUsable ? null : message,
    };
    return ServiceStatusPresentation(
      icon: icon,
      color: color,
      label: showRegion ? '$text · ${regionFlag(region)} $region' : text,
      note: note,
    );
  }
}

// ---------------------------------------------------------------------------
// Interfaces
// ---------------------------------------------------------------------------

class _InterfacesSection extends ConsumerWidget {
  const _InterfacesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interfaces = ref.watch(
      networkInsightIdentityProvider.select(
        (state) => state.identity?.interfaces ?? const <LocalInterface>[],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListHeader(title: context.appLocalizations.interfaces),
        if (interfaces.isEmpty)
          const ListItem(title: Text('—'))
        else
          for (final interface in interfaces)
            ListItem(
              title: Row(
                children: [
                  Flexible(child: Text(interface.name)),
                  if (interface.isTun) ...[
                    const SizedBox(width: 8),
                    Text(
                      context.appLocalizations.tun,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.accent,
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: _TechnicalText(interface.addresses.join('\n')),
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DNS (brief §71: configured DNS only)
// ---------------------------------------------------------------------------

class _DnsSection extends ConsumerWidget {
  const _DnsSection();

  static String _mode(String mode) => switch (mode) {
    'fake-ip' => 'Fake-IP',
    'redir-host' => 'Redir-Host',
    'normal' => 'Normal',
    'hosts' => 'Hosts',
    _ => mode,
  };

  static String _transport(DnsTransport transport) => switch (transport) {
    DnsTransport.udp => 'UDP',
    DnsTransport.tcp => 'TCP',
    DnsTransport.tls => 'DoT',
    DnsTransport.https => 'DoH',
    DnsTransport.quic => 'DoQ',
    DnsTransport.dhcp => 'DHCP',
    DnsTransport.system || DnsTransport.other => '',
  };

  static String _server(AppLocalizations l, DnsServer server) {
    final name = switch (server.transport) {
      DnsTransport.system => l.systemResolver,
      DnsTransport.other => server.host,
      _ => '${_transport(server.transport).padRight(4)} ${server.host}',
    };
    return server.via == null ? name : '$name  → ${server.via}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final dns = ref.watch(
      networkInsightIdentityProvider.select((state) => state.identity?.dns),
    );

    Widget servers(String title, List<DnsServer> list) => ListItem(
      title: Text(title),
      subtitle: _TechnicalText(list.map((s) => _server(l, s)).join('\n')),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListHeader(title: 'DNS'),
        if (dns == null)
          const ListItem(title: Text('—'))
        else ...[
          ListItem(
            title: Text(l.dnsConfiguredBy),
            subtitle: Text(switch (dns.source) {
              DnsSource.profile => l.dnsFromProfile,
              DnsSource.appOverride => l.dnsFromOverride,
              DnsSource.appFallback => l.dnsFromFallback,
            }),
          ),
          ListItem(
            title: Text(l.dnsMode),
            trailing: _TechnicalText(
              [_mode(dns.mode), if (dns.isFakeIp) ?dns.fakeIpRange].join('  '),
            ),
          ),
          if (dns.nameservers.isNotEmpty)
            servers(l.nameserver, dns.nameservers),
          if (dns.fallback.isNotEmpty) servers(l.fallback, dns.fallback),
          if (dns.proxyServerNameservers.isNotEmpty)
            servers(l.proxyNameserver, dns.proxyServerNameservers),
          if (dns.policyCount > 0)
            ListItem(
              title: Text(l.nameserverPolicy),
              trailing: Text(l.dnsRuleCount(dns.policyCount)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              l.dnsConfigNote,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.labelSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diagnostics
// ---------------------------------------------------------------------------

class _DiagnosticsSection extends ConsumerWidget {
  const _DiagnosticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colors = context.colorScheme;
    final isStart = ref.watch(isStartProvider);
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final tun = ref.watch(realTunEnableProvider);
    final identity = ref.watch(
      networkInsightIdentityProvider.select((state) => state.identity),
    );

    Widget row(String label, bool? ok, String okText, String badText) {
      return ListItem(
        title: Text(label),
        minVerticalPadding: 8,
        trailing: ok == null
            ? const Text('—')
            : _StatusLabel(
                icon: ok
                    ? PanoramaIcons.status.ok
                    : PanoramaIcons.status.notChecked,
                color: ok ? colors.success : colors.labelSecondary,
                text: ok ? okText : badText,
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListHeader(title: appLocalizations.diagnostics),
        row(
          appLocalizations.coreStatus,
          isStart,
          appLocalizations.stateRunning,
          appLocalizations.stateStopped,
        ),
        if (system.isDesktop)
          row(
            appLocalizations.systemProxy,
            isStart && systemProxy,
            appLocalizations.stateOn,
            appLocalizations.stateOff,
          ),
        row(
          appLocalizations.tun,
          tun,
          appLocalizations.stateOn,
          appLocalizations.stateOff,
        ),
        row(
          'IPv4',
          identity?.ipv4?.isAvailable,
          appLocalizations.statusAvailable,
          appLocalizations.notAvailable,
        ),
        row(
          'IPv6',
          identity?.ipv6?.isAvailable,
          appLocalizations.statusAvailable,
          appLocalizations.notAvailable,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _StatusLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusLabel({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontFamilyFallback: [FontFamily.twEmoji.value],
            ),
          ),
        ),
      ],
    );
  }
}

/// Addresses and other technical values: monospace and selectable.
class _TechnicalText extends StatelessWidget {
  final String text;

  const _TechnicalText(this.text);

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: context.textTheme.bodyMedium?.toJetBrainsMono.copyWith(
        color: context.colorScheme.labelSecondary,
      ),
    );
  }
}
