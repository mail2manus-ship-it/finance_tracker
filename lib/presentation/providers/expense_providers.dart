import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense_model.dart';
import 'filter_providers.dart';
import 'repository_providers.dart';

/// Streams all (non-deleted) expenses, live-updating whenever the Isar
/// collection changes -- add/edit/delete anywhere in the app reflects here
/// immediately without manual refresh calls.
final expenseListProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchAll();
});

/// Applies [transactionFilterProvider] to the live expense stream.
/// Kept as a plain `Provider` (not another stream) since filtering is a
/// cheap, synchronous transform over already-loaded data.
final filteredExpenseListProvider = Provider<List<ExpenseModel>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final filter = ref.watch(transactionFilterProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      var result = expenses;

      final range = filter.resolveRange();
      if (range != null) {
        final (start, end) = range;
        result = result
            .where((e) => e.dateTime.isAfter(start) && e.dateTime.isBefore(end))
            .toList();
      }

      if (filter.category != null && filter.category!.isNotEmpty) {
        result = result.where((e) => e.displayCategory == filter.category).toList();
      }

      if (filter.query.trim().isNotEmpty) {
        final q = filter.query.trim().toLowerCase();
        result = result.where((e) {
          return e.displayCategory.toLowerCase().contains(q) ||
              (e.notes?.toLowerCase().contains(q) ?? false) ||
              e.amount.toString().contains(q);
        }).toList();
      }

      return result;
    },
    orElse: () => const [],
  );
});

/// Notifier for the delete/undo flow. Deleting is a soft-delete in the
/// repository; this notifier tracks the most recently deleted id so the
/// UI can show a SnackBar with an "Undo" action.
class ExpenseActionsNotifier extends StateNotifier<int?> {
  final Ref ref;
  ExpenseActionsNotifier(this.ref) : super(null);

  Future<void> delete(int id) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    state = id;
  }

  Future<void> undoLastDelete() async {
    final id = state;
    if (id == null) return;
    await ref.read(expenseRepositoryProvider).restoreExpense(id);
    state = null;
  }

  void clearUndoState() => state = null;
}

final expenseActionsProvider =
    StateNotifierProvider<ExpenseActionsNotifier, int?>(
  (ref) => ExpenseActionsNotifier(ref),
);
