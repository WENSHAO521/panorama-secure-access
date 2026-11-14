import 'dart:convert';

import 'package:fl_clash/common/preferences.dart';
import 'package:fl_clash/features/invite/invite.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/preferences.dart';
import '../helpers/test_app.dart';

// Signed by the server's token code with the Ed25519 key whose seed is 32
// bytes of 7.
final _publicKey = base64.decode(
  '6kpsY+KcUgq+9VB7Ey7F+ZVHdq6+vnuSQh7qaRRG0iw=',
);
const _device = 'device-aaaaaaaaaaaaaaaa';
const _live =
    'eyJ2IjoxLCJjIjoiQUJDREVGR0giLCJkIjoiZGV2aWNlLWFhYWFhYWFhYWFhYWFhYWEiLCJpYXQiOjQwMDAwMDAwMDAsImV4cCI6NDEwMjQ0NDgwMH0.T0CxCgAKd5kTERktzggMeJaZafoQkmMk2p1Udo34MtsJ8H0MHUDQqfTpGAeKv_7Af3HETsKZ8yORsxRC7XibAg';
const _expired =
    'eyJ2IjoxLCJjIjoiQUJDREVGR0giLCJkIjoiZGV2aWNlLWFhYWFhYWFhYWFhYWFhYWEiLCJpYXQiOjk0NjY4NDgwMCwiZXhwIjo5NDY2ODQ4MDB9._EQCGHvHsPogetdjA4jHQWNVR91AYc40pJeJRmQdJ-bz-Qiq1KH3XRtBBcK6KysjpXJcE01TWapX5gPKgotLCw';
const _otherDevice =
    'eyJ2IjoxLCJjIjoiQUJDREVGR0giLCJkIjoiZGV2aWNlLWJiYmJiYmJiYmJiYmJiYmIiLCJpYXQiOjQwMDAwMDAwMDAsImV4cCI6NDEwMjQ0NDgwMH0.j7L4VI24BIaAM3i9cav8DZ8b8N9WX1w3lSsZktLPK5mvwYf6r8dTzLa3BTOX0G81ZtbL6F-77IugXZ2616nODg';

class _FakeClient implements InviteClient {
  InviteReply redeemReply = (token: _live, refusal: null);
  InviteReply refreshReply = (token: _live, refusal: null);
  final redeemed = <(String, String)>[];
  final refreshed = <String>[];

  @override
  Future<InviteReply> redeem(String code, String device) async {
    redeemed.add((code, device));
    return redeemReply;
  }

  @override
  Future<InviteReply> refresh(String token) async {
    refreshed.add(token);
    return refreshReply;
  }
}

ProviderContainer _container(
  _FakeClient client, {
  String? token,
  bool configured = true,
}) {
  final container = ProviderContainer(
    overrides: [
      inviteConfigProvider.overrideWithValue(
        configured
            ? InviteConfig(api: 'https://invite.test', publicKey: _publicKey)
            : null,
      ),
      inviteClientProvider.overrideWithValue(client),
      inviteBootProvider.overrideWithValue(
        InviteBoot(device: _device, token: token),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(mockPreferences);

  group('a token', () {
    test('reads back what the server signed', () {
      final claims = readInviteToken(_live, _publicKey)!;
      expect(claims.code, 'ABCDEFGH');
      expect(claims.device, _device);
      expect(claims.expiresAt.year, 2100);
    });

    test('is refused once a byte of it changes or under another key', () {
      final [payload, signature] = _live.split('.');
      final flipped = signature.startsWith('A') ? 'B' : 'A';
      expect(
        readInviteToken(
          '$payload.$flipped${signature.substring(1)}',
          _publicKey,
        ),
        isNull,
      );
      expect(readInviteToken(_live, List.filled(32, 1)), isNull);
      expect(readInviteToken('not a token', _publicKey), isNull);
      expect(readInviteToken('a.b.c', _publicKey), isNull);
    });
  });

  group('access', () {
    test('is open in a build without an invitation server', () {
      final client = _FakeClient();
      final container = _container(client, configured: false);
      expect(container.read(inviteProvider).granted, isTrue);
      expect(client.refreshed, isEmpty);
    });

    test('is locked without a token', () {
      final container = _container(_FakeClient());
      expect(container.read(inviteProvider).granted, isFalse);
    });

    test('opens on a live token for this device and renews it', () async {
      final client = _FakeClient();
      final container = _container(client, token: _live);
      expect(container.read(inviteProvider).granted, isTrue);
      await _settle();
      expect(client.refreshed, [_live]);
    });

    test('stays locked on a token for another device', () {
      final container = _container(_FakeClient(), token: _otherDevice);
      expect(container.read(inviteProvider).granted, isFalse);
    });

    test('stays open offline but locks once the code is withdrawn', () async {
      final client = _FakeClient()
        ..refreshReply = (token: null, refusal: InviteRefusal.network);
      final offline = _container(client, token: _live);
      offline.read(inviteProvider);
      await _settle();
      expect(offline.read(inviteProvider).granted, isTrue);

      client.refreshReply = (token: null, refusal: InviteRefusal.revoked);
      await preferences.saveInviteToken(_live);
      final revoked = _container(client, token: _live);
      revoked.read(inviteProvider);
      await _settle();
      await _settle();
      expect(revoked.read(inviteProvider).granted, isFalse);
      expect(revoked.read(inviteProvider).refusal, InviteRefusal.revoked);
      expect(await preferences.getInviteToken(), isNull);
    });

    test('an expired token opens again once it is renewed', () async {
      final client = _FakeClient();
      final container = _container(client, token: _expired);
      expect(container.read(inviteProvider).granted, isFalse);
      await _settle();
      await _settle();
      expect(container.read(inviteProvider).granted, isTrue);
      expect(await preferences.getInviteToken(), _live);
    });

    test('a redeemed code opens it and keeps the token', () async {
      final client = _FakeClient();
      final container = _container(client);
      await container.read(inviteProvider.notifier).redeem('abcd-efgh');
      expect(client.redeemed, [('abcd-efgh', _device)]);
      expect(container.read(inviteProvider).granted, isTrue);
      expect(await preferences.getInviteToken(), _live);
    });

    test('a refused code says why and a token for another device is not '
        'taken', () async {
      final client = _FakeClient()
        ..redeemReply = (token: null, refusal: InviteRefusal.exhausted);
      final container = _container(client);
      await container.read(inviteProvider.notifier).redeem('ABCD-EFGH');
      expect(container.read(inviteProvider).refusal, InviteRefusal.exhausted);

      client.redeemReply = (token: _otherDevice, refusal: null);
      await container.read(inviteProvider.notifier).redeem('ABCD-EFGH');
      expect(container.read(inviteProvider).granted, isFalse);
      expect(container.read(inviteProvider).refusal, InviteRefusal.invalid);
    });
  });

  testWidgets('the gate asks for a code and lets the app in once it is '
      'accepted', (tester) async {
    final client = _FakeClient();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(client),
        child: const TestApp(
          locale: Locale('en'),
          child: InviteGate(child: Text('home')),
        ),
      ),
    );
    expect(find.text('Invitation code'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    client.redeemReply = (token: null, refusal: InviteRefusal.invalid);
    await tester.enterText(find.byType(EditableText), 'nope-nope');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not exist'), findsOneWidget);

    client.redeemReply = (token: _live, refusal: null);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
