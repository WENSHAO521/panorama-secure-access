import 'dart:async';

import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LockManager extends ConsumerStatefulWidget {
  final Widget child;

  const LockManager({super.key, required this.child});

  @override
  ConsumerState<LockManager> createState() => _LockManagerState();
}

class _LockManagerState extends ConsumerState<LockManager>
    with WidgetsBindingObserver {
  bool _locked = false;
  DateTime? _backgroundedAt;
  Timer? _autoLockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tryLockOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLockTimer?.cancel();
    super.dispose();
  }

  bool get _lockEnabled =>
      ref.read(appSettingProvider).appLockEnabled &&
      ref.read(appSettingProvider).appLockPin != null;

  int get _autoLockMinutes => ref.read(appSettingProvider).autoLockMinutes;

  void _tryLockOnStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lockEnabled && mounted) {
        setState(() => _locked = true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_lockEnabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
      if (_autoLockMinutes == 0) {
        _autoLockTimer?.cancel();
        _autoLockTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _locked = true);
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundedAt != null && _autoLockMinutes > 0) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        if (elapsed.inMinutes >= _autoLockMinutes) {
          if (mounted) setState(() => _locked = true);
        }
      }
      _backgroundedAt = null;
    }
  }

  void _unlock() {
    setState(() => _locked = false);
    _autoLockTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      appSettingProvider.select((s) => s.appLockEnabled && s.appLockPin != null),
      (_, enabled) {
        if (!enabled && _locked) setState(() => _locked = false);
      },
    );

    if (_locked) {
      return LockScreen(onUnlocked: _unlock);
    }
    return widget.child;
  }
}
