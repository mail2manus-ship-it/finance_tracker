import 'package:isar/isar.dart';

part 'settings_model.g.dart';

/// App-wide settings, stored as a single row (id is always fixed at 0).
/// Kept in Isar (rather than SharedPreferences) so it's part of the same
/// backup/restore flow as the rest of the user's data.
@collection
class SettingsModel {
  Id id = 0;

  String currencySymbol = '₹';
  String currencyCode = 'INR';

  /// 'system' | 'light' | 'dark'
  String themeMode = 'system';

  /// Minutes since midnight for the daily reminder, e.g. 21 * 60 for 9 PM.
  int reminderMinutesOfDay = 21 * 60;
  bool reminderEnabled = true;

  bool pinEnabled = false;
  bool biometricEnabled = false;

  /// PIN itself is NEVER stored here — it lives in flutter_secure_storage.
  /// This model only tracks whether the feature is turned on.
}
