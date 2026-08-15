import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/transaction_filter.dart';
import '../../data/models/income_model.dart';
import 'repository_providers.dart';

final incomeListProvider = StreamProvider<List<IncomeModel>>((ref) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.watchAll();
});

final filteredIncomeListProvider = Provider<List<IncomeModel>>((ref) {
  final incomeAsync = ref.watch(incomeListProvider);
  final filter = ref.watch(transactionFilterProvider);

  return incomeAsync.maybeWhen(
    data: (incomes) {
      var result = incomes;

      final range = filter.resolveRange();
      if (range != null) {
        final (start, end) = range;
        result = result
            .where((i) => i.dateTime.isAfter(start) && i.dateTime.isBefore(end))
            .toList();
      }

      if (filter.category != null && filter.category!.isNotEmpty) {
        result = result.where((i) => i.source == filter.category).toList();
      }

      if (filter.query.trim().isNotEmpty) {
        final q = filter.query.trim().toLowerCase();
        result = result.where((i) {
          return i.source.toLowerCase().contains(q) ||
              (i.notes?.toLowerCase().contains(q) ?? false) ||
              i.amount.toString().contains(q);
        }).toList();
      }

      return result;
    },
    orElse: () => const [],
  );
});

class IncomeActionsNotifier extends StateNotifier<int?> {
  final Ref ref;
  IncomeActionsNotifier(this.ref) : super(null);

  Future<void> delete(int id) async {
    await ref.read(incomeRepositoryProvider).deleteIncome(id);
    state = id;
  }

  Future<void> undoLastDelete() async {
    final id = state;
    if (id == null) return;
    await ref.read(incomeRepositoryProvider).restoreIncome(id);
    state = null;
  }

  void clearUndoState() => state = null;
}

final incomeActionsProvider =
    StateNotifierProvider<IncomeActionsNotifier, int?>(
  (ref) => IncomeActionsNotifier(ref),
);
