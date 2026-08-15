import 'package:isar/isar.dart';

part 'expense_model.g.dart';

/// Persisted representation of a single expense transaction.
///
/// NOTE: after editing this file, run:
///   flutter pub run build_runner build --delete-conflicting-outputs
/// to regenerate `expense_model.g.dart` (Isar's generated adapter).
@collection
class ExpenseModel {
  Id id = Isar.autoIncrement;

  /// Stored as UTC midnight for the calendar date this expense belongs to.
  /// Time-of-day is kept separately so date-only queries (daily/monthly
  /// summaries) stay simple and index-friendly.
  @Index()
  late DateTime date;

  /// Free-form "HH:mm" string is avoided in favor of a full DateTime so we
  /// can sort by exact time; `date` remains the source of truth for grouping.
  /// Indexed: every repository query (getAll, getByDateRange, watch*) sorts
  /// or filters on this field, not `date`.
  @Index()
  late DateTime dateTime;

  @Index()
  late String category;

  /// Only populated when [category] == 'Others'.
  String? customCategory;

  late double amount;

  late String paymentMethod;

  String? notes;

  /// Local file path to an optional receipt photo.
  String? imagePath;

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Soft-delete flag to support "Undo Delete" without immediately
  /// destroying the row. A background sweep (or app start) can purge
  /// rows older than e.g. 10 seconds once the undo window has passed.
  /// Indexed: every repository query filters on this field first.
  @Index()
  bool isDeleted = false;

  /// Effective category label for display: custom text when "Others"
  /// was chosen and filled in, otherwise the predefined category.
  String get displayCategory =>
      category == 'Others' && (customCategory?.isNotEmpty ?? false)
          ? customCategory!
          : category;
}
