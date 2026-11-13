import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rust_api/netcfg.dart' as native;
import 'package:rust_api/rust_api.dart' show isRustLibInitialized;

// The dart* functions here and in cidr.dart are the reference for `netcfg` in
// rust_api, and the fallback wherever the Rust library is not loaded.

bool isHost(String value) =>
    isRustLibInitialized ? native.isHost(value: value) : dartIsHost(value);

/// mihomo starts no DNS server, and only logs why, for an address this refuses.
bool isListenAddress(String value) => isRustLibInitialized
    ? native.isListenAddress(value: value)
    : dartIsListenAddress(value);

bool isPortRange(String value) => isRustLibInitialized
    ? native.isPortRange(value: value)
    : dartIsPortRange(value);

final _portRange = RegExp(r'^([0-9]{1,5})(?:-([0-9]{1,5}))?$');

final _domainLabel = RegExp(
  r'^[A-Za-z0-9_]([A-Za-z0-9_-]{0,61}[A-Za-z0-9_])?$',
);

final _port = RegExp(r'^[0-9]{1,5}$');

bool _isIpv6(String value) =>
    InternetAddress.tryParse(value)?.type == InternetAddressType.IPv6;

@visibleForTesting
bool dartIsHost(String value) => value.contains(':')
    ? _isIpv6(value)
    : value.length <= 253 && value.split('.').every(_domainLabel.hasMatch);

@visibleForTesting
bool dartIsListenAddress(String value) {
  final colon = value.lastIndexOf(':');
  final host = colon < 0 ? null : value.substring(0, colon);
  final port = colon < 0 ? '' : value.substring(colon + 1);
  final validHost = switch (host) {
    null => false,
    '' => true,
    final host when host.startsWith('[') && host.endsWith(']') => _isIpv6(
      host.substring(1, host.length - 1),
    ),
    final host => !host.contains(':') && dartIsHost(host),
  };
  final validPort =
      _port.hasMatch(port) && int.parse(port) > 0 && int.parse(port) <= 65535;
  return validHost && validPort;
}

@visibleForTesting
bool dartIsPortRange(String value) {
  final match = _portRange.firstMatch(value);
  return match != null &&
      [?match[1], ?match[2]].every((port) => int.parse(port) <= 65535);
}
