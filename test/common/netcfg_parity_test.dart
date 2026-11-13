import 'dart:io';
import 'dart:math';

import 'package:fl_clash/common/cidr.dart';
import 'package:fl_clash/common/netcfg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rust_api/netcfg.dart' as native;

import '../helpers/rust_native.dart';

const _addresses = [
  '',
  ' ',
  'a',
  'a.',
  '.a',
  'example.com',
  '_dns.example.com',
  'x-y.z',
  '-a.com',
  'a-.com',
  'a b',
  'a..b',
  'localhost',
  '1.2.3.4',
  '01.2.3.4',
  '1.2.3',
  '256.1.1.1',
  '0.0.0.0',
  '::',
  '::1',
  '[::1]',
  'fe80::1',
  '::ffff:1.2.3.4',
  '::ffff:01.2.3.4',
  '1:2',
  '1:2:3:4:5:6:7:8',
  '1:2:3:4:5:6:7:8:9',
  '12345::',
  'gggg::',
  ':53',
  '0.0.0.0:1053',
  '[::]:53',
  '[::1]:0',
  'localhost:65535',
  'localhost:65536',
  '::1:53',
  'a:b',
  ':053',
  ':053x',
  '53',
  '0',
  '00080',
  '443',
  '1000-2000',
  '65535',
  '65536',
  '1-',
  '-1',
  '1-2-3',
  '123456',
  ' 1',
  'GEOIP:cn',
  'geoip:',
  'rule-set:private',
  'RULE-SET:x',
  '10.0.0.0/8',
  '10.0.0.0/+8',
  '10.0.0.0/08',
  '10.0.0.0/33',
  '10.0.0.0/8/8',
  '192.168.1.5/24',
  '192.168.01.0/24',
  ' 10.0.0.0/8',
  '10.0.0.0/8 ',
  'fd00::/8',
  'fd00::/129',
  'fe80::1%eth0/64',
  '::ffff:1.2.3.4/96',
  '/8',
  '1.2.3.4/',
  '中文.com',
  'ａ.com',
];

// Dart prints an IPv4-compatible address dotted (::1.2.3.4) where Rust and Go
// print it in hex; the core reads both, so blocks compare by value.
List<(String, String)> _blocks(List<String> cidrs) => [
  for (final cidr in cidrs)
    (
      InternetAddress(cidr.split('/').first).rawAddress.join('.'),
      cidr.split('/').last,
    ),
];

String _randomCidr(Random random) {
  if (random.nextInt(3) == 0) {
    final words = [for (var i = 0; i < 8; i++) random.nextInt(0x10000)];
    if (random.nextBool()) {
      words.fillRange(0, random.nextInt(8), 0);
    }
    final address = words.map((word) => word.toRadixString(16)).join(':');
    return '$address/${random.nextInt(129)}';
  }
  final octets = [for (var i = 0; i < 4; i++) random.nextInt(256)];
  return '${octets.join('.')}/${random.nextInt(33)}';
}

void main() {
  setUpAll(initRustNative);

  test('the Rust address checks agree with the Dart reference', () {
    for (final value in [
      ..._addresses,
      for (final address in _addresses) '$address:53',
    ]) {
      expect(native.isHost(value: value), dartIsHost(value), reason: value);
      expect(
        native.isListenAddress(value: value),
        dartIsListenAddress(value),
        reason: value,
      );
      expect(
        native.isPortRange(value: value),
        dartIsPortRange(value),
        reason: value,
      );
      expect(native.isCidr(value: value), dartIsCidr(value), reason: value);
      expect(
        native.isIpMatcher(value: value),
        dartIsIpMatcher(value),
        reason: value,
      );
    }
  });

  test('the Rust route subtraction agrees with the Dart reference', () async {
    final random = Random(20261113);
    for (var round = 0; round < 300; round++) {
      final include = [
        for (var i = random.nextInt(4); i > 0; i--) _randomCidr(random),
        if (round.isEven) 'not a cidr',
      ];
      final exclude = [
        for (var i = random.nextInt(12); i > 0; i--) _randomCidr(random),
      ];
      final whole = random.nextBool();
      expect(
        _blocks(
          await native.subtractCidrs(
            include: include,
            exclude: exclude,
            wholeWhenEmpty: whole,
          ),
        ),
        _blocks(subtractCidrs(include, exclude, wholeWhenEmpty: whole)),
        reason: '$include - $exclude whole=$whole',
      );
    }
  });

  test('the shared entry points use Rust once it is loaded', () async {
    expect(isHost('example.com'), isTrue);
    expect(isCidr('10.0.0.0/8'), isTrue);
    expect(
      await subtractCidrsTask(const ['0.0.0.0/0'], const ['128.0.0.0/1']),
      ['0.0.0.0/1'],
    );
  });
}
