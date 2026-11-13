import 'dart:async';

import 'helpers/rust_native.dart';

/// The app's network, lifecycle and install decisions live in rust_api, so
/// every test runs with the library loaded, as `main` does.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initRustNative();
  await testMain();
}
