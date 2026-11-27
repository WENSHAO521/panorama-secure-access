import 'package:fl_clash/main.dart';
import 'package:fl_clash/pages/error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a startup failure is logged with its stack trace', () {
    final printed = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    addTearDown(() => debugPrint = original);
    final error = StateError('boot failed');
    final stack = StackTrace.fromString(
      '#0 boot (package:fl_clash/main.dart:1)',
    );

    final app = initFailureApp(error, stack);

    expect(app, isA<InitErrorApp>().having((app) => app.error, 'error', error));
    expect(printed, [
      allOf(
        startsWith('[APP] Startup failed: $error'),
        contains('package:fl_clash/main.dart:1'),
      ),
    ]);
  });

  test('a framework error is logged after the frame that hit it', () async {
    final printed = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    addTearDown(() => debugPrint = original);

    logFlutterError(FlutterErrorDetails(exception: StateError('layout')));
    expect(printed, isEmpty);
    await Future<void>.delayed(Duration.zero);

    expect(printed, [contains('exception: Bad state: layout')]);
  });
}
