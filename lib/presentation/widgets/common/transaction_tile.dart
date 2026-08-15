import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Uniform row for both expense and income entries in a mixed list.
/// Keeping expense/income rendering in one widget (rather than two nearly
/// identical ones) avoids visual drift between the two transaction types.
class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isExpense;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;
    final sign = isExpense ? '-' : '+';
    final categoryColor = isExpense ? AppColors.colorForCategory(title) : color;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: categoryColor.withValues(alpha: 0.15),
          child: Icon(
            isExpense ? Icons.remove_rounded : Icons.add_rounded,
            color: categoryColor,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          '$sign${AppConstants.defaultCurrencySymbol}${NumberFormat('#,##0.00').format(amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
