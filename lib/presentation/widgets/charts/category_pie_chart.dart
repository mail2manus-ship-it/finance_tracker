import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/summary.dart';

/// Pie chart of expense-by-category, with a legend. Reused by the
/// Dashboard's Monthly Overview card and by Reports' Category Comparison.
class CategoryPieChart extends StatelessWidget {
  final List<CategoryTotal> categories;
  final double totalExpense;

  const CategoryPieChart({
    super.key,
    required this.categories,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty || totalExpense <= 0) {
      return _EmptyChart(message: 'No expenses recorded yet');
    }

    final top = categories.take(6).toList();
    final othersTotal = categories.skip(6).fold(0.0, (s, c) => s + c.total);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                ...top.map((c) => PieChartSectionData(
                      value: c.total,
                      color: AppColors.colorForCategory(c.category),
                      title: '${(c.total / totalExpense * 100).round()}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )),
                if (othersTotal > 0)
                  PieChartSectionData(
                    value: othersTotal,
                    color: AppColors.textSecondaryLight,
                    title: '${(othersTotal / totalExpense * 100).round()}%',
                    radius: 46,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ...top.map((c) => _LegendItem(
                  color: AppColors.colorForCategory(c.category),
                  label: c.category,
                )),
            if (othersTotal > 0)
              const _LegendItem(color: AppColors.textSecondaryLight, label: 'Others'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
      ),
    );
  }
}
