import 'package:fl_clash/core/desktop/lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/rust_native.dart';

const _dart = DartLifecyclePolicy();
const _rust = RustLifecyclePolicy();
const _bools = [false, true];

void main() {
  setUpAll(initRustNative);

  test('Rust and Dart decide alike on every input', () {
    for (final target in LifecycleTarget.values) {
      for (final achievement in LifecycleAchievement.values) {
        expect(
          _rust.satisfies(achievement, target),
          _dart.satisfies(achievement, target),
          reason: '$achievement $target',
        );
      }
      for (final settled in LifecycleTarget.values) {
        for (final revision in [1, 2, 3]) {
          expect(
            _rust.commandOutcome(revision, target, 2, settled),
            _dart.commandOutcome(revision, target, 2, settled),
            reason: '$revision $target 2 $settled',
          );
        }
      }
      for (final hasSession in _bools) {
        for (final sessionRunning in _bools) {
          for (final terminalRequested in _bools) {
            expect(
              _rust.planReconcile(
                target,
                hasSession: hasSession,
                sessionRunning: sessionRunning,
                terminalRequested: terminalRequested,
              ),
              _dart.planReconcile(
                target,
                hasSession: hasSession,
                sessionRunning: sessionRunning,
                terminalRequested: terminalRequested,
              ),
              reason: '$target $hasSession $sessionRunning $terminalRequested',
            );
          }
        }
      }
      expect(
        _rust.unconfirmedLeaseMayFail(target),
        _dart.unconfirmedLeaseMayFail(target),
      );
    }
    for (final phase in TransportPhase.values) {
      expect(_rust.transportUsable(phase), _dart.transportUsable(phase));
      for (final hasSession in _bools) {
        expect(
          _rust.transportNeedsReplacement(phase, hasSession: hasSession),
          _dart.transportNeedsReplacement(phase, hasSession: hasSession),
          reason: '$phase $hasSession',
        );
      }
    }
    for (final event in TransportEventKind.values) {
      for (final sessionRunning in _bools) {
        for (final sameGeneration in _bools) {
          expect(
            _rust.disconnectReaction(
              event,
              sessionRunning: sessionRunning,
              sameGeneration: sameGeneration,
            ),
            _dart.disconnectReaction(
              event,
              sessionRunning: sessionRunning,
              sameGeneration: sameGeneration,
            ),
            reason: '$event $sessionRunning $sameGeneration',
          );
        }
      }
    }
  });

  test('the bridged enums keep the names the app maps onto them', () {
    expect(TransportPhase.values.map((phase) => phase.name), [
      'idle',
      'starting',
      'ready',
      'connected',
      'failed',
      'closed',
    ]);
  });
}
