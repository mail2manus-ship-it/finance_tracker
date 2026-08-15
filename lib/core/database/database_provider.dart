import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/settings_model.dart';
import '../constants/app_constants.dart';

/// Opens (or returns the already-open) Isar instance.
///
/// This is called once from `main()` before `runApp`, and the resulting
/// instance is injected into the widget tree via [isarProvider] as an
/// override -- see main.dart. Repositories read `ref.watch(isarProvider)`
/// rather than opening the database themselves, keeping data access
/// testable and decoupled from I/O setup.
Future<Isar> openAppDatabase() async {
  if (Isar.instanceNames.isNotEmpty) {
    return Isar.getInstance()!;
  }
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [ExpenseModelSchema, IncomeModelSchema, SettingsModelSchema],
    directory: dir.path,
    name: AppConstants.dbName,
  );
}

/// Placeholder provider; overridden with the real instance in main.dart
/// after `openAppDatabase()` resolves. Throwing by default makes it obvious
/// if a widget tries to read the database before app startup finishes.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'isarProvider was not overridden. Ensure main.dart awaits '
    'openAppDatabase() and provides it via ProviderScope overrides.',
  );
});
