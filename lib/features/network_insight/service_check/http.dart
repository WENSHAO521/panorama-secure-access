import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Upper bound on a response body a checker will read. Service landing
/// pages are well under this; anything larger isn't a page we can parse.
const _maxBodyBytes = 4 * 1024 * 1024;

/// Same desktop-Chrome identity the reference implementation sends, so
/// services serve the page the checks were written against.
const serviceCheckUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

class ServiceHttpResponse {
  final int statusCode;

  /// Lower-cased header names; repeated headers are joined with ", ".
  final Map<String, String> headers;
  final String body;

  /// The URI of the response actually returned, after any redirects.
  final Uri uri;

  const ServiceHttpResponse({
    required this.statusCode,
    required this.body,
    required this.uri,
    this.headers = const {},
  });

  String? header(String name) => headers[name.toLowerCase()];

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ServiceHttpException implements Exception {
  final ServiceCheckErrorType type;
  final String message;

  const ServiceHttpException(this.type, this.message);

  @override
  String toString() => 'ServiceHttpException($type, $message)';
}

/// The only way a checker touches the network, so tests can substitute
/// canned responses and never reach real third-party services.
abstract interface class ServiceHttp {
  Future<ServiceHttpResponse> get(
    Uri uri, {
    Map<String, String> headers,
    bool followRedirects,
  });

  Future<ServiceHttpResponse> post(
    Uri uri, {
    Map<String, String> headers,
    String? body,
  });

  /// Aborts any in-flight request. Used on timeout and cancellation.
  void close();
}

/// Real [ServiceHttp] used by the app: routes through the proxy route
/// chosen by [findProxy] (the core's mixed port while connected, so the
/// check sees the active node's exit), keeps cookies for the duration of
/// one service's check, and validates TLS certificates and host names.
class ProxiedServiceHttp implements ServiceHttp {
  final HttpClient _client;
  final Map<String, Map<String, String>> _cookies = {};

  ProxiedServiceHttp({
    required String Function(Uri uri) findProxy,
    Duration connectionTimeout = const Duration(seconds: 10),
  }) : _client = HttpClient() {
    _client
      ..findProxy = findProxy
      ..connectionTimeout = connectionTimeout
      ..userAgent = serviceCheckUserAgent
      // HttpOverrides.global (FlClashHttpOverrides) installs an accept-all
      // certificate callback on every HttpClient in the app. Service checks
      // talk to third parties through the user's proxy route and must fail
      // on a bad certificate, so the default (reject) behaviour is restored.
      ..badCertificateCallback = null;
  }

  @override
  Future<ServiceHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
    bool followRedirects = true,
  }) {
    return _send('GET', uri, headers, null, followRedirects);
  }

  @override
  Future<ServiceHttpResponse> post(
    Uri uri, {
    Map<String, String> headers = const {},
    String? body,
  }) {
    return _send('POST', uri, headers, body, true);
  }

  Future<ServiceHttpResponse> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
    bool followRedirects,
  ) async {
    try {
      final request = await _client.openUrl(method, uri);
      request
        ..followRedirects = followRedirects
        ..maxRedirects = 10;
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
      final cookie = _cookieHeaderFor(uri);
      if (cookie != null) {
        request.headers.set(HttpHeaders.cookieHeader, cookie);
      }
      headers.forEach(request.headers.set);
      if (body != null) {
        request.write(body);
      }
      final response = await request.close();
      _storeCookies(uri, response.cookies);
      final text = await _readBody(response);
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name.toLowerCase()] = values.join(', ');
      });
      final finalUri = response.redirects.isEmpty
          ? uri
          : uri.resolveUri(response.redirects.last.location);
      return ServiceHttpResponse(
        statusCode: response.statusCode,
        headers: responseHeaders,
        body: text,
        uri: finalUri,
      );
    } on TlsException catch (e) {
      throw ServiceHttpException(ServiceCheckErrorType.tls, e.message);
    } on SocketException catch (e) {
      throw ServiceHttpException(ServiceCheckErrorType.network, e.message);
    } on HttpException catch (e) {
      throw ServiceHttpException(ServiceCheckErrorType.network, e.message);
    }
  }

  Future<String> _readBody(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > _maxBodyBytes) {
        break;
      }
    }
    return const Utf8Decoder(allowMalformed: true).convert(bytes);
  }

  String? _cookieHeaderFor(Uri uri) {
    final jar = _cookies[uri.host];
    if (jar == null || jar.isEmpty) {
      return null;
    }
    return jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void _storeCookies(Uri uri, List<Cookie> cookies) {
    if (cookies.isEmpty) {
      return;
    }
    final jar = _cookies.putIfAbsent(uri.host, () => {});
    for (final cookie in cookies) {
      jar[cookie.name] = cookie.value;
    }
  }

  @override
  void close() {
    _client.close(force: true);
  }
}
