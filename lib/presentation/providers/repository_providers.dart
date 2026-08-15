import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../data/repositories/isar_expense_repository.dart';
import '../../data/repositories/isar_income_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/income_repository.dart';

/// Exposes the concrete Isar repositories behind their abstract contracts.
/// Everything above this layer (notifiers, screens) depends only on
/// `ExpenseRepository` / `IncomeRepository`, never on Isar directly.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return IsarExpenseRepository(ref.watch(isarProvider));
});

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IsarIncomeRepository(ref.watch(isarProvider));
});
