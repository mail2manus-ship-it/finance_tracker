import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import 'pin_screen.dart';

/// Wraps the app's home content. When `SettingsModel.pinEnabled` is on,
/// shows the PIN/biometric unlock screen on cold start and again every
/// time the app returns from the background -- a common expectation for
/// a finance app holding sensitive data.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Arm the lock on cold start; the settings stream (below) decides
    // whether it actually needs to show anything.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(appLockProvider.notifier).lock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _biometricAttempted = false;
    }
    if (state == AppLifecycleState.resumed) {
      final settings = ref.read(settingsStreamProvider).value;
      if (settings?.pinEnabled == true) {
        ref.read(appLockProvider.notifier).lock();
      }
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricAttempted) return;
    _biometricAttempted = true;
    final settings = ref.read(settingsStreamProvider).value;
    if (settings?.biometricEnabled != true) return;
    final available = await ref.read(biometricServiceProvider).isAvailable();
    if (!available) return;
    final ok = await ref.read(biometricServiceProvider).authenticate();
    if (ok && mounted) {
      ref.read(appLockProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final isLocked = ref.watch(appLockProvider);

    final settings = settingsAsync.value;
    final pinEnabled = settings?.pinEnabled ?? false;

    if (!pinEnabled || !isLocked) {
      return widget.child;
    }

    // Fire-and-forget biometric attempt whenever the lock screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());

    return PinScreen(
      mode: PinScreenMode.unlock,
      onSuccess: () => ref.read(appLockProvider.notifier).unlock(),
    );
  }
}
