import '../../data/models/income_model.dart';

abstract class IncomeRepository {
  Future<int> addIncome(IncomeModel income);
  Future<void> updateIncome(IncomeModel income);
  Future<void> deleteIncome(int id);
  Future<void> restoreIncome(int id);

  Future<IncomeModel?> getById(int id);
  Future<List<IncomeModel>> getAll();
  Future<List<IncomeModel>> getByDateRange(DateTime start, DateTime end);
  Future<List<IncomeModel>> search(String query);

  Stream<List<IncomeModel>> watchAll();
  Stream<List<IncomeModel>> watchByDateRange(DateTime start, DateTime end);
}
