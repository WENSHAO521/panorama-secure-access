import 'dart:async';
import 'dart:io';

import 'package:fl_clash/features/network_insight/identity.dart';
import 'package:fl_clash/models/common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_service_http.dart';

const _v4 = 'https://1.1.1.1/cdn-cgi/trace';
const _v6 = 'https://[2606:4700:4700::1111]/cdn-cgi/trace';

String _trace(String ip, String loc) => 'fl=1\nh=1.1.1.1\nip=$ip\nloc=$loc\n';

void main() {
  group('probeIpFamily', () {
    test('IPv4 probe goes to the IPv4 literal and reads the exit', () async {
      final http = FakeServiceHttp({_v4: reply(_trace('203.0.113.7', 'JP'))});
      final probe = await probeIpFamily(http, IpFamily.ipv4);

      expect(probe.status, IpFamilyStatus.available);
      expect(probe.exitIp, '203.0.113.7');
      expect(probe.regionCode, 'JP');
      expect(http.requests.single.uri.host, '1.1.1.1');
    });

    test('IPv6 probe goes to the IPv6 literal', () async {
      final http = FakeServiceHttp({_v6: reply(_trace('2001:db8::7', 'DE'))});
      final probe = await probeIpFamily(http, IpFamily.ipv6);

      expect(probe.status, IpFamilyStatus.available);
      expect(probe.exitIp, '2001:db8::7');
      expect(http.requests.single.uri.host, '2606:4700:4700::1111');
    });

    test('an unreachable family is unavailable, not an error', () async {
      final probe = await probeIpFamily(
        FakeServiceHttp({_v6: failWith()}),
        IpFamily.ipv6,
      );
      expect(probe.status, IpFamilyStatus.unavailable);
      expect(probe.exitIp, isNull);
    });

    test('a hung probe times out and aborts its session', () async {
      final http = FakeServiceHttp({_v4: (_) => Completer<Never>().future});
      final probe = await probeIpFamily(
        http,
        IpFamily.ipv4,
        timeout: const Duration(milliseconds: 20),
      );
      expect(probe.status, IpFamilyStatus.timeout);
      expect(http.closed, isTrue);
    });

    test('a page without an ip= line is not treated as reachable', () async {
      final probe = await probeIpFamily(
        FakeServiceHttp({_v4: reply('<html>captive portal</html>')}),
        IpFamily.ipv4,
      );
      expect(probe.status, IpFamilyStatus.unavailable);
    });

    test('an error status is unavailable even with a trace body', () async {
      final probe = await probeIpFamily(
        FakeServiceHttp({_v4: reply(_trace('203.0.113.7', 'JP'), status: 403)}),
        IpFamily.ipv4,
      );
      expect(probe.status, IpFamilyStatus.unavailable);
    });
  });

  group('NetworkIdentity', () {
    IpFamilyProbe up(IpFamily family, String ip, String loc) => IpFamilyProbe(
      family: family,
      status: IpFamilyStatus.available,
      exitIp: ip,
      regionCode: loc,
    );
    IpFamilyProbe down(IpFamily family) =>
        IpFamilyProbe(family: family, status: IpFamilyStatus.unavailable);

    final checkedAt = DateTime(2026, 9, 22);

    test('IPv4 only', () {
      final identity = NetworkIdentity(
        checkedAt: checkedAt,
        ipv4: up(IpFamily.ipv4, '203.0.113.7', 'JP'),
        ipv6: down(IpFamily.ipv6),
      );
      expect(identity.publicIPv4, '203.0.113.7');
      expect(identity.publicIPv6, isNull);
      expect(identity.countryCode, 'JP');
    });

    test('IPv6 only', () {
      final identity = NetworkIdentity(
        checkedAt: checkedAt,
        ipv4: down(IpFamily.ipv4),
        ipv6: up(IpFamily.ipv6, '2001:db8::7', 'DE'),
      );
      expect(identity.publicIPv4, isNull);
      expect(identity.publicIPv6, '2001:db8::7');
      expect(identity.countryCode, 'DE');
    });

    test('dual stack prefers the lookup service country', () {
      final identity = NetworkIdentity(
        checkedAt: checkedAt,
        publicIp: const IpInfo(ip: '203.0.113.7', countryCode: 'jp'),
        ipv4: up(IpFamily.ipv4, '203.0.113.7', 'US'),
        ipv6: up(IpFamily.ipv6, '2001:db8::7', 'US'),
      );
      expect(identity.publicIPv4, isNotNull);
      expect(identity.publicIPv6, isNotNull);
      expect(identity.countryCode, 'JP');
    });

    test('local addresses exclude the TUN device', () {
      final identity = NetworkIdentity(
        checkedAt: checkedAt,
        interfaces: const [
          LocalInterface(name: 'en0', addresses: ['192.168.1.10', 'fe80::1']),
          LocalInterface(name: 'utun4', addresses: ['198.18.0.1'], isTun: true),
        ],
      );
      expect(identity.localIPv4, ['192.168.1.10']);
      expect(identity.localIPv6, ['fe80::1']);
    });
  });

  group('listLocalInterfaces', () {
    test('flags TUN by device name or by the 198.18/15 range', () async {
      final interfaces = await listLocalInterfaces(
        tunDeviceName: 'PanoramaTun',
        lister: () async => [
          await _interface('eth0', ['192.168.1.10']),
          await _interface('PanoramaTun', ['172.19.0.1']),
          await _interface('utun7', ['198.19.0.1']),
          await _interface('down0', []),
        ],
      );
      expect(interfaces.map((i) => i.name), ['eth0', 'PanoramaTun', 'utun7']);
      expect(interfaces.map((i) => i.isTun), [false, true, true]);
    });
  });

  test('parseTrace ignores malformed lines', () {
    expect(parseTrace('ip=1.2.3.4\ngarbage\n=x\nloc=JP'), {
      'ip': '1.2.3.4',
      'loc': 'JP',
    });
  });

  group('IpInfo source parsing', () {
    test('ipwho.is nests ASN/ISP under connection', () {
      final info = IpInfo.fromIpWhoIsJson({
        'ip': '203.0.113.7',
        'country_code': 'JP',
        'country': 'Japan',
        'region': 'Tokyo',
        'city': 'Tokyo',
        'connection': {'asn': 2516, 'isp': 'KDDI', 'org': 'KDDI Corporation'},
      });
      expect(info.asn, 2516);
      expect(info.isp, 'KDDI');
      expect(info.organization, 'KDDI Corporation');
      expect(info.city, 'Tokyo');
    });

    test('ip-api.com and ipinfo.io pack the ASN into a string', () {
      final ipApi = IpInfo.fromIpAPIJson({
        'query': '203.0.113.7',
        'countryCode': 'US',
        'as': 'AS13335 Cloudflare, Inc.',
        'isp': 'Cloudflare',
      });
      expect(ipApi.asn, 13335);

      final ipInfo = IpInfo.fromIpInfoIoJson({
        'ip': '203.0.113.7',
        'country': 'US',
        'org': 'AS13335 Cloudflare, Inc.',
      });
      expect(ipInfo.asn, 13335);
      expect(ipInfo.organization, 'Cloudflare, Inc.');
    });

    test('missing or wrongly-typed optional fields become null', () {
      final info = IpInfo.fromIpApiCoJson({
        'ip': '203.0.113.7',
        'country_code': 'US',
        'asn': ['unexpected'],
        'city': '',
      });
      expect(info.asn, isNull);
      expect(info.city, isNull);
      expect(info.countryCode, 'US');
    });

    test('still rejects a response without the required fields', () {
      expect(
        () => IpInfo.fromIpSbJson({'country_code': 'US'}),
        throwsFormatException,
      );
    });
  });
}

/// dart:io's NetworkInterface has no public constructor; this fakes one.
Future<NetworkInterface> _interface(String name, List<String> addresses) async {
  return _FakeInterface(name, [
    for (final address in addresses) InternetAddress(address),
  ]);
}

class _FakeInterface implements NetworkInterface {
  @override
  final String name;
  @override
  final List<InternetAddress> addresses;

  _FakeInterface(this.name, this.addresses);

  @override
  int get index => 0;
}
