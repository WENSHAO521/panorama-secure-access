import 'dart:async';

import 'package:fl_clash/features/network_insight/service_check/http.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';

typedef FakeHandler =
    FutureOr<ServiceHttpResponse> Function(FakeRequest request);

class FakeRequest {
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
  final bool followRedirects;

  const FakeRequest(
    this.method,
    this.uri,
    this.headers,
    this.body,
    this.followRedirects,
  );
}

/// Canned-response [ServiceHttp]. Routes are matched by URL prefix; an
/// unmatched request fails like a network error so a test can't silently
/// depend on a real service.
class FakeServiceHttp implements ServiceHttp {
  final Map<String, FakeHandler> routes;
  final requests = <FakeRequest>[];
  bool closed = false;

  FakeServiceHttp(this.routes);

  @override
  Future<ServiceHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
    bool followRedirects = true,
  }) => _handle(FakeRequest('GET', uri, headers, null, followRedirects));

  @override
  Future<ServiceHttpResponse> post(
    Uri uri, {
    Map<String, String> headers = const {},
    String? body,
  }) => _handle(FakeRequest('POST', uri, headers, body, true));

  Future<ServiceHttpResponse> _handle(FakeRequest request) async {
    requests.add(request);
    final url = request.uri.toString();
    String? matched;
    for (final prefix in routes.keys) {
      if (url.startsWith(prefix) &&
          (matched == null || prefix.length > matched.length)) {
        matched = prefix;
      }
    }
    if (matched == null) {
      throw ServiceHttpException(
        ServiceCheckErrorType.network,
        'No fake route for $url',
      );
    }
    return routes[matched]!(request);
  }

  @override
  void close() {
    closed = true;
  }
}

ServiceHttpResponse respond(
  String body, {
  int status = 200,
  String? url,
  Map<String, String> headers = const {},
}) {
  return ServiceHttpResponse(
    statusCode: status,
    body: body,
    uri: Uri.parse(url ?? 'https://example.invalid/'),
    headers: headers,
  );
}

FakeHandler reply(
  String body, {
  int status = 200,
  String? url,
  Map<String, String> headers = const {},
}) {
  return (request) => respond(
    body,
    status: status,
    url: url ?? request.uri.toString(),
    headers: headers,
  );
}

FakeHandler failWith([
  ServiceCheckErrorType type = ServiceCheckErrorType.network,
]) {
  return (_) => throw ServiceHttpException(type, 'simulated failure');
}
