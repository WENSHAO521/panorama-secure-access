import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rust_api/rust_api.dart' show verifyInviteSignature;

const _inviteApi = String.fromEnvironment('INVITE_API');
const _invitePublicKey = String.fromEnvironment('INVITE_PUBLIC_KEY');

/// Where codes are checked and the key their tokens are signed with. A build
/// without both, a fork or a safe mode build, never asks for a code.
class InviteConfig {
  const InviteConfig({required this.api, required this.publicKey});

  final String api;
  final List<int> publicKey;

  static InviteConfig? fromEnvironment() {
    if (_inviteApi.isEmpty || _invitePublicKey.isEmpty || safeModeBuild) {
      return null;
    }
    return InviteConfig(
      api: _inviteApi,
      publicKey: base64.decode(_invitePublicKey),
    );
  }
}

/// Why the server turned a code or token down, or [network] when it could
/// not be asked.
enum InviteRefusal { invalid, revoked, expired, exhausted, unbound, network }

class InviteClaims {
  const InviteClaims({
    required this.code,
    required this.device,
    required this.expiresAt,
  });

  final String code;
  final String device;
  final DateTime expiresAt;
}

/// The claims of a token the invitation server signed, expired or not.
InviteClaims? readInviteToken(String token, List<int> publicKey) {
  final parts = token.split('.');
  if (parts.length != 2) return null;
  try {
    final [payload, signature] = parts;
    final signed = verifyInviteSignature(
      publicKey: publicKey,
      message: utf8.encode(payload),
      signature: base64Url.decode(base64Url.normalize(signature)),
    );
    if (!signed) return null;
    final claims = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(payload))),
    );
    if (claims case {
      'v': 1,
      'c': final String code,
      'd': final String device,
      'exp': final int exp,
    }) {
      return InviteClaims(
        code: code,
        device: device,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      );
    }
  } on FormatException {
    return null;
  }
  return null;
}

typedef InviteReply = ({String? token, InviteRefusal? refusal});

abstract interface class InviteClient {
  Future<InviteReply> redeem(String code, String device);

  Future<InviteReply> refresh(String token);
}

class HttpInviteClient implements InviteClient {
  HttpInviteClient(String api)
    : _dio = Dio(
        BaseOptions(
          baseUrl: api,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (_) => true,
        ),
      );

  final Dio _dio;

  @override
  Future<InviteReply> redeem(String code, String device) =>
      _post('/v1/redeem', {'code': code, 'device': device});

  @override
  Future<InviteReply> refresh(String token) =>
      _post('/v1/refresh', {'token': token});

  Future<InviteReply> _post(String path, Map<String, String> body) async {
    try {
      final response = await _dio.post<Object?>(path, data: body);
      return switch (response.data) {
        {'token': final String token} when response.statusCode == 200 => (
          token: token,
          refusal: null,
        ),
        {'error': final String error} when response.statusCode! < 500 => (
          token: null,
          refusal:
              InviteRefusal.values.asNameMap()[error] ?? InviteRefusal.invalid,
        ),
        _ => (token: null, refusal: InviteRefusal.network),
      };
    } on DioException {
      return (token: null, refusal: InviteRefusal.network);
    }
  }
}

/// What the app read at launch, so the gate decides before the first frame.
class InviteBoot {
  const InviteBoot({required this.device, this.token});

  final String device;
  final String? token;

  static InviteBoot current = const InviteBoot(device: '');

  static Future<void> load() async {
    if (InviteConfig.fromEnvironment() == null) return;
    current = InviteBoot(
      device: await preferences.getInviteDevice(),
      token: await preferences.getInviteToken(),
    );
  }
}

@immutable
class InviteState {
  const InviteState({
    required this.granted,
    required this.device,
    this.busy = false,
    this.refusal,
  });

  final bool granted;
  final String device;
  final bool busy;
  final InviteRefusal? refusal;
}

final inviteConfigProvider = Provider<InviteConfig?>(
  (_) => InviteConfig.fromEnvironment(),
);

final inviteClientProvider = Provider<InviteClient>(
  (ref) => HttpInviteClient(ref.watch(inviteConfigProvider)?.api ?? ''),
);

final inviteBootProvider = Provider<InviteBoot>((_) => InviteBoot.current);

final inviteProvider = NotifierProvider<InviteAccess, InviteState>(
  InviteAccess.new,
);

/// Admits the app once this install holds a token for a code, and checks it
/// again at each launch: a code that is revoked or no longer holds this
/// device locks it again, while being offline never does until it expires.
class InviteAccess extends Notifier<InviteState> {
  String? _token;

  @override
  InviteState build() {
    final config = ref.watch(inviteConfigProvider);
    if (config == null) return const InviteState(granted: true, device: '');
    final boot = ref.watch(inviteBootProvider);
    final token = boot.token;
    final claims = token == null
        ? null
        : readInviteToken(token, config.publicKey);
    if (claims == null || claims.device != boot.device) {
      return InviteState(granted: false, device: boot.device);
    }
    _token = token;
    final live = claims.expiresAt.isAfter(DateTime.now());
    Future.microtask(_refresh);
    return InviteState(granted: live, device: boot.device, busy: !live);
  }

  Future<void> _refresh() async {
    final token = _token;
    if (token == null) return;
    final reply = await ref.read(inviteClientProvider).refresh(token);
    if (!ref.mounted) return;
    switch (reply) {
      case (token: final String token, refusal: _):
        await _admit(token);
      case (token: _, refusal: InviteRefusal.network):
        state = InviteState(
          granted: state.granted,
          device: state.device,
          refusal: state.granted ? null : InviteRefusal.network,
        );
      case (token: _, refusal: final refusal):
        _token = null;
        await preferences.saveInviteToken(null);
        state = InviteState(
          granted: false,
          device: state.device,
          refusal: refusal,
        );
    }
  }

  Future<void> redeem(String code) async {
    if (state.busy) return;
    state = InviteState(granted: false, device: state.device, busy: true);
    final reply = await ref
        .read(inviteClientProvider)
        .redeem(code, state.device);
    if (!ref.mounted) return;
    if (reply.token case final token? when await _admit(token)) return;
    state = InviteState(
      granted: false,
      device: state.device,
      refusal: reply.refusal ?? InviteRefusal.invalid,
    );
  }

  Future<bool> _admit(String token) async {
    final config = ref.read(inviteConfigProvider)!;
    final claims = readInviteToken(token, config.publicKey);
    if (claims == null || claims.device != state.device) return false;
    _token = token;
    await preferences.saveInviteToken(token);
    if (ref.mounted) {
      state = InviteState(granted: true, device: state.device);
    }
    return true;
  }
}
