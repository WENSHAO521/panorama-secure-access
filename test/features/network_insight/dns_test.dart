import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/features/network_insight/dns.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DnsServer.parse', () {
    test('plain addresses are UDP', () {
      expect(
        DnsServer.parse('223.5.5.5'),
        const DnsServer(transport: DnsTransport.udp, host: '223.5.5.5'),
      );
      expect(DnsServer.parse('8.8.8.8:53').host, '8.8.8.8');
      expect(
        DnsServer.parse('2001:4860:4860::8888').host,
        '2001:4860:4860::8888',
      );
      expect(DnsServer.parse('[2001:4860::8888]:53').host, '2001:4860::8888');
    });

    test('schemes map to transports', () {
      expect(DnsServer.parse('tcp://1.1.1.1').transport, DnsTransport.tcp);
      expect(DnsServer.parse('tls://dns.google:853').host, 'dns.google');
      expect(
        DnsServer.parse('tls://dns.google:853').transport,
        DnsTransport.tls,
      );
      expect(
        DnsServer.parse('quic://dns.adguard.com').transport,
        DnsTransport.quic,
      );
      expect(DnsServer.parse('dhcp://en0').host, 'en0');
      expect(DnsServer.parse('system://').transport, DnsTransport.system);
      expect(DnsServer.parse('system').transport, DnsTransport.system);
    });

    test('DoH keeps only the host: no path, query or user info', () {
      final s = DnsServer.parse(
        'https://user:pw@dns.nextdns.io/abc123?token=x',
      );
      expect(s.transport, DnsTransport.https);
      expect(s.host, 'dns.nextdns.io');
      expect(s.toString(), isNot(contains('abc123')));
      expect(s.toString(), isNot(contains('pw')));
    });

    test('#Proxy routes through a proxy; #key=value options do not', () {
      expect(DnsServer.parse('https://1.1.1.1/dns-query#Proxy').via, 'Proxy');
      expect(DnsServer.parse('https://1.1.1.1/dns-query#h3=true').via, isNull);
    });
  });

  group('resolveDnsSection', () {
    const appDns = Dns(
      nameserver: ['https://doh.pub/dns-query'],
      nameserverPolicy: {'geosite:cn': '223.5.5.5,119.29.29.29'},
    );

    test('an enabled profile section is used as is', () {
      final r = resolveDnsSection(
        {
          'enable': true,
          'enhanced-mode': 'redir-host',
          'nameserver': ['1.1.1.1'],
        },
        appDns: appDns,
        overrideDns: false,
        appendSystemDns: false,
      );
      expect(r.source, DnsSource.profile);
      expect(r.dns['nameserver'], ['1.1.1.1']);
      expect(r.dns['enhanced-mode'], 'redir-host');
    });

    test('Override DNS replaces it with the app settings', () {
      final r = resolveDnsSection(
        {
          'enable': true,
          'nameserver': ['1.1.1.1'],
        },
        appDns: appDns,
        overrideDns: true,
        appendSystemDns: false,
      );
      expect(r.source, DnsSource.appOverride);
      expect(r.dns['nameserver'], ['https://doh.pub/dns-query']);
      expect(r.dns['nameserver-policy'], {
        'geosite:cn': ['223.5.5.5', '119.29.29.29'],
      });
    });

    test('a profile without DNS gets the app settings plus system', () {
      for (final section in [
        null,
        {'enable': false},
      ]) {
        final r = resolveDnsSection(
          section,
          appDns: appDns,
          overrideDns: false,
          appendSystemDns: false,
        );
        expect(r.source, DnsSource.appFallback);
        expect(r.dns['nameserver'], ['https://doh.pub/dns-query', 'system://']);
      }
    });

    test('"append system DNS" adds it once', () {
      final r = resolveDnsSection(
        {
          'enable': true,
          'nameserver': ['1.1.1.1', 'system://'],
        },
        appDns: appDns,
        overrideDns: false,
        appendSystemDns: true,
      );
      expect(r.dns['nameserver'], ['1.1.1.1', 'system://']);
      final r2 = resolveDnsSection(
        {
          'enable': true,
          'nameserver': ['1.1.1.1'],
        },
        appDns: appDns,
        overrideDns: false,
        appendSystemDns: true,
      );
      expect(r2.dns['nameserver'], ['1.1.1.1', 'system://']);
    });

    test("doesn't modify the profile's map", () {
      final profile = {
        'enable': true,
        'nameserver': ['1.1.1.1'],
      };
      resolveDnsSection(
        profile,
        appDns: appDns,
        overrideDns: false,
        appendSystemDns: true,
      );
      expect(profile['nameserver'], ['1.1.1.1']);
    });
  });

  group('DnsInsight.fromSection', () {
    test('reads mode, range, servers and policy count', () {
      final insight = DnsInsight.fromSection(const {
        'enhanced-mode': 'fake-ip',
        'fake-ip-range': '198.18.0.1/16',
        'nameserver': ['https://doh.pub/dns-query', 'system://'],
        'fallback': ['tls://8.8.4.4'],
        'proxy-server-nameserver': ['223.5.5.5'],
        'nameserver-policy': {'geosite:cn': '223.5.5.5', '+.lan': 'system'},
        'ipv6': true,
      }, DnsSource.profile);
      expect(insight.isFakeIp, isTrue);
      expect(insight.fakeIpRange, '198.18.0.1/16');
      expect(insight.nameservers.map((s) => s.transport), [
        DnsTransport.https,
        DnsTransport.system,
      ]);
      expect(insight.fallback.single.host, '8.8.4.4');
      expect(insight.proxyServerNameservers.single.host, '223.5.5.5');
      expect(insight.policyCount, 2);
      expect(insight.ipv6, isTrue);
    });

    test('missing fields: normal mode, no servers', () {
      final insight = DnsInsight.fromSection(const {}, DnsSource.profile);
      expect(insight.mode, 'normal');
      expect(insight.nameservers, isEmpty);
      expect(insight.fakeIpRange, isNull);
    });
  });
}
