import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';

String hashPin(String pin) =>
    sha256.convert(utf8.encode(pin)).toString();

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _input = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_input.length >= 6) return;
    setState(() => _input += digit);
    if (_input.length >= 4) {
      _submit();
    }
  }

  void _deleteLast() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _submit() async {
    final storedHash = globalState.container
        .read(appSettingProvider)
        .appLockPin;
    if (storedHash == null) {
      widget.onUnlocked();
      return;
    }
    if (hashPin(_input) == storedHash) {
      widget.onUnlocked();
    } else {
      await _shakeController.forward(from: 0);
      setState(() {
        _input = '';
      });
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < _input.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onTap, Widget? child}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: child ??
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
        ),
      ),
    );
  }

  Widget _buildPad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Row(
            children: row.map((k) {
              if (k == 'del') {
                return _buildKey(
                  '',
                  onTap: _deleteLast,
                  child: const Icon(Icons.backspace_outlined, size: 22),
                );
              }
              if (k.isEmpty) return _buildKey('', onTap: null, child: const SizedBox());
              return _buildKey(k, onTap: () => _appendDigit(k));
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Image.asset('assets/images/icon.png', width: 72, height: 72),
                const SizedBox(height: 24),
                Text(
                  appLocalizations.enterCurrentPIN,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  ),
                  child: _buildDots(),
                ),
                const SizedBox(height: 40),
                _buildPad(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PIN setup dialog ──────────────────────────────────────────────────────────

enum _PinStep { enterNew, confirm, enterCurrent }

class PinSetupDialog extends StatefulWidget {
  final bool hasExistingPin;

  const PinSetupDialog({super.key, required this.hasExistingPin});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  _PinStep _step = _PinStep.enterNew;
  String _firstPin = '';
  String _currentInput = '';
  String? _error;

  void _appendDigit(String d) {
    if (_currentInput.length >= 6) return;
    setState(() {
      _currentInput += d;
      _error = null;
    });
  }

  void _delete() {
    if (_currentInput.isEmpty) return;
    setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  void _submit() {
    final loc = context.appLocalizations;
    if (_currentInput.length < 4) {
      setState(() => _error = loc.pinTooShort);
      return;
    }
    if (widget.hasExistingPin && _step == _PinStep.enterNew) {
      _step = _PinStep.enterCurrent;
      _firstPin = _currentInput;
      setState(() => _currentInput = '');
      return;
    }
    if (_step == _PinStep.enterCurrent) {
      final stored = globalState.container.read(appSettingProvider).appLockPin;
      if (stored != null && hashPin(_currentInput) != stored) {
        setState(() {
          _error = loc.pinIncorrect;
          _currentInput = '';
        });
        return;
      }
      _step = _PinStep.confirm;
      setState(() => _currentInput = '');
      return;
    }
    if (_step == _PinStep.confirm) {
      if (_currentInput != _firstPin) {
        setState(() {
          _error = loc.pinMismatch;
          _currentInput = '';
          _step = _PinStep.enterNew;
          _firstPin = '';
        });
        return;
      }
      Navigator.of(context).pop(hashPin(_firstPin));
      return;
    }
    // enterNew (no existing pin)
    _firstPin = _currentInput;
    _step = _PinStep.confirm;
    setState(() => _currentInput = '');
  }

  String _title(AppLocalizations loc) {
    return switch (_step) {
      _PinStep.enterNew => loc.enterNewPIN,
      _PinStep.confirm => loc.confirmPIN,
      _PinStep.enterCurrent => loc.enterCurrentPIN,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.appLocalizations;
    return AlertDialog(
      title: Text(widget.hasExistingPin ? loc.changePIN : loc.setPIN),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_title(loc)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = i < _currentInput.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              );
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          _buildPad(context),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: _currentInput.length >= 4 ? _submit : null,
          child: Text(loc.confirm),
        ),
      ],
    );
  }

  Widget _buildPad(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((k) {
              if (k == 'del') {
                return SizedBox(
                  width: 72,
                  height: 44,
                  child: TextButton(
                    onPressed: _delete,
                    child: const Icon(Icons.backspace_outlined, size: 18),
                  ),
                );
              }
              if (k.isEmpty) return const SizedBox(width: 72, height: 44);
              return SizedBox(
                width: 72,
                height: 44,
                child: TextButton(
                  onPressed: () => _appendDigit(k),
                  child: Text(k, style: Theme.of(context).textTheme.titleLarge),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
