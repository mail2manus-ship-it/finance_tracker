import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/transaction_filter.dart';

/// Current Search & Filter state for the Transactions tab. Shared between
/// the expense and income filtered views (`filteredExpenseListProvider`,
/// `filteredIncomeListProvider`) so one filter bar drives both -- lives in
/// its own file rather than inside `expense_providers.dart` so
/// `income_providers.dart` can depend on it without an odd
/// income-depends-on-expense-file import.
final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());
