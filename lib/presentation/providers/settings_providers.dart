import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backup/backup_service.dart';
import '../../core/database/database_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(isarProvider));
});

final pinServiceProvider = Provider<PinService>((ref) => PinService());
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(isarProvider)));

/// Live settings row. `.value` is null only for the single frame before
/// the initial read completes; `getOrCreate()` guarantees a row exists.
final settingsStreamProvider = StreamProvider<SettingsModel?>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// Convenience notifier for updating individual settings fields without
/// every screen re-reading/re-writing the whole model by hand.
class SettingsController {
  final SettingsRepository _repo;
  SettingsController(this._repo);

  Future<void> update(SettingsModel Function(SettingsModel current) mutate) async {
    final current = await _repo.getOrCreate();
    await _repo.save(mutate(current));
  }
}

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

/// Whether the app is currently locked (PIN/biometric screen should show).
/// True at cold start whenever `pinEnabled` is on; set to false once the
/// user successfully authenticates for this session. Re-armed on resume
/// by the WidgetsBindingObserver in `app_lock_gate.dart`.
class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false);

  void lock() => state = true;
  void unlock() => state = false;
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) => AppLockNotifier());
