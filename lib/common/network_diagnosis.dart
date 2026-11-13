import 'dart:async';
import 'dart:io';

import 'package:fl_clash/enum/enum.dart';

import 'conflicts.dart';
import 'netdiag.dart';

export 'netdiag.dart' show ProbeFailure;

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

/// Why a check did not pass, shown before the raw error.
enum DiagnosisCause {
  notConfigured,
  unreachable,
  refused,
  timeout,
  tls,
  hostLookup,
  proxy,
  unknown;

  static DiagnosisCause of(ProbeFailure failure) => switch (failure) {
    ProbeFailure.notConfigured => notConfigured,
    ProbeFailure.unreachable => unreachable,
    ProbeFailure.refused => refused,
    ProbeFailure.timeout => timeout,
    ProbeFailure.tls => tls,
    ProbeFailure.hostLookup => hostLookup,
    ProbeFailure.unknown => unknown,
  };
}

/// A failed probe: what kind of failure, and the error as the OS gave it.
class ProbeError {
  final ProbeFailure failure;
  final String message;

  const ProbeError(this.failure, this.message);

  @override
  bool operator ==(Object other) =>
      other is ProbeError &&
      other.failure == failure &&
      other.message == message;

  @override
  int get hashCode => Object.hash(failure, message);

  @override
  String toString() => 'ProbeError(${failure.name}, $message)';
}

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
  final DiagnosisCause? cause;

  const DiagnosisResult(
    this.check,
    this.level, {
    this.detail,
    this.repair,
    this.cause,
  });

  @override
  bool operator ==(Object other) =>
      other is DiagnosisResult &&
      other.check == check &&
      other.level == level &&
      other.detail == detail &&
      other.repair == repair &&
      other.cause == cause;

  @override
  int get hashCode => Object.hash(check, level, detail, repair, cause);

  @override
  String toString() =>
      'DiagnosisResult(${check.name}, ${level.name}, $detail, '
      '${repair?.name}, ${cause?.name})';
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
  final ProbeError? dnsError;
  final ProbeError? ipv4Error;
  final ProbeError? ipv6Error;
  final bool ipv6Enabled;
  final int? proxyStatus;
  final ProbeError? proxyError;
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
    switch (o.dnsError) {
      null => const DiagnosisResult(DiagnosisCheck.dns, ok),
      final error => DiagnosisResult(
        DiagnosisCheck.dns,
        failure,
        detail: error.message,
        cause: DiagnosisCause.of(error.failure),
        repair: o.canFlushDns ? DiagnosisRepair.flushDns : null,
      ),
    },
    switch (o.ipv4Error) {
      null => const DiagnosisResult(DiagnosisCheck.ipv4, ok),
      final error => DiagnosisResult(
        DiagnosisCheck.ipv4,
        failure,
        detail: error.message,
        cause: DiagnosisCause.of(error.failure),
      ),
    },
    switch ((o.ipv6Error, o.ipv6Enabled)) {
      (null, _) => const DiagnosisResult(DiagnosisCheck.ipv6, ok),
      (final error?, true) => DiagnosisResult(
        DiagnosisCheck.ipv6,
        warning,
        detail: error.message,
        cause: DiagnosisCause.of(error.failure),
        repair: DiagnosisRepair.disableIpv6,
      ),
      (final error?, false) => DiagnosisResult(
        DiagnosisCheck.ipv6,
        skipped,
        detail: error.message,
        cause: DiagnosisCause.of(error.failure),
      ),
    },
    if (!running)
      const DiagnosisResult(DiagnosisCheck.proxyRequest, skipped)
    else if (o.proxyStatus case final status? when status < 400)
      DiagnosisResult(DiagnosisCheck.proxyRequest, ok, detail: 'HTTP $status')
    else if (o.proxyStatus case final status?)
      DiagnosisResult(
        DiagnosisCheck.proxyRequest,
        failure,
        detail: 'HTTP $status',
        cause: DiagnosisCause.proxy,
      )
    else
      DiagnosisResult(
        DiagnosisCheck.proxyRequest,
        failure,
        detail: o.proxyError?.message,
        cause: switch (o.proxyError) {
          final error? => DiagnosisCause.of(error.failure),
          null => DiagnosisCause.unknown,
        },
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

/// Several targets per check, run together: one blocked, retired or
/// rate-limited address must not read as a broken network.
const dnsProbeHosts = ['www.cloudflare.com', 'www.apple.com', 'www.baidu.com'];
const ipv4ProbeAddresses = ['1.1.1.1', '8.8.8.8', '223.5.5.5'];
const ipv6ProbeAddresses = [
  '2606:4700:4700::1111',
  '2001:4860:4860::8888',
  '2400:3200::1',
];
const proxyProbeFallbackUrls = [
  'http://cp.cloudflare.com/generate_204',
  'https://www.gstatic.com/generate_204',
];

String _describe(Object error) => switch (error) {
  TimeoutException() => 'timeout',
  SocketException(:final osError?) => osError.message,
  SocketException(:final message) => message,
  HttpException(:final message) => message,
  TlsException(:final message) => message,
  _ => '$error',
};

/// [stage] is where [error] came from when its type does not say.
ProbeError probeErrorOf(Object error, ProbeStage stage) {
  final osError = error is SocketException ? error.osError : null;
  final timedOut =
      error is TimeoutException ||
      (error is SocketException &&
          osError == null &&
          error.message.contains('timed out'));
  return ProbeError(
    probeFailure(
      error is TlsException ? ProbeStage.handshake : stage,
      errno: osError?.errorCode,
      timedOut: timedOut,
    ),
    _describe(error),
  );
}

/// Returns null when [run] succeeds, otherwise what went wrong.
Future<ProbeError?> probe(
  Future<void> Function() run, {
  ProbeStage stage = ProbeStage.connect,
}) async {
  try {
    await run().timeout(_probeTimeout);
    return null;
  } catch (error) {
    return probeErrorOf(error, stage);
  }
}

/// Null as soon as one target passes; the probes still running are dropped.
Future<ProbeError?> probeAny(
  Iterable<String> targets,
  Future<ProbeError?> Function(String target) run,
) async {
  final pending = [for (final target in targets) run(target)];
  final done = Completer<ProbeError?>();
  final errors = <ProbeError?>[];
  for (final result in pending) {
    unawaited(
      result.then((error) {
        if (done.isCompleted) return;
        if (error == null) {
          done.complete(null);
          return;
        }
        errors.add(error);
        if (errors.length == pending.length) {
          final failure = summarizeProbes([
            for (final error in errors) error?.failure,
          ]);
          done.complete(
            errors.firstWhere(
              (error) => error?.failure == failure,
              orElse: () => errors.first,
            ),
          );
        }
      }),
    );
  }
  return done.future;
}

Future<ProbeError?> probeDns([List<String> hosts = dnsProbeHosts]) {
  return probeAny(
    hosts,
    (host) => probe(() async {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isEmpty) {
        throw const SocketException('no address');
      }
    }, stage: ProbeStage.lookup),
  );
}

Future<ProbeError?> probeTcp(List<String> addresses, {int port = 443}) {
  return probeAny(
    addresses,
    (address) => probe(() async {
      final task = await Socket.startConnect(InternetAddress(address), port);
      try {
        final socket = await task.socket.timeout(_probeTimeout);
        socket.destroy();
      } on TimeoutException {
        task.cancel();
        rethrow;
      }
    }),
  );
}

/// Returns the status the proxy answered with, or the error instead.
Future<(int?, ProbeError?)> probeProxyRequest(int port, String url) async {
  final client = HttpClient()
    ..findProxy = ((_) => 'PROXY 127.0.0.1:$port')
    ..connectionTimeout = _probeTimeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(_probeTimeout);
    final response = await request.close().timeout(_probeTimeout);
    await response.drain<void>();
    return (response.statusCode, null);
  } catch (error) {
    return (null, probeErrorOf(error, ProbeStage.connect));
  } finally {
    client.close(force: true);
  }
}

/// The first answer below 400 among [urls], otherwise the first url's result.
Future<(int?, ProbeError?)> probeProxyRequests(
  int port,
  List<String> urls,
) async {
  final results = await Future.wait([
    for (final url in urls.toSet()) probeProxyRequest(port, url),
  ]);
  return results.firstWhere(
    (result) => result.$1 != null && result.$1! < 400,
    orElse: () => results.first,
  );
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
