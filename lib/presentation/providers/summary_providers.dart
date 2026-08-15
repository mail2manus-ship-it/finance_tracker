import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_ranges.dart';
import '../../core/utils/insights_generator.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../domain/entities/summary.dart';
import 'expense_providers.dart';
import 'income_providers.dart';

/// All of these providers derive from the same two live streams
/// (`expenseListProvider`, `incomeListProvider`), so any add/edit/delete
/// anywhere in the app recalculates the Dashboard, Daily Summary, Monthly
/// Summary, and Statistics automatically -- no manual refresh, no
/// duplicated queries against Isar.

List<CategoryTotal> _categoryBreakdown(List<ExpenseModel> expenses) {
  final totals = <String, double>{};
  final counts = <String, int>{};
  for (final e in expenses) {
    final key = e.displayCategory;
    totals[key] = (totals[key] ?? 0) + e.amount;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final list = totals.entries
      .map((e) => CategoryTotal(
            category: e.key,
            total: e.value,
            count: counts[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  return list;
}

/// Today's summary: income, expense, balance, category breakdown,
/// highest expense, transaction count.
final dailySummaryProvider = Provider<DailySummary>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final incomesAsync = ref.watch(incomeListProvider);
  if (!expensesAsync.hasValue || !incomesAsync.hasValue) return DailySummary.empty;

  final now = DateTime.now();
  final start = DateRanges.startOfDay(now);
  final end = DateRanges.endOfDay(now);

  final todayExpenses = expensesAsync.value!
      .where((e) => e.dateTime.isAfter(start) && e.dateTime.isBefore(end))
      .toList();
  final todayIncomes = incomesAsync.value!
      .where((i) => i.dateTime.isAfter(start) && i.dateTime.isBefore(end))
      .toList();

  final totalExpense = todayExpenses.fold(0.0, (s, e) => s + e.amount);
  final totalIncome = todayIncomes.fold(0.0, (s, i) => s + i.amount);
  final byCategory = _categoryBreakdown(todayExpenses);

  return DailySummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    balance: totalIncome - totalExpense,
    expenseByCategory: byCategory,
    highestExpenseCategory: byCategory.isEmpty ? null : byCategory.first,
    highestExpenseAmount: todayExpenses.isEmpty
        ? null
        : todayExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b),
    transactionCount: todayExpenses.length + todayIncomes.length,
  );
});

MonthlySummary _computeMonthlySummary({
  required List<ExpenseModel> allExpenses,
  required List<IncomeModel> allIncomes,
  required DateTime month,
}) {
  final start = DateRanges.startOfMonth(month);
  final end = DateRanges.endOfMonth(month);
  final now = DateTime.now();

  final monthExpenses =
      allExpenses.where((e) => e.dateTime.isAfter(start) && e.dateTime.isBefore(end)).toList();
  final monthIncomes =
      allIncomes.where((i) => i.dateTime.isAfter(start) && i.dateTime.isBefore(end)).toList();

  final totalExpense = monthExpenses.fold(0.0, (s, e) => s + e.amount);
  final totalIncome = monthIncomes.fold(0.0, (s, i) => s + i.amount);

  final byCategory = _categoryBreakdown(monthExpenses);
  final topFive = byCategory.take(5).toList();

  // For the current month, average over days elapsed so far; for a fully
  // past month, average over the whole month.
  final isCurrentMonth = start.year == now.year && start.month == now.month;
  final divisorDays =
      isCurrentMonth ? DateRanges.daysElapsedInMonth(now) : DateRanges.daysInMonth(start);

  final expenseByDay = <DateTime, double>{};
  for (final e in monthExpenses) {
    final day = DateRanges.startOfDay(e.dateTime);
    expenseByDay[day] = (expenseByDay[day] ?? 0) + e.amount;
  }
  final incomeByDay = <DateTime, double>{};
  for (final i in monthIncomes) {
    final day = DateRanges.startOfDay(i.dateTime);
    incomeByDay[day] = (incomeByDay[day] ?? 0) + i.amount;
  }

  MapEntry<DateTime, double>? highestOf(Map<DateTime, double> m) {
    if (m.isEmpty) return null;
    return m.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  return MonthlySummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    totalSavings: totalIncome - totalExpense,
    topCategories: topFive,
    transactionCount: monthExpenses.length + monthIncomes.length,
    averageDailyExpense: divisorDays == 0 ? 0 : totalExpense / divisorDays,
    averageDailyIncome: divisorDays == 0 ? 0 : totalIncome / divisorDays,
    highestExpenseDay: highestOf(expenseByDay),
    highestIncomeDay: highestOf(incomeByDay),
  );
}

/// Family provider: monthly summary for an arbitrary month, keyed by its
/// first-of-month DateTime. Powers both the current-month convenience
/// provider below and Reports' month-by-month views (Phase 4).
final monthlySummaryForProvider =
    Provider.family<MonthlySummary, DateTime>((ref, month) {
  final expensesAsync = ref.watch(expenseListProvider);
  final incomesAsync = ref.watch(incomeListProvider);
  if (!expensesAsync.hasValue || !incomesAsync.hasValue) return MonthlySummary.empty;

  return _computeMonthlySummary(
    allExpenses: expensesAsync.value!,
    allIncomes: incomesAsync.value!,
    month: month,
  );
});

/// Current-month summary: totals, savings, top 5 categories, averages,
/// and the single highest expense/income day.
final monthlySummaryProvider = Provider<MonthlySummary>((ref) {
  return ref.watch(monthlySummaryForProvider(DateTime.now()));
});

/// Previous calendar month's summary, used for month-over-month
/// comparisons in the Smart Insights feed.
final previousMonthSummaryProvider = Provider<MonthlySummary>((ref) {
  final now = DateTime.now();
  final previousMonth = DateTime(now.year, now.month - 1, 1);
  return ref.watch(monthlySummaryForProvider(previousMonth));
});

/// All-time statistics across every non-deleted transaction.
final overallStatisticsProvider = Provider<OverallStatistics>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final incomesAsync = ref.watch(incomeListProvider);
  if (!expensesAsync.hasValue || !incomesAsync.hasValue) return OverallStatistics.empty;

  final expenses = expensesAsync.value!;
  final incomes = incomesAsync.value!;

  if (expenses.isEmpty && incomes.isEmpty) return OverallStatistics.empty;

  final expenseAmounts = expenses.map((e) => e.amount).toList();
  final incomeAmounts = incomes.map((i) => i.amount).toList();

  final byCategory = _categoryBreakdown(expenses);
  final mostUsed = byCategory.isEmpty
      ? null
      : (byCategory.toList()..sort((a, b) => b.count.compareTo(a.count))).first.category;

  // Daily average spending across the span from the first recorded
  // transaction to today, so it reflects real historical pace rather
  // than just the current month.
  double dailyAvg = 0;
  if (expenses.isNotEmpty) {
    final earliest = expenses.map((e) => e.dateTime).reduce((a, b) => a.isBefore(b) ? a : b);
    final days = DateTime.now().difference(DateRanges.startOfDay(earliest)).inDays + 1;
    dailyAvg = expenseAmounts.fold(0.0, (s, a) => s + a) / (days == 0 ? 1 : days);
  }

  return OverallStatistics(
    highestExpense: expenseAmounts.isEmpty ? 0 : expenseAmounts.reduce((a, b) => a > b ? a : b),
    lowestExpense: expenseAmounts.isEmpty ? 0 : expenseAmounts.reduce((a, b) => a < b ? a : b),
    highestIncome: incomeAmounts.isEmpty ? 0 : incomeAmounts.reduce((a, b) => a > b ? a : b),
    averageExpense: expenseAmounts.isEmpty
        ? 0
        : expenseAmounts.fold(0.0, (s, a) => s + a) / expenseAmounts.length,
    averageIncome: incomeAmounts.isEmpty
        ? 0
        : incomeAmounts.fold(0.0, (s, a) => s + a) / incomeAmounts.length,
    mostUsedCategory: mostUsed,
    dailyAverageSpending: dailyAvg,
  );
});

/// Most recent transactions across both expense & income, newest first,
/// for the Dashboard's "Recent Transactions" list.
final recentTransactionsProvider = Provider<List<dynamic>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final incomesAsync = ref.watch(incomeListProvider);
  final expenses = expensesAsync.value ?? const <ExpenseModel>[];
  final incomes = incomesAsync.value ?? const <IncomeModel>[];

  final merged = <dynamic>[...expenses, ...incomes]
    ..sort((a, b) => (b.dateTime as DateTime).compareTo(a.dateTime as DateTime));
  return merged.take(10).toList();
});

/// Last 7 calendar days (oldest first) of income/expense totals, for the
/// Dashboard's Weekly Expense Graph / Income vs Expense bar chart.
final weeklyChartDataProvider = Provider<List<MapEntry<DateTime, ({double income, double expense})>>>((ref) {
  final expenses = ref.watch(expenseListProvider).value ?? const <ExpenseModel>[];
  final incomes = ref.watch(incomeListProvider).value ?? const <IncomeModel>[];

  final today = DateRanges.startOfDay(DateTime.now());
  final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

  return days.map((day) {
    final dayEnd = day.add(const Duration(days: 1));
    final income = incomes
        .where((i) => i.dateTime.isAfter(day) && i.dateTime.isBefore(dayEnd))
        .fold(0.0, (s, i) => s + i.amount);
    final expense = expenses
        .where((e) => e.dateTime.isAfter(day) && e.dateTime.isBefore(dayEnd))
        .fold(0.0, (s, e) => s + e.amount);
    return MapEntry(day, (income: income, expense: expense));
  }).toList();
});

/// Cumulative running savings balance (all-time income minus expense,
/// running total) sampled once per day for the last 30 days -- the
/// Dashboard/Reports "Savings Trend" line chart.
final savingsTrendProvider = Provider<List<MapEntry<DateTime, double>>>((ref) {
  final expenses = ref.watch(expenseListProvider).value ?? const <ExpenseModel>[];
  final incomes = ref.watch(incomeListProvider).value ?? const <IncomeModel>[];
  if (expenses.isEmpty && incomes.isEmpty) return const [];

  final today = DateRanges.startOfDay(DateTime.now());
  final windowStart = today.subtract(const Duration(days: 29));

  // Running balance carried in from before the visible window, so the
  // chart reflects true cumulative savings rather than resetting to 0.
  double runningBalance = 0;
  for (final e in expenses) {
    if (e.dateTime.isBefore(windowStart)) runningBalance -= e.amount;
  }
  for (final i in incomes) {
    if (i.dateTime.isBefore(windowStart)) runningBalance += i.amount;
  }

  final points = <MapEntry<DateTime, double>>[];
  for (var day = windowStart; !day.isAfter(today); day = day.add(const Duration(days: 1))) {
    final dayEnd = day.add(const Duration(days: 1));
    final dayIncome = incomes
        .where((i) => i.dateTime.isAfter(day.subtract(const Duration(milliseconds: 1))) && i.dateTime.isBefore(dayEnd))
        .fold(0.0, (s, i) => s + i.amount);
    final dayExpense = expenses
        .where((e) => e.dateTime.isAfter(day.subtract(const Duration(milliseconds: 1))) && e.dateTime.isBefore(dayEnd))
        .fold(0.0, (s, e) => s + e.amount);
    runningBalance += dayIncome - dayExpense;
    points.add(MapEntry(day, runningBalance));
  }
  return points;
});

/// Smart Financial Insights feed shown on the Dashboard. Currency symbol
/// is hardcoded to the app default for now -- Phase 5's Settings module
/// will thread the user's chosen currency through here instead.
final insightsProvider = Provider<List<String>>((ref) {
  final current = ref.watch(monthlySummaryProvider);
  final previous = ref.watch(previousMonthSummaryProvider);
  return InsightsGenerator.generate(
    current: current,
    previous: previous,
    currencySymbol: AppConstants.defaultCurrencySymbol,
  );
});
