import 'package:isar/isar.dart';

part 'income_model.g.dart';

/// Persisted representation of a single income transaction.
/// See `expense_model.dart` for the build_runner note.
@collection
class IncomeModel {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  /// Indexed: repository queries sort/filter on this field, not `date`.
  @Index()
  late DateTime dateTime;

  @Index()
  late String source;

  late double amount;

  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Indexed: every repository query filters on this field first.
  @Index()
  bool isDeleted = false;
}
