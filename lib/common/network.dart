import 'dart:io';

import 'package:flutter/foundation.dart';

import 'netdiag.dart';

typedef NetworkInterfaceLister =
    Future<List<NetworkInterface>> Function({bool includeLoopback});

@visibleForTesting
NetworkInterfaceLister listNetworkInterfaces =
    ({bool includeLoopback = false}) =>
        NetworkInterface.list(includeLoopback: includeLoopback);

extension InternetAddressExt on InternetAddress {
  bool get isIPv4 {
    return type == InternetAddressType.IPv4;
  }
}

Future<String?> getLocalIpAddress() async {
  final interfaces = await listNetworkInterfaces(includeLoopback: false);
  return pickLocalAddress([
    for (final interface in interfaces)
      LocalInterface(
        name: interface.name,
        addresses: [
          for (final address in interface.addresses)
            LocalAddress(address: address.address, ipv4: address.isIPv4),
        ],
      ),
  ]);
}
