import 'dart:io';

import 'package:fl_clash/common/http.dart';
import 'package:fl_clash/features/network_insight/service_check/http.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves the service-check client validates TLS even though the app
/// installs FlClashHttpOverrides, which accepts any certificate, as the
/// global HttpOverrides. A local HTTPS server with a freshly generated
/// self-signed certificate stands in for a man-in-the-middle.
void main() {
  late Directory tempDir;
  late HttpServer server;
  HttpOverrides? previousOverrides;
  String? skipReason;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('panorama_tls_test');
    final key = '${tempDir.path}/key.pem';
    final cert = '${tempDir.path}/cert.pem';
    final ProcessResult generated;
    try {
      generated = await Process.run('openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-keyout',
        key,
        '-out',
        cert,
        '-days',
        '1',
        '-subj',
        '/CN=localhost',
      ]);
    } on ProcessException {
      skipReason = 'openssl is not installed';
      return;
    }
    if (generated.exitCode != 0) {
      skipReason = 'openssl failed: ${generated.stderr}';
      return;
    }
    final context = SecurityContext()
      ..useCertificateChain(cert)
      ..usePrivateKey(key);
    server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    server.listen((request) {
      request.response
        ..write('intercepted')
        ..close();
    });
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = FlClashHttpOverrides();
  });

  tearDownAll(() async {
    HttpOverrides.global = previousOverrides;
    if (skipReason == null) {
      await server.close(force: true);
    }
    await tempDir.delete(recursive: true);
  });

  Uri serverUri() => Uri.parse('https://localhost:${server.port}/');

  test('the app-wide HttpClient accepts the self-signed certificate', () async {
    if (skipReason != null) {
      markTestSkipped(skipReason!);
      return;
    }
    // Control: documents why ProxiedServiceHttp has to opt back in.
    final client = HttpClient()..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
    final response = await (await client.getUrl(serverUri())).close();
    expect(response.statusCode, 200);
  });

  test('ProxiedServiceHttp rejects the self-signed certificate', () async {
    if (skipReason != null) {
      markTestSkipped(skipReason!);
      return;
    }
    final http = ProxiedServiceHttp(findProxy: (_) => 'DIRECT');
    addTearDown(http.close);

    await expectLater(
      http.get(serverUri()),
      throwsA(
        isA<ServiceHttpException>().having(
          (e) => e.type,
          'type',
          ServiceCheckErrorType.tls,
        ),
      ),
    );
  });
}
