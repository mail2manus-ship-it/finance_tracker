import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/settings_providers.dart';

enum PinScreenMode { create, confirm, unlock, change }

/// Single reusable screen for creating, confirming, changing, or
/// verifying the PIN. `mode` controls copy and what happens on success;
/// `onSuccess` lets the caller (Settings, or the app-lock gate) decide
/// what "done" means in each context.
class PinScreen extends ConsumerStatefulWidget {
  final PinScreenMode mode;
  final String? pinToConfirm; // used when mode == confirm
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const PinScreen({
    super.key,
    required this.mode,
    required this.onSuccess,
    this.pinToConfirm,
    this.onCancel,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _entered = '';
  String? _error;
  bool _checking = false;

  static const _pinLength = 4;

  String get _title {
    switch (widget.mode) {
      case PinScreenMode.create:
      case PinScreenMode.change:
        return 'Create a PIN';
      case PinScreenMode.confirm:
        return 'Confirm your PIN';
      case PinScreenMode.unlock:
        return 'Enter your PIN';
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= _pinLength || _checking) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == _pinLength) {
      await _submit();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _checking = true);

    if (widget.mode == PinScreenMode.unlock) {
      final ok = await ref.read(pinServiceProvider).verifyPin(_entered);
      if (!mounted) return;
      if (ok) {
        widget.onSuccess();
      } else {
        setState(() {
          _error = 'Incorrect PIN. Try again.';
          _entered = '';
          _checking = false;
        });
        HapticFeedback.heavyImpact();
      }
      return;
    }

    if (widget.mode == PinScreenMode.confirm) {
      if (_entered == widget.pinToConfirm) {
        await ref.read(pinServiceProvider).setPin(_entered);
        await ref.read(settingsControllerProvider).update((s) => s..pinEnabled = true);
        if (!mounted) return;
        widget.onSuccess();
      } else {
        setState(() {
          _error = "PINs didn't match. Try again.";
          _entered = '';
          _checking = false;
        });
        HapticFeedback.heavyImpact();
      }
      return;
    }

    // create / change: hand off to a confirm step with what was just typed.
    if (!mounted) return;
    final justEntered = _entered;
    setState(() {
      _checking = false;
      _entered = '';
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinScreen(
          mode: PinScreenMode.confirm,
          pinToConfirm: justEntered,
          onSuccess: () {
            Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/settings');
            widget.onSuccess();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              if (widget.onCancel != null)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
                ),
              const Spacer(),
              Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: AppColors.primary, width: 1.6),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: _error != null
                    ? Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))
                    : null,
              ),
              const Spacer(),
              _NumberPad(onDigit: _onDigit, onBackspace: _onBackspace),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  const _NumberPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: AspectRatio(
          aspectRatio: 1.4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap ?? (label.isEmpty ? null : () => onDigit(label)),
            child: Center(
              child: child ??
                  Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [key('1'), key('2'), key('3')]),
        Row(children: [key('4'), key('5'), key('6')]),
        Row(children: [key('7'), key('8'), key('9')]),
        Row(children: [
          key(''),
          key('0'),
          key('', onTap: onBackspace, child: const Icon(Icons.backspace_outlined, size: 20)),
        ]),
      ],
    );
  }
}
