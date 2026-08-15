import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_finance_tracker/core/utils/date_ranges.dart';

void main() {
  group('DateRanges', () {
    test('startOfDay / endOfDay strip and advance time correctly', () {
      final d = DateTime(2026, 3, 15, 14, 32, 10);
      expect(DateRanges.startOfDay(d), DateTime(2026, 3, 15));
      expect(DateRanges.endOfDay(d), DateTime(2026, 3, 16));
    });

    test('startOfMonth / endOfMonth handle December year rollover', () {
      final d = DateTime(2026, 12, 10);
      expect(DateRanges.startOfMonth(d), DateTime(2026, 12, 1));
      expect(DateRanges.endOfMonth(d), DateTime(2027, 1, 1));
    });

    test('startOfYear / endOfYear', () {
      final d = DateTime(2026, 6, 1);
      expect(DateRanges.startOfYear(d), DateTime(2026, 1, 1));
      expect(DateRanges.endOfYear(d), DateTime(2027, 1, 1));
    });

    test('startOfWeek returns the preceding (or same) Monday', () {
      // Wednesday 11 March 2026
      final wednesday = DateTime(2026, 3, 11);
      expect(DateRanges.startOfWeek(wednesday), DateTime(2026, 3, 9)); // Monday

      // Monday itself should return the same day.
      final monday = DateTime(2026, 3, 9);
      expect(DateRanges.startOfWeek(monday), DateTime(2026, 3, 9));
    });

    test('endOfWeek is exactly 7 days after startOfWeek', () {
      final d = DateTime(2026, 3, 11);
      final diff = DateRanges.endOfWeek(d).difference(DateRanges.startOfWeek(d));
      expect(diff, const Duration(days: 7));
    });

    test('daysElapsedInMonth returns the day-of-month', () {
      expect(DateRanges.daysElapsedInMonth(DateTime(2026, 3, 15)), 15);
      expect(DateRanges.daysElapsedInMonth(DateTime(2026, 3, 1)), 1);
    });

    test('daysInMonth accounts for leap years', () {
      expect(DateRanges.daysInMonth(DateTime(2024, 2, 10)), 29); // leap year
      expect(DateRanges.daysInMonth(DateTime(2026, 2, 10)), 28); // non-leap
      expect(DateRanges.daysInMonth(DateTime(2026, 4, 1)), 30);
    });

    test('isSameDay ignores time-of-day', () {
      expect(
        DateRanges.isSameDay(DateTime(2026, 3, 15, 1), DateTime(2026, 3, 15, 23)),
        isTrue,
      );
      expect(
        DateRanges.isSameDay(DateTime(2026, 3, 15), DateTime(2026, 3, 16)),
        isFalse,
      );
    });
  });
}
