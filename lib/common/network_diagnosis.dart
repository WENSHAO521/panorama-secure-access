import 'dart:async';
import 'dart:io';

import 'package:fl_clash/enum/enum.dart';

import 'conflicts.dart';

enum DiagnosisCheck {
  core,
  mixedPort,
  otherClients,
  systemProxy,
  tunAuthorization,
  dns,
  ipv4,
  ipv6,
  proxyRequest,
}

enum DiagnosisLevel { ok, warning, failure, skipped }

enum DiagnosisRepair {
  restartCore,
  switchPort,
  reapplySystemProxy,
  clearStaleProxy,
  authorizeTun,
  disableIpv6,
  flushDns,
}

class DiagnosisResult {
  final DiagnosisCheck check;
  final DiagnosisLevel level;
  final String? detail;
  final DiagnosisRepair? repair;

  const DiagnosisResult(this.check, this.level, {this.detail, this.repair});

  @override
  bool operator ==(Object other) =>
      other is DiagnosisResult &&
      other.check == check &&
      other.level == level &&
      other.detail == detail &&
      other.repair == repair;

  @override
  int get hashCode => Object.hash(check, level, detail, repair);

  @override
  String toString() =>
      'DiagnosisResult(${check.name}, ${level.name}, $detail, ${repair?.name})';
}

/// What a probe saw, null where it did not run. Kept apart from grading, so
/// the verdicts can be checked without a network.
class NetworkObservations {
  final bool desktop;
  final bool running;
  final CoreStatus coreStatus;
  final int mixedPort;
  final bool? mixedPortListening;
  final List<String> otherClients;
  final bool systemProxyWanted;
  final bool systemProxyReadable;
  final int? systemProxyPort;
  final bool? systemProxyPortListening;
  final bool tunEnabled;
  final bool? tunAuthorized;
  final String? dnsError;
  final String? ipv4Error;
  final String? ipv6Error;
  final bool ipv6Enabled;
  final int? proxyStatus;
  final String? proxyError;
  final bool canFlushDns;

  const NetworkObservations({
    required this.desktop,
    required this.running,
    required this.coreStatus,
    required this.mixedPort,
    this.mixedPortListening,
    this.otherClients = const [],
    this.systemProxyWanted = false,
    this.systemProxyReadable = false,
    this.systemProxyPort,
    this.systemProxyPortListening,
    this.tunEnabled = false,
    this.tunAuthorized,
    this.dnsError,
    this.ipv4Error,
    this.ipv6Error,
    this.ipv6Enabled = false,
    this.proxyStatus,
    this.proxyError,
    this.canFlushDns = false,
  });
}

List<DiagnosisResult> gradeNetworkDiagnosis(NetworkObservations o) {
  const ok = DiagnosisLevel.ok;
  const warning = DiagnosisLevel.warning;
  const failure = DiagnosisLevel.failure;
  const skipped = DiagnosisLevel.skipped;
  final running = o.running && o.coreStatus == CoreStatus.connected;
  return [
    switch (o.coreStatus) {
      CoreStatus.connected => const DiagnosisResult(DiagnosisCheck.core, ok),
      CoreStatus.connecting => const DiagnosisResult(
        DiagnosisCheck.core,
        warning,
      ),
      CoreStatus.disconnected => const DiagnosisResult(
        DiagnosisCheck.core,
        failure,
        repair: DiagnosisRepair.restartCore,
      ),
    },
    switch (o.mixedPortListening) {
      null => const DiagnosisResult(DiagnosisCheck.mixedPort, skipped),
      true when !running => DiagnosisResult(
        DiagnosisCheck.mixedPort,
        failure,
        detail: '${o.mixedPort}',
        repair: DiagnosisRepair.switchPort,
      ),
      false when running => DiagnosisResult(
        DiagnosisCheck.mixedPort,
        failure,
        detail: '${o.mixedPort}',
        repair: DiagnosisRepair.switchPort,
      ),
      _ => DiagnosisResult(
        DiagnosisCheck.mixedPort,
        ok,
        detail: '${o.mixedPort}',
      ),
    },
    if (o.desktop)
      o.otherClients.isEmpty
          ? const DiagnosisResult(DiagnosisCheck.otherClients, ok)
          : DiagnosisResult(
              DiagnosisCheck.otherClients,
              warning,
              detail: o.otherClients.join(', '),
            ),
    if (o.desktop) _gradeSystemProxy(o, running),
    if (o.desktop)
      switch ((o.tunEnabled, o.tunAuthorized)) {
        (false, _) || (_, null) => const DiagnosisResult(
          DiagnosisCheck.tunAuthorization,
          skipped,
        ),
        (true, true) => const DiagnosisResult(
          DiagnosisCheck.tunAuthorization,
          ok,
        ),
        (true, false) => const DiagnosisResult(
          DiagnosisCheck.tunAuthorization,
          failure,
          repair: DiagnosisRepair.authorizeTun,
        ),
      },
    o.dnsError == null
        ? const DiagnosisResult(DiagnosisCheck.dns, ok)
        : DiagnosisResult(
            DiagnosisCheck.dns,
            failure,
            detail: o.dnsError,
            repair: o.canFlushDns ? DiagnosisRepair.flushDns : null,
          ),
    o.ipv4Error == null
        ? const DiagnosisResult(DiagnosisCheck.ipv4, ok)
        : DiagnosisResult(DiagnosisCheck.ipv4, failure, detail: o.ipv4Error),
    switch ((o.ipv6Error, o.ipv6Enabled)) {
      (null, _) => const DiagnosisResult(DiagnosisCheck.ipv6, ok),
      (final error, true) => DiagnosisResult(
        DiagnosisCheck.ipv6,
        warning,
        detail: error,
        repair: DiagnosisRepair.disableIpv6,
      ),
      (final error, false) => DiagnosisResult(
        DiagnosisCheck.ipv6,
        skipped,
        detail: error,
      ),
    },
    if (!running)
      const DiagnosisResult(DiagnosisCheck.proxyRequest, skipped)
    else if (o.proxyStatus case final status? when status < 400)
      DiagnosisResult(DiagnosisCheck.proxyRequest, ok, detail: 'HTTP $status')
    else
      DiagnosisResult(
        DiagnosisCheck.proxyRequest,
        failure,
        detail: o.proxyStatus != null ? 'HTTP ${o.proxyStatus}' : o.proxyError,
      ),
  ];
}

DiagnosisResult _gradeSystemProxy(NetworkObservations o, bool running) {
  const check = DiagnosisCheck.systemProxy;
  if (!o.systemProxyReadable) {
    return const DiagnosisResult(check, DiagnosisLevel.skipped);
  }
  final port = o.systemProxyPort;
  if (running && o.systemProxyWanted) {
    return port == o.mixedPort
        ? DiagnosisResult(check, DiagnosisLevel.ok, detail: '127.0.0.1:$port')
        : DiagnosisResult(
            check,
            DiagnosisLevel.failure,
            detail: port == null ? null : '127.0.0.1:$port',
            repair: DiagnosisRepair.reapplySystemProxy,
          );
  }
  if (port != null && o.systemProxyPortListening == false) {
    return DiagnosisResult(
      check,
      DiagnosisLevel.failure,
      detail: '127.0.0.1:$port',
      repair: DiagnosisRepair.clearStaleProxy,
    );
  }
  return const DiagnosisResult(check, DiagnosisLevel.ok);
}

const _probeTimeout = Duration(seconds: 5);

String _describe(Object error) => switch (error) {
  TimeoutException() => 'timeout',
  SocketException(:final osError?) => osError.message,
  SocketException(:final message) => message,
  HttpException(:final message) => message,
  _ => '$error',
};

/// Returns null when [run] succeeds, otherwise what went wrong.
Future<String?> probe(Future<void> Function() run) async {
  try {
    await run().timeout(_probeTimeout);
    return null;
  } catch (error) {
    return _describe(error);
  }
}

Future<String?> probeDns([String host = 'www.cloudflare.com']) {
  return probe(() async {
    final addresses = await InternetAddress.lookup(host);
    if (addresses.isEmpty) {
      throw const SocketException('no address');
    }
  });
}

Future<String?> probeTcp(String address, {int port = 443}) {
  return probe(() async {
    final socket = await Socket.connect(
      InternetAddress(address),
      port,
      timeout: _probeTimeout,
    );
    socket.destroy();
  });
}

/// Returns the status the proxy answered with, or the error instead.
Future<(int?, String?)> probeProxyRequest(int port, String url) async {
  final client = HttpClient()
    ..findProxy = ((_) => 'PROXY 127.0.0.1:$port')
    ..connectionTimeout = _probeTimeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(_probeTimeout);
    final response = await request.close().timeout(_probeTimeout);
    await response.drain<void>();
    return (response.statusCode, null);
  } catch (error) {
    return (null, _describe(error));
  } finally {
    client.close(force: true);
  }
}

Future<bool> probePortListening(int port) async =>
    !await isLoopbackPortFree(port);

/// Windows and systemd-resolved can drop their cache without a password.
List<String>? flushDnsCommand({
  required String operatingSystem,
  required bool hasResolvectl,
}) {
  return switch (operatingSystem) {
    'windows' => ['ipconfig', '/flushdns'],
    'linux' when hasResolvectl => ['resolvectl', 'flush-caches'],
    _ => null,
  };
}

Future<bool> flushDns() async {
  final command = flushDnsCommand(
    operatingSystem: Platform.operatingSystem,
    hasResolvectl:
        Platform.isLinux && await File('/usr/bin/resolvectl').exists(),
  );
  if (command == null) {
    return false;
  }
  try {
    final result = await Process.run(command.first, command.skip(1).toList());
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}
