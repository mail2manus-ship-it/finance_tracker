/// Plain aggregation results consumed by the Dashboard, Daily Summary,
/// Monthly Summary, and Statistics screens. Computed in
/// `summary_providers.dart` from the live expense/income streams --
/// nothing here talks to Isar or Riverpod, so it's trivially testable.

class CategoryTotal {
  final String category;
  final double total;
  final int count;

  const CategoryTotal({
    required this.category,
    required this.total,
    required this.count,
  });
}

class DailySummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<CategoryTotal> expenseByCategory;
  final CategoryTotal? highestExpenseCategory;
  final double? highestExpenseAmount;
  final int transactionCount;

  const DailySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseByCategory,
    required this.highestExpenseCategory,
    required this.highestExpenseAmount,
    required this.transactionCount,
  });

  static const empty = DailySummary(
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
    expenseByCategory: [],
    highestExpenseCategory: null,
    highestExpenseAmount: null,
    transactionCount: 0,
  );
}

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double totalSavings;
  final List<CategoryTotal> topCategories; // top 5, descending
  final int transactionCount;
  final double averageDailyExpense;
  final double averageDailyIncome;
  final MapEntry<DateTime, double>? highestExpenseDay;
  final MapEntry<DateTime, double>? highestIncomeDay;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSavings,
    required this.topCategories,
    required this.transactionCount,
    required this.averageDailyExpense,
    required this.averageDailyIncome,
    required this.highestExpenseDay,
    required this.highestIncomeDay,
  });

  static const empty = MonthlySummary(
    totalIncome: 0,
    totalExpense: 0,
    totalSavings: 0,
    topCategories: [],
    transactionCount: 0,
    averageDailyExpense: 0,
    averageDailyIncome: 0,
    highestExpenseDay: null,
    highestIncomeDay: null,
  );
}

class OverallStatistics {
  final double highestExpense;
  final double lowestExpense;
  final double highestIncome;
  final double averageExpense;
  final double averageIncome;
  final String? mostUsedCategory;
  final double dailyAverageSpending;

  const OverallStatistics({
    required this.highestExpense,
    required this.lowestExpense,
    required this.highestIncome,
    required this.averageExpense,
    required this.averageIncome,
    required this.mostUsedCategory,
    required this.dailyAverageSpending,
  });

  static const empty = OverallStatistics(
    highestExpense: 0,
    lowestExpense: 0,
    highestIncome: 0,
    averageExpense: 0,
    averageIncome: 0,
    mostUsedCategory: null,
    dailyAverageSpending: 0,
  );
}
