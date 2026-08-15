import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_finance_tracker/core/utils/transaction_filter.dart';

void main() {
  group('TransactionFilter.resolveRange', () {
    test('DateFilterPreset.all resolves to null (no restriction)', () {
      const filter = TransactionFilter(datePreset: DateFilterPreset.all);
      expect(filter.resolveRange(), isNull);
    });

    test('DateFilterPreset.today spans exactly today', () {
      const filter = TransactionFilter(datePreset: DateFilterPreset.today);
      final range = filter.resolveRange();
      expect(range, isNotNull);
      final now = DateTime.now();
      final expectedStart = DateTime(now.year, now.month, now.day);
      expect(range!.$1, expectedStart);
      expect(range.$2, expectedStart.add(const Duration(days: 1)));
    });

    test('DateFilterPreset.yesterday is the day before today', () {
      const filter = TransactionFilter(datePreset: DateFilterPreset.yesterday);
      final range = filter.resolveRange();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      expect(range!.$1, todayStart.subtract(const Duration(days: 1)));
      expect(range.$2, todayStart);
    });

    test('DateFilterPreset.custom with no dates set resolves to null', () {
      const filter = TransactionFilter(datePreset: DateFilterPreset.custom);
      expect(filter.resolveRange(), isNull);
    });

    test('DateFilterPreset.custom with dates set is inclusive of the end date', () {
      final filter = TransactionFilter(
        datePreset: DateFilterPreset.custom,
        customStart: DateTime(2026, 1, 1),
        customEnd: DateTime(2026, 1, 10),
      );
      final range = filter.resolveRange();
      expect(range!.$1, DateTime(2026, 1, 1));
      // End should be exclusive-upper-bound of the day AFTER customEnd,
      // so a transaction on Jan 10 itself is still included.
      expect(range.$2, DateTime(2026, 1, 11));
    });
  });

  group('TransactionFilter.copyWith', () {
    test('preserves unspecified fields', () {
      const original = TransactionFilter(query: 'coffee', category: 'Food');
      final updated = original.copyWith(query: 'tea');
      expect(updated.query, 'tea');
      expect(updated.category, 'Food');
    });

    test('clearCategory explicitly nulls out the category', () {
      const original = TransactionFilter(category: 'Food');
      final updated = original.copyWith(clearCategory: true);
      expect(updated.category, isNull);
    });
  });
}
