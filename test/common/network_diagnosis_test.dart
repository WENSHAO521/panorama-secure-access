import 'dart:io';

import 'package:fl_clash/common/network_diagnosis.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

NetworkObservations _healthy({
  bool running = true,
  CoreStatus coreStatus = CoreStatus.connected,
  bool? mixedPortListening = true,
  List<String> otherClients = const [],
  bool systemProxyWanted = true,
  int? systemProxyPort = 7890,
  bool? systemProxyPortListening = true,
  bool tunEnabled = false,
  bool? tunAuthorized,
  String? dnsError,
  String? ipv6Error,
  bool ipv6Enabled = false,
  int? proxyStatus = 204,
  String? proxyError,
}) => NetworkObservations(
  desktop: true,
  running: running,
  coreStatus: coreStatus,
  mixedPort: 7890,
  mixedPortListening: mixedPortListening,
  otherClients: otherClients,
  systemProxyWanted: systemProxyWanted,
  systemProxyReadable: true,
  systemProxyPort: systemProxyPort,
  systemProxyPortListening: systemProxyPortListening,
  tunEnabled: tunEnabled,
  tunAuthorized: tunAuthorized,
  dnsError: dnsError,
  ipv6Error: ipv6Error,
  ipv6Enabled: ipv6Enabled,
  proxyStatus: proxyStatus,
  proxyError: proxyError,
  canFlushDns: true,
);

DiagnosisResult _of(List<DiagnosisResult> results, DiagnosisCheck check) =>
    results.singleWhere((item) => item.check == check);

void main() {
  test('a healthy desktop passes every check it can run', () {
    final results = gradeNetworkDiagnosis(_healthy());

    expect(
      results.where((item) => item.level == DiagnosisLevel.failure),
      isEmpty,
    );
    expect(
      _of(results, DiagnosisCheck.tunAuthorization).level,
      DiagnosisLevel.skipped,
    );
    expect(_of(results, DiagnosisCheck.proxyRequest).detail, 'HTTP 204');
  });

  test('a disconnected core is offered a restart', () {
    final results = gradeNetworkDiagnosis(
      _healthy(coreStatus: CoreStatus.disconnected),
    );

    expect(
      _of(results, DiagnosisCheck.core),
      const DiagnosisResult(
        DiagnosisCheck.core,
        DiagnosisLevel.failure,
        repair: DiagnosisRepair.restartCore,
      ),
    );
    expect(
      _of(results, DiagnosisCheck.proxyRequest).level,
      DiagnosisLevel.skipped,
    );
  });

  test('the port is a problem when another program holds it before start '
      'or nothing holds it while running', () {
    final taken = gradeNetworkDiagnosis(
      _healthy(running: false, systemProxyPort: null),
    );
    final unbound = gradeNetworkDiagnosis(_healthy(mixedPortListening: false));

    for (final results in [taken, unbound]) {
      expect(
        _of(results, DiagnosisCheck.mixedPort).repair,
        DiagnosisRepair.switchPort,
      );
    }
  });

  test('other clients are a warning naming them', () {
    final result = _of(
      gradeNetworkDiagnosis(_healthy(otherClients: ['clash-verge', 'v2ray'])),
      DiagnosisCheck.otherClients,
    );

    expect(result.level, DiagnosisLevel.warning);
    expect(result.detail, 'clash-verge, v2ray');
  });

  group('system proxy', () {
    test('pointing elsewhere while running is set again', () {
      final result = _of(
        gradeNetworkDiagnosis(_healthy(systemProxyPort: 1080)),
        DiagnosisCheck.systemProxy,
      );

      expect(result.repair, DiagnosisRepair.reapplySystemProxy);
      expect(result.detail, '127.0.0.1:1080');
    });

    test('left on a dead port after a stop is cleared', () {
      final result = _of(
        gradeNetworkDiagnosis(
          _healthy(
            running: false,
            mixedPortListening: false,
            systemProxyPortListening: false,
          ),
        ),
        DiagnosisCheck.systemProxy,
      );

      expect(result.repair, DiagnosisRepair.clearStaleProxy);
    });

    test('is skipped where it cannot be read', () {
      final results = gradeNetworkDiagnosis(
        const NetworkObservations(
          desktop: true,
          running: true,
          coreStatus: CoreStatus.connected,
          mixedPort: 7890,
        ),
      );

      expect(
        _of(results, DiagnosisCheck.systemProxy).level,
        DiagnosisLevel.skipped,
      );
    });
  });

  test('an unauthorized TUN is offered the authorization', () {
    final result = _of(
      gradeNetworkDiagnosis(_healthy(tunEnabled: true, tunAuthorized: false)),
      DiagnosisCheck.tunAuthorization,
    );

    expect(result.repair, DiagnosisRepair.authorizeTun);
  });

  test('failed DNS can be flushed', () {
    final result = _of(
      gradeNetworkDiagnosis(_healthy(dnsError: 'timeout')),
      DiagnosisCheck.dns,
    );

    expect(result.level, DiagnosisLevel.failure);
    expect(result.repair, DiagnosisRepair.flushDns);
  });

  test('missing IPv6 matters only while IPv6 is on', () {
    final on = _of(
      gradeNetworkDiagnosis(
        _healthy(ipv6Error: 'unreachable', ipv6Enabled: true),
      ),
      DiagnosisCheck.ipv6,
    );
    final off = _of(
      gradeNetworkDiagnosis(_healthy(ipv6Error: 'unreachable')),
      DiagnosisCheck.ipv6,
    );

    expect(on.repair, DiagnosisRepair.disableIpv6);
    expect(off.level, DiagnosisLevel.skipped);
  });

  test('a refused or failed request through the proxy fails', () {
    expect(
      _of(
        gradeNetworkDiagnosis(_healthy(proxyStatus: 502)),
        DiagnosisCheck.proxyRequest,
      ).detail,
      'HTTP 502',
    );
    expect(
      _of(
        gradeNetworkDiagnosis(
          _healthy(proxyStatus: null, proxyError: 'timeout'),
        ),
        DiagnosisCheck.proxyRequest,
      ).detail,
      'timeout',
    );
  });

  test('Android runs no desktop-only check', () {
    final checks = gradeNetworkDiagnosis(
      const NetworkObservations(
        desktop: false,
        running: true,
        coreStatus: CoreStatus.connected,
        mixedPort: 7890,
      ),
    ).map((item) => item.check);

    expect(checks, isNot(contains(DiagnosisCheck.systemProxy)));
    expect(checks, isNot(contains(DiagnosisCheck.otherClients)));
  });

  test('DNS is flushed only where no password is needed', () {
    expect(flushDnsCommand(operatingSystem: 'windows', hasResolvectl: false), [
      'ipconfig',
      '/flushdns',
    ]);
    expect(flushDnsCommand(operatingSystem: 'linux', hasResolvectl: true), [
      'resolvectl',
      'flush-caches',
    ]);
    expect(
      flushDnsCommand(operatingSystem: 'linux', hasResolvectl: false),
      null,
    );
    expect(
      flushDnsCommand(operatingSystem: 'macos', hasResolvectl: true),
      null,
    );
  });

  group('probes', () {
    test('report success as null and failure as text', () async {
      expect(await probe(() async {}), isNull);
      expect(
        await probe(() async => throw const SocketException('refused')),
        'refused',
      );
    });

    test('see a listening loopback port', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      expect(await probePortListening(server.port), isTrue);
    });

    test('get the status a local proxy answers with', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) {
        request.response
          ..statusCode = 204
          ..close();
      });

      expect(await probeProxyRequest(server.port, 'http://example.invalid/'), (
        204,
        null,
      ));
    });
  });
}
