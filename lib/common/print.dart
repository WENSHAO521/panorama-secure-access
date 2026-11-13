import 'package:dio/dio.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/widgets.dart';

String compactError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    return statusCode != null
        ? 'DioException(${error.type.name}, HTTP $statusCode)'
        : 'DioException(${error.type.name})';
  }
  return error.toString();
}

final _url = RegExp(
  r'\b([a-zA-Z][\w+.-]*://)([^\s/?#@]*@)?([^\s/?#]*)([^\s?#]*)(\?[^\s#]*)?',
);
final _token = RegExp(r'[A-Za-z0-9_-]{16,}');
final _ageKey = RegExp(r'AGE-SECRET-KEY-1[0-9A-Z]+');

/// A subscription token hides in the user info, query or a long path segment.
String redactSecrets(String text) => text
    .replaceAll(_ageKey, 'AGE-SECRET-KEY-***')
    .replaceAllMapped(_url, (match) {
      final path = match[4]!.replaceAll(_token, '***');
      return [
        match[1],
        if (match[2] != null) '***@',
        match[3],
        path,
        if (match[5] != null) '?***',
      ].join();
    });

class CommonPrint {
  static CommonPrint? _instance;

  CommonPrint._internal();

  factory CommonPrint() {
    _instance ??= CommonPrint._internal();
    return _instance!;
  }

  void log(String? text, {LogLevel logLevel = LogLevel.info}) {
    final payload = '[APP] ${text == null ? null : redactSecrets(text)}';
    debugPrint(payload);
    if (!globalState.isAttach) {
      return;
    }
    globalState.container
        .read(logsProvider.notifier)
        .add(Log.app(payload).copyWith(logLevel: logLevel));
  }
}

final commonPrint = CommonPrint();
