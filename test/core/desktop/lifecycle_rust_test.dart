import 'package:fl_clash/core/desktop/lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/rust_native.dart';
import 'lifecycle_test.dart' as lifecycle;

void main() {
  setUpAll(initRustNative);

  test('the lifecycle decides through Rust once the library is loaded', () {
    expect(lifecyclePolicy, isA<RustLifecyclePolicy>());
  });

  group('with the Rust policy', lifecycle.main);
}
