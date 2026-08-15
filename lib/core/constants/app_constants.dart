/// Central place for all static, non-visual constants used across the app.
/// Keeping these here (instead of scattering magic strings through the UI)
/// makes future changes -- e.g. adding a new expense category -- a one-line edit.
class AppConstants {
  AppConstants._();

  static const String appName = 'My Personal Finance Tracker';
  static const String appTagline = 'Track Every Rupee. Understand Every Expense.';

  /// Predefined expense categories. "Others" triggers a custom text field
  /// in the Add/Edit Expense screen (handled in the UI layer, not here).
  static const List<String> expenseCategories = [
    'Food',
    'Travel',
    'Petrol',
    'Rent',
    'Electricity Bill',
    'Water Bill',
    'Internet',
    'Mobile Recharge',
    'Shopping',
    'Entertainment',
    'Medical',
    'Education',
    'Insurance',
    'Household',
    'Subscription',
    'Maintenance',
    'Others',
  ];

  static const List<String> incomeSources = [
    'Salary',
    'Freelance',
    'Business',
    'Bonus',
    'Refund',
    'Interest',
    'Gift',
    'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Debit Card',
    'Credit Card',
    'Net Banking',
    'Wallet',
    'Other',
  ];

  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';

  /// Isar database file name.
  static const String dbName = 'finance_tracker_db';
}
