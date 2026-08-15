/// A flattened, export-ready representation of a single transaction.
/// Built from either an `ExpenseModel` or `IncomeModel` so the export
/// code (CSV/Excel/PDF) never needs to know about Isar collections.
class ExportRow {
  final DateTime dateTime;
  final String type; // 'Income' | 'Expense'
  final String category; // category or source
  final double amount;
  final String paymentMethodOrSource;
  final String notes;

  const ExportRow({
    required this.dateTime,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMethodOrSource,
    required this.notes,
  });
}
