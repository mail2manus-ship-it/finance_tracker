/// Shared form validators used by both Add/Edit Expense and Add/Edit Income.
/// Centralizing these avoids subtly-different rules drifting apart between
/// the two forms over time.
class Validators {
  Validators._();

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero';
    }
    if (parsed > 100000000) {
      return 'Amount seems unrealistically large';
    }
    return null;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  /// Custom category text is only required when the user picked "Others".
  static String? customCategory(String? value, {required bool isRequired}) {
    if (!isRequired) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a category name';
    }
    if (value.trim().length > 30) {
      return 'Keep it under 30 characters';
    }
    return null;
  }

  static String? notes(String? value) {
    if (value != null && value.length > 300) {
      return 'Notes must be under 300 characters';
    }
    return null;
  }
}
