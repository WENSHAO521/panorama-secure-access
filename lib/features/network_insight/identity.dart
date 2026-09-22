import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/models/common.dart';
import 'package:flutter/foundation.dart';

import 'service_check/http.dart';
import 'service_check/region.dart';

enum IpFamily { ipv4, ipv6 }

/// Cloudflare's trace endpoint at an IP literal. Connecting to a literal
/// forces the address family end to end: the proxy core has to reach
/// 1.1.1.1 over IPv4 (or 2606:4700:4700::1111 over IPv6) from the node's
/// exit, so success means that family genuinely works on this route —
/// not merely that a local interface has an address of that family.
/// The certificate carries IP SANs, so TLS validation stays on.
Uri ipFamilyProbeUri(IpFamily family) => switch (family) {
  IpFamily.ipv4 => Uri.parse('https://1.1.1.1/cdn-cgi/trace'),
  IpFamily.ipv6 => Uri.parse('https://[2606:4700:4700::1111]/cdn-cgi/trace'),
};

enum IpFamilyStatus { available, unavailable, timeout }

@immutable
class IpFamilyProbe {
  final IpFamily family;
  final IpFamilyStatus status;

  /// Exit address as seen by Cloudflare.
  final String? exitIp;

  /// ISO alpha-2 of the Cloudflare edge's view of [exitIp].
  final String? regionCode;
  final Duration? latency;
  final String? error;

  const IpFamilyProbe({
    required this.family,
    required this.status,
    this.exitIp,
    this.regionCode,
    this.latency,
    this.error,
  });

  bool get isAvailable => status == IpFamilyStatus.available;

  @override
  bool operator ==(Object other) =>
      other is IpFamilyProbe &&
      other.family == family &&
      other.status == status &&
      other.exitIp == exitIp &&
      other.regionCode == regionCode &&
      other.latency == latency &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(family, status, exitIp, regionCode, latency, error);
}

Future<IpFamilyProbe> probeIpFamily(
  ServiceHttp http,
  IpFamily family, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http.get(ipFamilyProbeUri(family)).timeout(timeout);
    stopwatch.stop();
    final fields = parseTrace(response.body);
    final ip = fields['ip'];
    if (!response.isSuccess || ip == null) {
      return IpFamilyProbe(
        family: family,
        status: IpFamilyStatus.unavailable,
        error: 'HTTP ${response.statusCode}',
      );
    }
    return IpFamilyProbe(
      family: family,
      status: IpFamilyStatus.available,
      exitIp: ip,
      regionCode: normalizeRegionCode(fields['loc']),
      latency: stopwatch.elapsed,
    );
  } on TimeoutException {
    http.close();
    return IpFamilyProbe(family: family, status: IpFamilyStatus.timeout);
  } on ServiceHttpException catch (e) {
    return IpFamilyProbe(
      family: family,
      status: IpFamilyStatus.unavailable,
      error: e.message,
    );
  }
}

/// `key=value` lines of a Cloudflare `/cdn-cgi/trace` body.
Map<String, String> parseTrace(String body) {
  final fields = <String, String>{};
  for (final line in const LineSplitter().convert(body)) {
    final at = line.indexOf('=');
    if (at > 0) {
      fields[line.substring(0, at)] = line.substring(at + 1).trim();
    }
  }
  return fields;
}

@immutable
class LocalInterface {
  final String name;
  final List<String> addresses;
  final bool isTun;

  const LocalInterface({
    required this.name,
    required this.addresses,
    this.isTun = false,
  });

  @override
  bool operator ==(Object other) =>
      other is LocalInterface &&
      other.name == name &&
      other.isTun == isTun &&
      listEquals(other.addresses, addresses);

  @override
  int get hashCode => Object.hash(name, isTun, Object.hashAll(addresses));
}

/// mihomo's default TUN address range (198.18.0.0/15, RFC 2544).
bool _isBenchmarkRange(String address) {
  final parts = address.split('.');
  if (parts.length != 4) {
    return false;
  }
  final second = int.tryParse(parts[1]);
  return parts[0] == '198' && (second == 18 || second == 19);
}

typedef InterfaceLister = Future<List<NetworkInterface>> Function();

Future<List<NetworkInterface>> _listSystemInterfaces() =>
    NetworkInterface.list(includeLoopback: false);

/// Non-loopback interfaces with their addresses, the core's TUN device
/// flagged. TUN is recognised by its configured device name, or by an
/// address in mihomo's default TUN range (macOS names every TUN "utunN").
Future<List<LocalInterface>> listLocalInterfaces({
  required String tunDeviceName,
  InterfaceLister lister = _listSystemInterfaces,
}) async {
  final interfaces = await lister();
  return [
    for (final interface in interfaces)
      if (interface.addresses.isNotEmpty)
        LocalInterface(
          name: interface.name,
          addresses: [
            for (final address in interface.addresses) address.address,
          ],
          isTun:
              interface.name == tunDeviceName ||
              interface.addresses.any((a) => _isBenchmarkRange(a.address)),
        ),
  ];
}

enum ConnectionKind { wifi, ethernet, mobile, vpn, other, none }

/// What the user needs to know about the current network, assembled from
/// the existing public-IP lookup (for ISP / ASN / location) plus explicit
/// per-family probes and local interfaces.
@immutable
class NetworkIdentity {
  /// First answer from the existing IP lookup pipeline (request.checkIp).
  final IpInfo? publicIp;
  final IpFamilyProbe? ipv4;
  final IpFamilyProbe? ipv6;
  final List<LocalInterface> interfaces;
  final Set<ConnectionKind> connectionKinds;
  final DateTime checkedAt;

  const NetworkIdentity({
    required this.checkedAt,
    this.publicIp,
    this.ipv4,
    this.ipv6,
    this.interfaces = const [],
    this.connectionKinds = const {},
  });

  String? get publicIPv4 => ipv4?.exitIp;

  String? get publicIPv6 => ipv6?.exitIp;

  /// Country for display: the lookup service first, the trace as fallback.
  String? get countryCode =>
      normalizeRegionCode(publicIp?.countryCode) ??
      ipv4?.regionCode ??
      ipv6?.regionCode;

  List<String> get localIPv4 => [
    for (final interface in interfaces)
      if (!interface.isTun)
        ...interface.addresses.where((a) => !a.contains(':')),
  ];

  List<String> get localIPv6 => [
    for (final interface in interfaces)
      if (!interface.isTun)
        ...interface.addresses.where((a) => a.contains(':')),
  ];
}
