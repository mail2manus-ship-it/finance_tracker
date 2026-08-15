import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/export/report_export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/summary.dart';
import '../../providers/report_providers.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/income_expense_bar_chart.dart';

/// Reports screen: Daily / Weekly / Monthly / Yearly tabs, each showing
/// Income vs Expense, a category breakdown, and Export actions. Reuses
/// the same chart widgets built for the Dashboard in Phase 3.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  String _periodLabel(ReportPeriodState state) {
    switch (state.period) {
      case ReportPeriod.daily:
        return DateFormat('EEEE, d MMMM yyyy').format(state.referenceDate);
      case ReportPeriod.weekly:
        final (start, end) = state.range;
        return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end.subtract(const Duration(days: 1)))}';
      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy').format(state.referenceDate);
      case ReportPeriod.yearly:
        return DateFormat('yyyy').format(state.referenceDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodState = ref.watch(reportPeriodProvider);
    final expenses = ref.watch(reportExpensesProvider);
    final incomes = ref.watch(reportIncomesProvider);
    final buckets = ref.watch(reportChartBucketsProvider);
    const currency = AppConstants.defaultCurrencySymbol;

    final totalIncome = incomes.fold(0.0, (s, i) => s + i.amount);
    final totalExpense = expenses.fold(0.0, (s, e) => s + e.amount);

    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};
    for (final e in expenses) {
      categoryTotals[e.displayCategory] = (categoryTotals[e.displayCategory] ?? 0) + e.amount;
      categoryCounts[e.displayCategory] = (categoryCounts[e.displayCategory] ?? 0) + 1;
    }
    final categories = categoryTotals.entries
        .map((e) => CategoryTotal(category: e.key, total: e.value, count: categoryCounts[e.key] ?? 0))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    String money(double v) => '$currency${NumberFormat('#,##0').format(v)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          _PeriodTabs(selected: periodState.period, ref: ref),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => ref.read(reportPeriodProvider.notifier).goToPrevious(),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                _periodLabel(periodState),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () => ref.read(reportPeriodProvider.notifier).goToNext(),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                Row(
                  children: [
                    Expanded(child: _TotalChip(label: 'Income', value: money(totalIncome), color: AppColors.income)),
                    const SizedBox(width: 10),
                    Expanded(child: _TotalChip(label: 'Expense', value: money(totalExpense), color: AppColors.expense)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TotalChip(
                        label: 'Savings',
                        value: money(totalIncome - totalExpense),
                        color: AppColors.savings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Income vs Expense', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
                    child: IncomeExpenseBarChart(
                      data: buckets
                          .map((e) => DailyTotal(day: e.key, income: e.value.income, expense: e.value.expense))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Category Comparison', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CategoryPieChart(
                      categories: categories,
                      totalExpense: totalExpense,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Export Report', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ExportButton(
                        label: 'PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        onTap: () => _export(context, ref, ExportFormat.pdf, _periodLabel(periodState)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExportButton(
                        label: 'Excel',
                        icon: Icons.grid_on_rounded,
                        onTap: () => _export(context, ref, ExportFormat.excel, _periodLabel(periodState)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExportButton(
                        label: 'CSV',
                        icon: Icons.table_chart_rounded,
                        onTap: () => _export(context, ref, ExportFormat.csv, _periodLabel(periodState)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, ExportFormat format, String label) async {
    final expenses = ref.read(reportExpensesProvider);
    final incomes = ref.read(reportIncomesProvider);

    if (expenses.isEmpty && incomes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export for this period yet.')),
      );
      return;
    }

    try {
      await ReportExportService.exportAndShare(
        format: format,
        expenses: expenses,
        incomes: incomes,
        periodLabel: label,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _PeriodTabs extends StatelessWidget {
  final ReportPeriod selected;
  final WidgetRef ref;
  const _PeriodTabs({required this.selected, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: ReportPeriod.values.map((p) {
          final isSelected = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(reportPeriodProvider.notifier).setPeriod(p),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                ),
                child: Text(
                  p.name[0].toUpperCase() + p.name.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TotalChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ExportButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
