import 'package:dio/dio.dart';
import 'package:fl_clash/common/print.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compactError compacts DioException to type and status code', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 403,
      ),
    );
    expect(compactError(error), 'DioException(badResponse, HTTP 403)');
  });

  test('compactError omits the status code when the response is missing', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionError,
    );
    expect(compactError(error), 'DioException(connectionError)');
  });

  test('compactError keeps other exception messages', () {
    expect(compactError(StateError('boom')), contains('boom'));
  });

  group('redactSecrets', () {
    test('drops the token of a subscription link', () {
      expect(
        redactSecrets(
          'onAppLink: clash://install-config?url=https%3A%2F%2Fsub.example.com',
        ),
        'onAppLink: clash://install-config?***',
      );
      expect(
        redactSecrets('GET https://user:pass@example.com/api/sub?token=abc'),
        'GET https://***@example.com/api/sub?***',
      );
      expect(
        redactSecrets('https://example.com/s/0123456789abcdefXYZ/clash'),
        'https://example.com/s/***/clash',
      );
    });

    test('keeps hosts, short paths and plain text', () {
      expect(
        redactSecrets('timeout talking to https://example.com/generate_204'),
        'timeout talking to https://example.com/generate_204',
      );
      expect(redactSecrets('no link here'), 'no link here');
    });

    test('drops age secret keys', () {
      expect(
        redactSecrets('key AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQ rejected'),
        'key AGE-SECRET-KEY-*** rejected',
      );
    });
  });
}
