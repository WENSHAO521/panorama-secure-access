import 'package:rust_api/netdiag.dart' as native;
import 'package:rust_api/netdiag.dart'
    show
        DnsApplyRoute,
        FailureKind,
        HttpStatusClass,
        LocalInterface,
        NetworkChangeReaction;

export 'package:rust_api/netdiag.dart'
    show
        DnsApplyRoute,
        FailureKind,
        HttpStatusClass,
        LocalAddress,
        LocalInterface,
        NetworkChangeReaction;

DnsApplyRoute dnsApplyRoute(String? appliedService, String service) =>
    native.dnsApplyRoute(appliedService: appliedService, service: service);

/// Null when [current] already carries [fallback] and nothing is written.
List<String>? dnsPatchedServers(List<String> current, String fallback) =>
    native.dnsPatchedServers(current: current, fallback: fallback);

FailureKind coreFailureKind(Object? reason) {
  final text = reason is String ? reason : null;
  return native.coreFailureKind(reason: text);
}

HttpStatusClass httpStatusClass(int status) =>
    native.httpStatusClass(status: status);

/// Wi-Fi first, then interfaces holding IPv4, and IPv4 first within one.
String pickLocalAddress(List<LocalInterface> interfaces) =>
    native.pickLocalAddress(interfaces: interfaces);

NetworkChangeReaction networkChangeReaction({
  required bool hadVpn,
  required bool hasVpn,
  required bool desktop,
}) => native.networkChangeReaction(
  hadVpn: hadVpn,
  hasVpn: hasVpn,
  desktop: desktop,
);
