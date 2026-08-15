import 'package:isar/isar.dart';

import '../../domain/repositories/income_repository.dart';
import '../models/income_model.dart';

class IsarIncomeRepository implements IncomeRepository {
  final Isar _isar;

  IsarIncomeRepository(this._isar);

  @override
  Future<int> addIncome(IncomeModel income) {
    final now = DateTime.now();
    income.createdAt = now;
    income.updatedAt = now;
    return _isar.writeTxn(() => _isar.incomeModels.put(income));
  }

  @override
  Future<void> updateIncome(IncomeModel income) {
    income.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.incomeModels.put(income));
  }

  @override
  Future<void> deleteIncome(int id) async {
    await _isar.writeTxn(() async {
      final income = await _isar.incomeModels.get(id);
      if (income == null) return;
      income.isDeleted = true;
      income.updatedAt = DateTime.now();
      await _isar.incomeModels.put(income);
    });
  }

  @override
  Future<void> restoreIncome(int id) async {
    await _isar.writeTxn(() async {
      final income = await _isar.incomeModels.get(id);
      if (income == null) return;
      income.isDeleted = false;
      income.updatedAt = DateTime.now();
      await _isar.incomeModels.put(income);
    });
  }

  @override
  Future<IncomeModel?> getById(int id) => _isar.incomeModels.get(id);

  @override
  Future<List<IncomeModel>> getAll() {
    return _isar.incomeModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateTimeDesc()
        .findAll();
  }

  @override
  Future<List<IncomeModel>> getByDateRange(DateTime start, DateTime end) {
    return _isar.incomeModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .dateTimeBetween(start, end)
        .sortByDateTimeDesc()
        .findAll();
  }

  @override
  Future<List<IncomeModel>> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return getAll();
    return _isar.incomeModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .group((r) => r
            .sourceContains(q, caseSensitive: false)
            .or()
            .notesContains(q, caseSensitive: false))
        .sortByDateTimeDesc()
        .findAll();
  }

  @override
  Stream<List<IncomeModel>> watchAll() {
    return _isar.incomeModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateTimeDesc()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<IncomeModel>> watchByDateRange(DateTime start, DateTime end) {
    return _isar.incomeModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .dateTimeBetween(start, end)
        .sortByDateTimeDesc()
        .watch(fireImmediately: true);
  }
}
