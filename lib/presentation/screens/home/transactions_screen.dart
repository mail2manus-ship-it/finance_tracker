import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/transaction_filter.dart';
import '../../providers/expense_providers.dart';
import '../../providers/filter_providers.dart';
import '../../providers/income_providers.dart';
import '../../widgets/common/filter_sheet.dart';
import '../../widgets/common/transaction_tile.dart';
import '../expense/add_edit_expense_screen.dart';
import '../income/add_edit_income_screen.dart';

/// Merges filtered expenses and income into one reverse-chronological
/// list, with a search bar and a filter sheet (date/type/category).
/// Swiping a row deletes it (soft delete) and shows an Undo SnackBar,
/// satisfying the spec's "Delete / Undo Delete" requirement.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final current = ref.read(transactionFilterProvider);
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FilterSheet(initial: current),
    );
    if (result != null) {
      ref.read(transactionFilterProvider.notifier).state = result;
    }
  }

  void _onSearchChanged(String value) {
    final current = ref.read(transactionFilterProvider);
    ref.read(transactionFilterProvider.notifier).state =
        current.copyWith(query: value);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final expenses = ref.watch(filteredExpenseListProvider);
    final incomes = ref.watch(filteredIncomeListProvider);

    final showExpenses = filter.type != TransactionTypeFilter.income;
    final showIncomes = filter.type != TransactionTypeFilter.expense;

    // Merge into one sorted, typed list for a unified feed.
    final items = <_ListItem>[
      if (showExpenses) ...expenses.map((e) => _ListItem.expense(e)),
      if (showIncomes) ...incomes.map((i) => _ListItem.income(i)),
    ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search by category, notes, or amount',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Slidable(
                        key: ValueKey('${item.isExpense}-${item.id}'),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) => _handleDelete(item),
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'Delete',
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        child: TransactionTile(
                          title: item.title,
                          subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(item.dateTime),
                          amount: item.amount,
                          isExpense: item.isExpense,
                          onTap: () => _openEdit(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit(_ListItem item) async {
    if (item.isExpense) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expense: item.expense)),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditIncomeScreen(income: item.income)),
      );
    }
  }

  Future<void> _handleDelete(_ListItem item) async {
    if (item.isExpense) {
      await ref.read(expenseActionsProvider.notifier).delete(item.id);
    } else {
      await ref.read(incomeActionsProvider.notifier).delete(item.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.isExpense ? "Expense" : "Income"} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (item.isExpense) {
              ref.read(expenseActionsProvider.notifier).undoLastDelete();
            } else {
              ref.read(incomeActionsProvider.notifier).undoLastDelete();
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          const Text('No transactions match your search or filters'),
        ],
      ),
    );
  }
}

/// Lightweight union type so expense & income rows can share one sorted
/// list without a sealed-class package dependency.
class _ListItem {
  final bool isExpense;
  final dynamic _model;

  _ListItem.expense(dynamic model) : isExpense = true, _model = model;
  _ListItem.income(dynamic model) : isExpense = false, _model = model;

  int get id => _model.id;
  DateTime get dateTime => _model.dateTime;
  double get amount => _model.amount;
  String get title => isExpense ? _model.displayCategory as String : _model.source as String;

  dynamic get expense => isExpense ? _model : null;
  dynamic get income => !isExpense ? _model : null;
}
