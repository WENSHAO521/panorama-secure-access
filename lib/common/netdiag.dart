import 'package:flutter/foundation.dart';
import 'package:rust_api/netdiag.dart' as native;
import 'package:rust_api/netdiag.dart'
    show
        DnsApplyRoute,
        FailureKind,
        HttpStatusClass,
        LocalInterface,
        NetworkChangeReaction;
import 'package:rust_api/rust_api.dart' show isRustLibInitialized;

export 'package:rust_api/netdiag.dart'
    show
        DnsApplyRoute,
        FailureKind,
        HttpStatusClass,
        LocalAddress,
        LocalInterface,
        NetworkChangeReaction;

// The dart* functions are the reference for `netdiag` in rust_api, and the
// fallback wherever the Rust library is not loaded.

DnsApplyRoute dnsApplyRoute(String? appliedService, String service) =>
    isRustLibInitialized
    ? native.dnsApplyRoute(appliedService: appliedService, service: service)
    : dartDnsApplyRoute(appliedService, service);

/// Null when [current] already carries [fallback] and nothing is written.
List<String>? dnsPatchedServers(List<String> current, String fallback) =>
    isRustLibInitialized
    ? native.dnsPatchedServers(current: current, fallback: fallback)
    : dartDnsPatchedServers(current, fallback);

FailureKind coreFailureKind(Object? reason) {
  final text = reason is String ? reason : null;
  return isRustLibInitialized
      ? native.coreFailureKind(reason: text)
      : dartCoreFailureKind(text);
}

HttpStatusClass httpStatusClass(int status) => isRustLibInitialized
    ? native.httpStatusClass(status: status)
    : dartHttpStatusClass(status);

/// Wi-Fi first, then interfaces holding IPv4, and IPv4 first within one.
String pickLocalAddress(List<LocalInterface> interfaces) => isRustLibInitialized
    ? native.pickLocalAddress(interfaces: interfaces)
    : dartPickLocalAddress(interfaces);

NetworkChangeReaction networkChangeReaction({
  required bool hadVpn,
  required bool hasVpn,
  required bool desktop,
}) => isRustLibInitialized
    ? native.networkChangeReaction(
        hadVpn: hadVpn,
        hasVpn: hasVpn,
        desktop: desktop,
      )
    : dartNetworkChangeReaction(hadVpn, hasVpn, desktop);

@visibleForTesting
DnsApplyRoute dartDnsApplyRoute(String? appliedService, String service) =>
    switch (appliedService) {
      null => DnsApplyRoute.fresh,
      final applied when applied == service => DnsApplyRoute.reapply,
      _ => DnsApplyRoute.releaseFirst,
    };

@visibleForTesting
List<String>? dartDnsPatchedServers(List<String> current, String fallback) =>
    current.contains(fallback) ? null : [...current, fallback];

@visibleForTesting
FailureKind dartCoreFailureKind(String? reason) => switch (reason) {
  'timeout' => FailureKind.timeout,
  'dns' => FailureKind.hostLookup,
  'tls' => FailureKind.tls,
  'connection' => FailureKind.connection,
  _ => FailureKind.unknown,
};

@visibleForTesting
HttpStatusClass dartHttpStatusClass(int status) => switch (status) {
  401 || 403 || 407 => HttpStatusClass.accessDenied,
  404 || 410 => HttpStatusClass.notFound,
  429 => HttpStatusClass.rateLimited,
  >= 500 && <= 599 => HttpStatusClass.server,
  _ => HttpStatusClass.badResponse,
};

bool _isWifi(String name) {
  final lower = name.toLowerCase();
  return lower.contains('wlan') ||
      lower.contains('wi-fi') ||
      lower == 'en0' ||
      lower == 'eth0';
}

int _rank(bool preferred) => preferred ? 0 : 1;

@visibleForTesting
String dartPickLocalAddress(List<LocalInterface> interfaces) {
  final ordered = [...interfaces]
    ..sort((a, b) {
      final wifi = _rank(_isWifi(a.name)).compareTo(_rank(_isWifi(b.name)));
      if (wifi != 0) return wifi;
      return _rank(
        a.addresses.any((address) => address.ipv4),
      ).compareTo(_rank(b.addresses.any((address) => address.ipv4)));
    });
  for (final interface in ordered) {
    if (interface.addresses.isEmpty) {
      continue;
    }
    final addresses = [...interface.addresses]
      ..sort((a, b) => _rank(a.ipv4).compareTo(_rank(b.ipv4)));
    return addresses.first.address;
  }
  return '';
}

@visibleForTesting
NetworkChangeReaction dartNetworkChangeReaction(
  bool hadVpn,
  bool hasVpn,
  bool desktop,
) {
  final newNetwork = hadVpn == hasVpn;
  return NetworkChangeReaction(
    resyncSystemDns: true,
    refreshLocalIp: true,
    reportToCore: newNetwork && desktop,
    bumpHostEpoch: newNetwork && !desktop,
  );
}
