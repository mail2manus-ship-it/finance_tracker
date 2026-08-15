import '../../data/models/expense_model.dart';

/// Abstract contract the UI/providers depend on. The concrete
/// `IsarExpenseRepository` (Phase 2) implements this against Isar, so
/// swapping storage engines later never touches presentation code --
/// this is the Repository Pattern half of the architecture requirement.
abstract class ExpenseRepository {
  Future<int> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(int id); // soft delete, supports Undo
  Future<void> restoreExpense(int id); // undoes the soft delete
  Future<void> purgeDeletedOlderThan(Duration age);

  Future<ExpenseModel?> getById(int id);
  Future<List<ExpenseModel>> getAll();
  Future<List<ExpenseModel>> getByDateRange(DateTime start, DateTime end);
  Future<List<ExpenseModel>> search(String query);

  Stream<List<ExpenseModel>> watchAll();
  Stream<List<ExpenseModel>> watchByDateRange(DateTime start, DateTime end);
}
