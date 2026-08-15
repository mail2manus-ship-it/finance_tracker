/// Small, dependency-free date helpers used by summary and report
/// calculations. Kept separate from `transaction_filter.dart` (which is
/// about UI filter presets) since these are pure calendar-math utilities.
class DateRanges {
  DateRanges._();

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime endOfDay(DateTime d) =>
      startOfDay(d).add(const Duration(days: 1));

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 1);

  static DateTime startOfYear(DateTime d) => DateTime(d.year, 1, 1);

  static DateTime endOfYear(DateTime d) => DateTime(d.year + 1, 1, 1);

  static DateTime startOfWeek(DateTime d) {
    final start = startOfDay(d);
    return start.subtract(Duration(days: start.weekday - 1)); // Monday
  }

  static DateTime endOfWeek(DateTime d) =>
      startOfWeek(d).add(const Duration(days: 7));

  /// Number of calendar days elapsed so far within [d]'s month, minimum 1
  /// (used for "average daily spending this month" so day 1 isn't a
  /// divide-by-zero and isn't diluted by future empty days).
  static int daysElapsedInMonth(DateTime d) => d.day;

  /// Total days in [d]'s month (for averages over a *completed* month).
  static int daysInMonth(DateTime d) => endOfMonth(d).difference(startOfMonth(d)).inDays;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
