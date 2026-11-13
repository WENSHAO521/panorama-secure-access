import 'package:fl_clash/common/netdiag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rust_api/netdiag.dart' as native;

import '../helpers/rust_native.dart';

const _bools = [false, true];

LocalInterface _interface(String name, List<(String, bool)> addresses) =>
    LocalInterface(
      name: name,
      addresses: [
        for (final (address, ipv4) in addresses)
          LocalAddress(address: address, ipv4: ipv4),
      ],
    );

void main() {
  setUpAll(initRustNative);

  test('DNS decisions agree', () {
    for (final applied in [null, 'Wi-Fi', 'Ethernet', '']) {
      for (final service in ['Wi-Fi', 'Ethernet', '']) {
        expect(
          native.dnsApplyRoute(appliedService: applied, service: service),
          dartDnsApplyRoute(applied, service),
          reason: '$applied $service',
        );
      }
    }
    for (final current in [
      <String>[],
      ['1.1.1.1'],
      ['223.5.5.5'],
      ['1.1.1.1', '223.5.5.5', '8.8.8.8'],
    ]) {
      expect(
        native.dnsPatchedServers(current: current, fallback: '223.5.5.5'),
        dartDnsPatchedServers(current, '223.5.5.5'),
        reason: '$current',
      );
    }
  });

  test('failure classification agrees', () {
    for (final reason in [null, 'timeout', 'dns', 'tls', 'connection', 'x']) {
      expect(
        native.coreFailureKind(reason: reason),
        dartCoreFailureKind(reason),
      );
    }
    for (var status = 0; status < 1000; status++) {
      expect(
        native.httpStatusClass(status: status),
        dartHttpStatusClass(status),
        reason: '$status',
      );
    }
  });

  test('local address choice agrees', () {
    final cases = [
      <LocalInterface>[],
      [_interface('lo', [])],
      [
        _interface('utun3', [('10.9.0.1', true)]),
        _interface('en0', [('fe80::1', false), ('192.168.1.20', true)]),
      ],
      [
        _interface('tun0', [('fd00::2', false)]),
        _interface('eth1', [('10.0.0.2', true)]),
        _interface('WLAN1', [('fe80::3', false)]),
      ],
      [
        _interface('Wi-Fi', []),
        _interface('en5', [('fd00::5', false), ('fd00::6', false)]),
        _interface('en6', [('10.6.0.1', true)]),
      ],
    ];
    for (final interfaces in cases) {
      expect(
        native.pickLocalAddress(interfaces: interfaces),
        dartPickLocalAddress(interfaces),
      );
    }
  });

  test('network change reactions agree', () {
    for (final hadVpn in _bools) {
      for (final hasVpn in _bools) {
        for (final desktop in _bools) {
          expect(
            native.networkChangeReaction(
              hadVpn: hadVpn,
              hasVpn: hasVpn,
              desktop: desktop,
            ),
            dartNetworkChangeReaction(hadVpn, hasVpn, desktop),
            reason: '$hadVpn $hasVpn $desktop',
          );
        }
      }
    }
  });
}
