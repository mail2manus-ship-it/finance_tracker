import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../providers/summary_providers.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/income_expense_bar_chart.dart';
import '../../widgets/charts/savings_trend_chart.dart';
import '../expense/add_edit_expense_screen.dart';
import '../income/add_edit_income_screen.dart';

/// Real Dashboard, wired to live Isar-backed data via the summary
/// providers. Everything here recalculates automatically on any
/// add/edit/delete elsewhere in the app -- no pull-to-refresh needed.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailySummaryProvider);
    final monthly = ref.watch(monthlySummaryProvider);
    final weekly = ref.watch(weeklyChartDataProvider);
    final savingsTrend = ref.watch(savingsTrendProvider);
    final insights = ref.watch(insightsProvider);
    final recent = ref.watch(recentTransactionsProvider);
    const currency = AppConstants.defaultCurrencySymbol;

    String money(double v) => '$currency${NumberFormat('#,##0.0').format(v)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 20),

        // Today's Income / Expense
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: "Today's Income",
                value: money(daily.totalIncome),
                color: AppColors.income,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: "Today's Expense",
                value: money(daily.totalExpense),
                color: AppColors.expense,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: "Today's Balance",
          value: money(daily.balance),
          color: daily.balance >= 0 ? AppColors.savings : AppColors.expense,
          icon: Icons.account_balance_wallet_rounded,
        ),

        const SizedBox(height: 24),
        Text('This Month', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _MiniStat(label: 'Income', value: money(monthly.totalIncome), color: AppColors.income)),
                    Expanded(child: _MiniStat(label: 'Expense', value: money(monthly.totalExpense), color: AppColors.expense)),
                    Expanded(child: _MiniStat(label: 'Savings', value: money(monthly.totalSavings), color: AppColors.savings)),
                  ],
                ),
                const SizedBox(height: 4),
                if (daily.highestExpenseCategory != null) ...[
                  const Divider(height: 32),
                  _InfoRow(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Top Expense Category',
                    value: daily.highestExpenseCategory!.category,
                  ),
                ],
                if (daily.highestExpenseAmount != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.trending_up_rounded,
                    label: "Highest Expense Today",
                    value: money(daily.highestExpenseAmount!),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text('Monthly Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CategoryPieChart(
              categories: monthly.topCategories,
              totalExpense: monthly.totalExpense,
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text('Weekly Expense Graph', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
            child: IncomeExpenseBarChart(
              data: weekly
                  .map((e) => DailyTotal(day: e.key, income: e.value.income, expense: e.value.expense))
                  .toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text('Savings Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
            child: SavingsTrendChart(points: savingsTrend),
          ),
        ),

        const SizedBox(height: 20),
        Text('Statistics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final stats = ref.watch(overallStatisticsProvider);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _MiniStat(label: 'Highest Expense', value: money(stats.highestExpense), color: AppColors.expense)),
                        Expanded(child: _MiniStat(label: 'Lowest Expense', value: money(stats.lowestExpense), color: AppColors.expense)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _MiniStat(label: 'Avg Expense', value: money(stats.averageExpense), color: AppColors.expense)),
                        Expanded(child: _MiniStat(label: 'Avg Income', value: money(stats.averageIncome), color: AppColors.income)),
                      ],
                    ),
                    if (stats.mostUsedCategory != null) ...[
                      const Divider(height: 32),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: 'Most Used Category',
                        value: stats.mostUsedCategory!,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        if (insights.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Smart Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...insights.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              )),
        ],

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No transactions yet — tap + to add your first one.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
          )
        else
          ...recent.map((item) => _RecentTile(item: item, money: money)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryLight),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  final dynamic item;
  final String Function(double) money;
  const _RecentTile({required this.item, required this.money});

  @override
  Widget build(BuildContext context) {
    final isExpense = item is ExpenseModel;
    final color = isExpense ? AppColors.expense : AppColors.income;
    final title = isExpense ? (item as ExpenseModel).displayCategory : (item as IncomeModel).source;
    final amount = item.amount as double;
    final dateTime = item.dateTime as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () {
          if (isExpense) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expense: item)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditIncomeScreen(income: item)));
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(isExpense ? Icons.remove_rounded : Icons.add_rounded, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat('dd MMM, hh:mm a').format(dateTime)),
        trailing: Text(
          '${isExpense ? "-" : "+"}${money(amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
