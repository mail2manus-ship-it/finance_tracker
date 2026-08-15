import 'package:isar/isar.dart';

import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

/// Isar implementation of [ExpenseRepository]. This is the only class in
/// the app that talks to Isar for expenses -- providers and UI never
/// import `package:isar/isar.dart` directly, which is what lets the
/// storage engine be swapped later without touching presentation code.
class IsarExpenseRepository implements ExpenseRepository {
  final Isar _isar;

  IsarExpenseRepository(this._isar);

  @override
  Future<int> addExpense(ExpenseModel expense) {
    final now = DateTime.now();
    expense.createdAt = now;
    expense.updatedAt = now;
    return _isar.writeTxn(() => _isar.expenseModels.put(expense));
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) {
    expense.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.expenseModels.put(expense));
  }

  @override
  Future<void> deleteExpense(int id) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.expenseModels.get(id);
      if (expense == null) return;
      expense.isDeleted = true;
      expense.updatedAt = DateTime.now();
      await _isar.expenseModels.put(expense);
    });
  }

  @override
  Future<void> restoreExpense(int id) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.expenseModels.get(id);
      if (expense == null) return;
      expense.isDeleted = false;
      expense.updatedAt = DateTime.now();
      await _isar.expenseModels.put(expense);
    });
  }

  @override
  Future<void> purgeDeletedOlderThan(Duration age) async {
    final cutoff = DateTime.now().subtract(age);
    await _isar.writeTxn(() async {
      final stale = await _isar.expenseModels
          .filter()
          .isDeletedEqualTo(true)
          .updatedAtLessThan(cutoff)
          .findAll();
      await _isar.expenseModels.deleteAll(stale.map((e) => e.id).toList());
    });
  }

  @override
  Future<ExpenseModel?> getById(int id) => _isar.expenseModels.get(id);

  @override
  Future<List<ExpenseModel>> getAll() {
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateTimeDesc()
        .findAll();
  }

  @override
  Future<List<ExpenseModel>> getByDateRange(DateTime start, DateTime end) {
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .dateTimeBetween(start, end)
        .sortByDateTimeDesc()
        .findAll();
  }

  @override
  Future<List<ExpenseModel>> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return getAll();
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .group((r) => r
            .categoryContains(q, caseSensitive: false)
            .or()
            .customCategoryContains(q, caseSensitive: false)
            .or()
            .notesContains(q, caseSensitive: false))
        .sortByDateTimeDesc()
        .findAll();
  }

  @override
  Stream<List<ExpenseModel>> watchAll() {
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateTimeDesc()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<ExpenseModel>> watchByDateRange(DateTime start, DateTime end) {
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .dateTimeBetween(start, end)
        .sortByDateTimeDesc()
        .watch(fireImmediately: true);
  }
}
