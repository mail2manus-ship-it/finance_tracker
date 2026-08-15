/// Which quick date-range preset is active. `custom` means the user picked
/// their own start/end via a date-range picker (stored separately).
enum DateFilterPreset { all, today, yesterday, thisWeek, thisMonth, thisYear, custom }

enum TransactionTypeFilter { all, income, expense }

/// Immutable value object describing the current Search & Filter state.
/// Passed straight into repository queries (`getByDateRange`, `search`),
/// so the UI layer never builds Isar queries itself.
class TransactionFilter {
  final String query;
  final DateFilterPreset datePreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? category; // expense category or income source
  final TransactionTypeFilter type;

  const TransactionFilter({
    this.query = '',
    this.datePreset = DateFilterPreset.all,
    this.customStart,
    this.customEnd,
    this.category,
    this.type = TransactionTypeFilter.all,
  });

  TransactionFilter copyWith({
    String? query,
    DateFilterPreset? datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    String? category,
    bool clearCategory = false,
    TransactionTypeFilter? type,
  }) {
    return TransactionFilter(
      query: query ?? this.query,
      datePreset: datePreset ?? this.datePreset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      category: clearCategory ? null : (category ?? this.category),
      type: type ?? this.type,
    );
  }

  /// Resolves the active preset into a concrete [start, end] range.
  /// Returns null for [DateFilterPreset.all] (no date restriction).
  (DateTime, DateTime)? resolveRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    switch (datePreset) {
      case DateFilterPreset.all:
        return null;
      case DateFilterPreset.today:
        return (todayStart, todayEnd);
      case DateFilterPreset.yesterday:
        return (todayStart.subtract(const Duration(days: 1)), todayStart);
      case DateFilterPreset.thisWeek:
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return (weekStart, todayEnd);
      case DateFilterPreset.thisMonth:
        return (DateTime(now.year, now.month, 1), todayEnd);
      case DateFilterPreset.thisYear:
        return (DateTime(now.year, 1, 1), todayEnd);
      case DateFilterPreset.custom:
        if (customStart == null || customEnd == null) return null;
        return (customStart!, customEnd!.add(const Duration(days: 1)));
    }
  }
}
