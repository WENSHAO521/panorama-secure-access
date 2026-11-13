import 'package:flutter_test/flutter_test.dart';

import '../helpers/rust_native.dart';
import 'legacy_data_test.dart' as legacy_data;
import 'legacy_install_test.dart' as legacy_install;
import 'network_test.dart' as network;
import 'system_dns_test.dart' as system_dns;

void main() {
  setUpAll(initRustNative);

  group('with Rust deciding', () {
    group('legacy data', legacy_data.main);
    group('legacy install', legacy_install.main);
    group('network', network.main);
    group('system DNS', system_dns.main);
  });
}
