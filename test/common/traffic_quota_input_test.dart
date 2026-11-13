import 'package:fl_clash/common/traffic_quota_input.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrafficQuotaInput', () {
    test('none or an empty field keeps the subscription total', () {
      for (final input in [
        TrafficQuotaInput.parse('', QuotaUnit.gb),
        TrafficQuotaInput.parse('   ', QuotaUnit.tb),
        TrafficQuotaInput.parse('100', QuotaUnit.none),
      ]) {
        expect(input.isValid, isTrue);
        expect(input.bytes, isNull);
        expect(input.quota(TrafficQuotaPeriod.monthly), isNull);
      }
    });

    test('integers and up to three decimals convert by unit', () {
      expect(TrafficQuotaInput.parse('100', QuotaUnit.mb).bytes, 100 << 20);
      expect(TrafficQuotaInput.parse(' 1.5 ', QuotaUnit.gb).bytes, 3 << 29);
      expect(
        TrafficQuotaInput.parse('0.125', QuotaUnit.tb).bytes,
        (1 << 40) ~/ 8,
      );
      expect(
        TrafficQuotaInput.parse(
          '2',
          QuotaUnit.gb,
        ).quota(TrafficQuotaPeriod.permanent),
        const TrafficQuota(
          total: 2 << 30,
          period: TrafficQuotaPeriod.permanent,
        ),
      );
    });

    test('rejects zero, signs, NaN, Infinity and anything not a number', () {
      for (final text in [
        '0',
        '0.0',
        '0.0001',
        '-1',
        '+1',
        'NaN',
        'Infinity',
        '1e3',
        '1.2.3',
        '.5',
        '5.',
        '1,5',
        'abc',
        '1.2345',
      ]) {
        expect(
          TrafficQuotaInput.parse(text, QuotaUnit.gb).error,
          TrafficQuotaInputError.invalid,
          reason: text,
        );
      }
    });

    test('rejects totals above 1024 TB', () {
      expect(TrafficQuotaInput.parse('1024', QuotaUnit.tb).bytes, 1 << 50);
      expect(
        TrafficQuotaInput.parse('1024.001', QuotaUnit.tb).error,
        TrafficQuotaInputError.tooLarge,
      );
      expect(
        TrafficQuotaInput.parse('9999999999', QuotaUnit.tb).error,
        TrafficQuotaInputError.tooLarge,
      );
    });

    test('a saved total reads back in the unit it fills', () {
      const total = 3 << 29;
      final unit = QuotaUnit.of(total);

      expect(unit, QuotaUnit.gb);
      expect(unit.format(total), '1.5');
      expect(TrafficQuotaInput.parse(unit.format(total), unit).bytes, total);
      expect(QuotaUnit.of(1), QuotaUnit.mb);
      expect(QuotaUnit.of(5 << 40), QuotaUnit.tb);
    });
  });

  group('Profile.trafficInfo', () {
    const info = SubscriptionInfo(
      upload: 3 << 30,
      download: 9 << 30,
      total: 100 << 30,
      expire: 1900000000,
    );

    test('overrides only the total, never used traffic or expiry', () {
      final profile = Profile.normal(url: 'https://example.com').copyWith(
        subscriptionInfo: info,
        trafficQuota: const TrafficQuota(total: 10 << 30),
      );
      final shown = profile.trafficInfo!;

      expect(shown.total, 10 << 30);
      expect(shown.upload, info.upload);
      expect(shown.download, info.download);
      expect(shown.expire, info.expire);
      expect(profile.subscriptionInfo, info);
      expect(shown.usage, 1.0);
    });

    test('without a quota the subscription total applies', () {
      final profile = Profile.normal(
        url: 'https://example.com',
      ).copyWith(subscriptionInfo: info);

      expect(profile.trafficInfo, info);
      expect(profile.trafficInfo!.usage, closeTo(0.12, 1e-9));
    });

    test('a refreshed subscription keeps the quota', () {
      final profile = Profile.normal(url: 'https://example.com').copyWith(
        subscriptionInfo: info,
        trafficQuota: const TrafficQuota(total: 10 << 30),
      );
      final refreshed = profile.copyWith(
        subscriptionInfo: info.copyWith(download: 20 << 30),
      );

      expect(refreshed.trafficQuota, profile.trafficQuota);
      expect(refreshed.trafficInfo!.total, 10 << 30);
    });

    test('the quota is stored and read back by the database column', () {
      const converter = TrafficQuotaConverter();
      const quota = TrafficQuota(
        total: 7 << 30,
        period: TrafficQuotaPeriod.permanent,
      );

      expect(converter.fromSql(converter.toSql(quota)), quota);
      expect(converter.toSql(null), isNull);
      expect(converter.fromSql(null), isNull);
    });
  });
}
