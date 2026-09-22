import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/profiles/profile_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 22, 12);
  int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  Profile subscription({SubscriptionInfo? info}) => Profile(
    id: 1,
    label: 'Work',
    url: 'https://sub.example.com/api/v1/client/subscribe?token=SECRET123',
    autoUpdateDuration: const Duration(hours: 12),
    subscriptionInfo: info,
  );

  ProfileSummary summarize(
    Profile p, {
    bool isCurrent = false,
    bool isUpdating = false,
  }) => ProfileSummary.of(
    p,
    isCurrent: isCurrent,
    isUpdating: isUpdating,
    now: now,
  );

  test('source is only the host, never the token-bearing path or query', () {
    final s = summarize(subscription());
    expect(s.sourceHost, 'sub.example.com');
    expect(s.isLocal, isFalse);
  });

  test('a local file has no source host', () {
    const local = Profile(id: 2, autoUpdateDuration: Duration());
    final s = summarize(local);
    expect(s.isLocal, isTrue);
    expect(s.sourceHost, isNull);
    expect(s.usage, isNull);
    expect(s.states, isEmpty);
  });

  test('traffic and expiry come from the subscription header', () {
    final s = summarize(
      subscription(
        info: SubscriptionInfo(
          upload: 1 << 30,
          download: 3 << 30,
          total: 16 << 30,
          expire: epoch(DateTime(2026, 12, 1)),
        ),
      ),
    );
    expect(s.usedBytes, 4 << 30);
    expect(s.totalBytes, 16 << 30);
    expect(s.usage, 0.25);
    expect(s.expiresAt, DateTime(2026, 12, 1));
    expect(s.hasNoExpiry, isFalse);
    expect(s.states, isEmpty);
  });

  test('a quota without an expiry date says so', () {
    final s = summarize(
      subscription(info: const SubscriptionInfo(download: 1, total: 10)),
    );
    expect(s.expiresAt, isNull);
    expect(s.hasNoExpiry, isTrue);
  });

  test('no quota reported: nothing about traffic or expiry', () {
    final s = summarize(subscription(info: const SubscriptionInfo()));
    expect(s.usage, isNull);
    expect(s.hasNoExpiry, isFalse);
  });

  test('states: in use, updating, expired, data used up', () {
    final s = summarize(
      subscription(
        info: SubscriptionInfo(
          download: 20,
          total: 10,
          expire: epoch(now.subtract(const Duration(days: 1))),
        ),
      ),
      isCurrent: true,
      isUpdating: true,
    );
    expect(s.states, [
      ProfileState.inUse,
      ProfileState.updating,
      ProfileState.expired,
      ProfileState.dataUsedUp,
    ]);
    expect(s.usage, 1.0);
  });

  test('not expired while the expiry is still ahead', () {
    final s = summarize(
      subscription(
        info: SubscriptionInfo(
          total: 10,
          expire: epoch(now.add(const Duration(hours: 1))),
        ),
      ),
    );
    expect(s.states, isNot(contains(ProfileState.expired)));
  });
}
