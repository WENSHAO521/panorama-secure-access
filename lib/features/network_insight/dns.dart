import 'package:fl_clash/common/task.dart';
import 'package:flutter/foundation.dart';

/// Transport of a configured DNS server, from its mihomo address syntax.
enum DnsTransport { udp, tcp, tls, https, quic, dhcp, system, other }

/// One configured DNS server, reduced to what is safe to show: transport,
/// host and the proxy it goes through. The path, query and user info of a
/// DoH URL are dropped — some services put an account id there.
@immutable
class DnsServer {
  final DnsTransport transport;

  /// Host, IP or (for DHCP) interface name; empty for the system resolver.
  final String host;

  /// Proxy or group the queries go through (`…#Proxy`), if any.
  final String? via;

  const DnsServer({required this.transport, this.host = '', this.via});

  factory DnsServer.parse(String raw) {
    final value = raw.trim();
    final hashAt = value.indexOf('#');
    final address = hashAt < 0 ? value : value.substring(0, hashAt);
    final fragment = hashAt < 0 ? '' : value.substring(hashAt + 1);
    // `#name` routes through a proxy; `#key=value&…` are query options.
    final via = fragment.isEmpty || fragment.contains('=') ? null : fragment;

    if (address == 'system' || address.startsWith('system://')) {
      return DnsServer(transport: DnsTransport.system, via: via);
    }
    final schemeEnd = address.indexOf('://');
    if (schemeEnd < 0) {
      return DnsServer(
        transport: DnsTransport.udp,
        host: _stripPort(address),
        via: via,
      );
    }
    final scheme = address.substring(0, schemeEnd).toLowerCase();
    final transport = switch (scheme) {
      'udp' => DnsTransport.udp,
      'tcp' => DnsTransport.tcp,
      'tls' => DnsTransport.tls,
      'https' => DnsTransport.https,
      'quic' => DnsTransport.quic,
      'dhcp' => DnsTransport.dhcp,
      _ => DnsTransport.other,
    };
    final uri = Uri.tryParse(address);
    final host = uri != null && uri.host.isNotEmpty
        ? uri.host
        : _stripPort(address.substring(schemeEnd + 3).split('/').first);
    return DnsServer(transport: transport, host: host, via: via);
  }

  static String _stripPort(String hostPort) {
    if (hostPort.startsWith('[')) {
      final end = hostPort.indexOf(']');
      return end < 0 ? hostPort : hostPort.substring(1, end);
    }
    // A bare IPv6 address has several colons and no port.
    if (':'.allMatches(hostPort).length == 1) {
      return hostPort.substring(0, hostPort.indexOf(':'));
    }
    return hostPort;
  }

  @override
  bool operator ==(Object other) =>
      other is DnsServer &&
      other.transport == transport &&
      other.host == host &&
      other.via == via;

  @override
  int get hashCode => Object.hash(transport, host, via);

  @override
  String toString() => 'DnsServer($transport, $host, via: $via)';
}

/// The DNS configuration the core runs with (brief §71: "configured DNS").
///
/// Configuration only. Which resolver actually answers a query is not
/// observed here, and nothing about DNS leaks is inferred from it.
@immutable
class DnsInsight {
  final DnsSource source;

  /// `fake-ip`, `redir-host`, `normal`, … as written in the config.
  final String mode;
  final String? fakeIpRange;
  final List<DnsServer> nameservers;
  final List<DnsServer> fallback;

  /// Resolvers used to look up proxy server addresses.
  final List<DnsServer> proxyServerNameservers;
  final int policyCount;
  final bool ipv6;

  const DnsInsight({
    required this.source,
    required this.mode,
    this.fakeIpRange,
    this.nameservers = const [],
    this.fallback = const [],
    this.proxyServerNameservers = const [],
    this.policyCount = 0,
    this.ipv6 = false,
  });

  bool get isFakeIp => mode == 'fake-ip';

  factory DnsInsight.fromSection(Map<String, dynamic> dns, DnsSource source) {
    List<DnsServer> servers(Object? value) => [
      if (value is List)
        for (final item in value)
          if (item is String && item.trim().isNotEmpty) DnsServer.parse(item),
    ];
    final mode = dns['enhanced-mode'];
    final range = dns['fake-ip-range'];
    final policy = dns['nameserver-policy'];
    return DnsInsight(
      source: source,
      mode: mode is String && mode.isNotEmpty ? mode : 'normal',
      fakeIpRange: range is String && range.isNotEmpty ? range : null,
      nameservers: servers(dns['nameserver']),
      fallback: servers(dns['fallback']),
      proxyServerNameservers: servers(dns['proxy-server-nameserver']),
      policyCount: policy is Map ? policy.length : 0,
      ipv6: dns['ipv6'] == true,
    );
  }
}
