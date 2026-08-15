import 'package:flutter/material.dart';

import '../../presentation/screens/expense/add_edit_expense_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/income/add_edit_income_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

/// Central route table. Kept intentionally simple (Navigator 1.0 named
/// routes) for Phase 1 -- sufficient for a single-user offline app with a
/// shallow navigation tree. Can be swapped for go_router later without
/// touching feature code, since screens never build routes themselves.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String addExpense = '/add-expense';
  static const String addIncome = '/add-income';
  static const String expenseDetail = '/expense-detail';
  static const String incomeDetail = '/income-detail';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        home: (_) => const HomeScreen(),
        addExpense: (_) => const AddEditExpenseScreen(),
        addIncome: (_) => const AddEditIncomeScreen(),
        // Reports and Settings are reached as bottom-nav tabs inside
        // HomeScreen, not as named routes, so they're intentionally
        // absent here. `reports`/`settings` constants above are kept
        // in case a future deep-link (e.g. from a notification) needs
        // to jump straight to one of them.
      };
}
