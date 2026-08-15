import 'package:isar/isar.dart';

import '../models/settings_model.dart';

/// Reads/writes the single-row [SettingsModel]. Kept small and direct
/// (no abstract interface) since, unlike Expense/Income, there's only
/// ever one implementation and one row -- an interface would add
/// indirection without a real benefit here.
class SettingsRepository {
  final Isar _isar;
  SettingsRepository(this._isar);

  Future<SettingsModel> getOrCreate() async {
    final existing = await _isar.settingsModels.get(0);
    if (existing != null) return existing;
    final fresh = SettingsModel();
    await _isar.writeTxn(() => _isar.settingsModels.put(fresh));
    return fresh;
  }

  Future<void> save(SettingsModel settings) {
    return _isar.writeTxn(() => _isar.settingsModels.put(settings));
  }

  Stream<SettingsModel?> watch() {
    return _isar.settingsModels.watchObject(0, fireImmediately: true);
  }
}
