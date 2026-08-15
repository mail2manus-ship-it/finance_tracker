import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_ranges.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import 'expense_providers.dart';
import 'income_providers.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

/// Currently-selected report period and reference date (e.g. "the week
/// containing referenceDate"). The Reports screen's tab bar writes here;
/// everything else re-derives from it.
class ReportPeriodState {
  final ReportPeriod period;
  final DateTime referenceDate;

  const ReportPeriodState({required this.period, required this.referenceDate});

  ReportPeriodState copyWith({ReportPeriod? period, DateTime? referenceDate}) {
    return ReportPeriodState(
      period: period ?? this.period,
      referenceDate: referenceDate ?? this.referenceDate,
    );
  }

  (DateTime, DateTime) get range {
    switch (period) {
      case ReportPeriod.daily:
        return (DateRanges.startOfDay(referenceDate), DateRanges.endOfDay(referenceDate));
      case ReportPeriod.weekly:
        return (DateRanges.startOfWeek(referenceDate), DateRanges.endOfWeek(referenceDate));
      case ReportPeriod.monthly:
        return (DateRanges.startOfMonth(referenceDate), DateRanges.endOfMonth(referenceDate));
      case ReportPeriod.yearly:
        return (DateRanges.startOfYear(referenceDate), DateRanges.endOfYear(referenceDate));
    }
  }
}

class ReportPeriodNotifier extends StateNotifier<ReportPeriodState> {
  ReportPeriodNotifier()
      : super(ReportPeriodState(period: ReportPeriod.monthly, referenceDate: DateTime.now()));

  void setPeriod(ReportPeriod period) => state = state.copyWith(period: period, referenceDate: DateTime.now());

  void goToPrevious() => state = state.copyWith(referenceDate: _shift(-1));
  void goToNext() => state = state.copyWith(referenceDate: _shift(1));

  DateTime _shift(int direction) {
    final d = state.referenceDate;
    switch (state.period) {
      case ReportPeriod.daily:
        return d.add(Duration(days: direction));
      case ReportPeriod.weekly:
        return d.add(Duration(days: 7 * direction));
      case ReportPeriod.monthly:
        return DateTime(d.year, d.month + direction, 1);
      case ReportPeriod.yearly:
        return DateTime(d.year + direction, d.month, d.day);
    }
  }
}

final reportPeriodProvider = StateNotifierProvider<ReportPeriodNotifier, ReportPeriodState>(
  (ref) => ReportPeriodNotifier(),
);

/// Expenses/income filtered to the currently-selected report period.
final reportExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(expenseListProvider).value ?? const <ExpenseModel>[];
  final (start, end) = ref.watch(reportPeriodProvider).range;
  return all.where((e) => e.dateTime.isAfter(start) && e.dateTime.isBefore(end)).toList();
});

final reportIncomesProvider = Provider<List<IncomeModel>>((ref) {
  final all = ref.watch(incomeListProvider).value ?? const <IncomeModel>[];
  final (start, end) = ref.watch(reportPeriodProvider).range;
  return all.where((i) => i.dateTime.isAfter(start) && i.dateTime.isBefore(end)).toList();
});

/// Chart-ready buckets for the selected period: by day for daily/weekly/
/// monthly, by month for yearly. Powers the Reports bar chart so it
/// doesn't render 31 illegible bars for a monthly view vs 7 for weekly.
final reportChartBucketsProvider = Provider<List<MapEntry<DateTime, ({double income, double expense})>>>((ref) {
  final state = ref.watch(reportPeriodProvider);
  final expenses = ref.watch(reportExpensesProvider);
  final incomes = ref.watch(reportIncomesProvider);
  final (start, end) = state.range;

  List<DateTime> bucketStarts;
  Duration Function(DateTime) bucketWidth;

  if (state.period == ReportPeriod.yearly) {
    bucketStarts = List.generate(12, (i) => DateTime(start.year, i + 1, 1));
    bucketWidth = (b) => DateTime(b.year, b.month + 1, 1).difference(b);
  } else {
    final days = end.difference(start).inDays;
    bucketStarts = List.generate(days, (i) => start.add(Duration(days: i)));
    bucketWidth = (_) => const Duration(days: 1);
  }

  return bucketStarts.map((bucketStart) {
    final bucketEnd = bucketStart.add(bucketWidth(bucketStart));
    final income = incomes
        .where((i) => !i.dateTime.isBefore(bucketStart) && i.dateTime.isBefore(bucketEnd))
        .fold(0.0, (s, i) => s + i.amount);
    final expense = expenses
        .where((e) => !e.dateTime.isBefore(bucketStart) && e.dateTime.isBefore(bucketEnd))
        .fold(0.0, (s, e) => s + e.amount);
    return MapEntry(bucketStart, (income: income, expense: expense));
  }).toList();
});
