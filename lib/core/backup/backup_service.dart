import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/settings_model.dart';

/// Serializes every expense, income, and settings row to a single JSON
/// file for local backup, and can restore from that same format. This is
/// the "Local Backup / Local Restore" feature from the spec; Google
/// Drive / Cloud Backup are explicitly future features, so this stays
/// file-based and local, shared out via the OS share sheet (same
/// mechanism as report export in Phase 4).
class BackupService {
  final Isar _isar;
  BackupService(this._isar);

  Future<File> createBackup() async {
    final expenses = await _isar.expenseModels.where().findAll();
    final incomes = await _isar.incomeModels.where().findAll();
    final settings = await _isar.settingsModels.get(0);

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'expenses': expenses.map(_expenseToJson).toList(),
      'incomes': incomes.map(_incomeToJson).toList(),
      'settings': settings == null ? null : _settingsToJson(settings),
    };

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/finance_tracker_backup_$timestamp.json');
    return file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<void> shareBackup(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'My Personal Finance Tracker — backup'),
    );
  }

  /// Lets the user pick a previously-exported .json file, then restores
  /// it. [merge] = false wipes existing expenses/income first (a clean
  /// restore); [merge] = true adds the backup's rows alongside what's
  /// already there.
  Future<RestoreResult> pickAndRestore({required bool merge}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) {
      return const RestoreResult(success: false, message: 'No file selected.');
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const RestoreResult(success: false, message: 'That file isn\'t a valid backup.');
    }

    if (payload['version'] != 1) {
      return const RestoreResult(success: false, message: 'Unsupported backup version.');
    }

    final expensesJson = (payload['expenses'] as List?) ?? [];
    final incomesJson = (payload['incomes'] as List?) ?? [];
    final settingsJson = payload['settings'] as Map<String, dynamic>?;

    await _isar.writeTxn(() async {
      if (!merge) {
        await _isar.expenseModels.clear();
        await _isar.incomeModels.clear();
      }
      for (final e in expensesJson) {
        await _isar.expenseModels.put(_expenseFromJson(e as Map<String, dynamic>, keepId: !merge));
      }
      for (final i in incomesJson) {
        await _isar.incomeModels.put(_incomeFromJson(i as Map<String, dynamic>, keepId: !merge));
      }
      if (settingsJson != null) {
        await _isar.settingsModels.put(_settingsFromJson(settingsJson));
      }
    });

    return RestoreResult(
      success: true,
      message: 'Restored ${expensesJson.length} expenses and ${incomesJson.length} income entries.',
    );
  }

  // -- Serialization helpers --------------------------------------------

  Map<String, dynamic> _expenseToJson(ExpenseModel e) => {
        'id': e.id,
        'date': e.date.toIso8601String(),
        'dateTime': e.dateTime.toIso8601String(),
        'category': e.category,
        'customCategory': e.customCategory,
        'amount': e.amount,
        'paymentMethod': e.paymentMethod,
        'notes': e.notes,
        'imagePath': e.imagePath,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
        'isDeleted': e.isDeleted,
      };

  ExpenseModel _expenseFromJson(Map<String, dynamic> j, {required bool keepId}) {
    final model = ExpenseModel()
      ..date = DateTime.parse(j['date'] as String)
      ..dateTime = DateTime.parse(j['dateTime'] as String)
      ..category = j['category'] as String
      ..customCategory = j['customCategory'] as String?
      ..amount = (j['amount'] as num).toDouble()
      ..paymentMethod = j['paymentMethod'] as String
      ..notes = j['notes'] as String?
      ..imagePath = j['imagePath'] as String?
      ..createdAt = DateTime.parse(j['createdAt'] as String)
      ..updatedAt = DateTime.parse(j['updatedAt'] as String)
      ..isDeleted = j['isDeleted'] as bool? ?? false;
    if (keepId) model.id = j['id'] as int;
    return model;
  }

  Map<String, dynamic> _incomeToJson(IncomeModel i) => {
        'id': i.id,
        'date': i.date.toIso8601String(),
        'dateTime': i.dateTime.toIso8601String(),
        'source': i.source,
        'amount': i.amount,
        'notes': i.notes,
        'createdAt': i.createdAt.toIso8601String(),
        'updatedAt': i.updatedAt.toIso8601String(),
        'isDeleted': i.isDeleted,
      };

  IncomeModel _incomeFromJson(Map<String, dynamic> j, {required bool keepId}) {
    final model = IncomeModel()
      ..date = DateTime.parse(j['date'] as String)
      ..dateTime = DateTime.parse(j['dateTime'] as String)
      ..source = j['source'] as String
      ..amount = (j['amount'] as num).toDouble()
      ..notes = j['notes'] as String?
      ..createdAt = DateTime.parse(j['createdAt'] as String)
      ..updatedAt = DateTime.parse(j['updatedAt'] as String)
      ..isDeleted = j['isDeleted'] as bool? ?? false;
    if (keepId) model.id = j['id'] as int;
    return model;
  }

  Map<String, dynamic> _settingsToJson(SettingsModel s) => {
        'currencySymbol': s.currencySymbol,
        'currencyCode': s.currencyCode,
        'themeMode': s.themeMode,
        'reminderMinutesOfDay': s.reminderMinutesOfDay,
        'reminderEnabled': s.reminderEnabled,
        // pinEnabled/biometricEnabled and the PIN itself are deliberately
        // NOT included -- restoring a backup on a new device shouldn't
        // silently carry over a lock credential tied to secure storage
        // that won't exist there.
      };

  SettingsModel _settingsFromJson(Map<String, dynamic> j) {
    return SettingsModel()
      ..id = 0
      ..currencySymbol = j['currencySymbol'] as String? ?? '₹'
      ..currencyCode = j['currencyCode'] as String? ?? 'INR'
      ..themeMode = j['themeMode'] as String? ?? 'system'
      ..reminderMinutesOfDay = j['reminderMinutesOfDay'] as int? ?? 21 * 60
      ..reminderEnabled = j['reminderEnabled'] as bool? ?? true;
  }
}

class RestoreResult {
  final bool success;
  final String message;
  const RestoreResult({required this.success, required this.message});
}
