import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_finance_tracker/core/utils/validators.dart';

void main() {
  group('Validators.amount', () {
    test('rejects null and empty input', () {
      expect(Validators.amount(null), isNotNull);
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('   '), isNotNull);
    });

    test('rejects non-numeric input', () {
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('12.34.56'), isNotNull);
    });

    test('rejects zero and negative amounts', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
    });

    test('rejects unrealistically large amounts', () {
      expect(Validators.amount('999999999999'), isNotNull);
    });

    test('accepts valid positive amounts', () {
      expect(Validators.amount('100'), isNull);
      expect(Validators.amount('99.99'), isNull);
      expect(Validators.amount('0.50'), isNull);
    });
  });

  group('Validators.requiredField', () {
    test('rejects null and blank values', () {
      expect(Validators.requiredField(null), isNotNull);
      expect(Validators.requiredField(''), isNotNull);
      expect(Validators.requiredField('   '), isNotNull);
    });

    test('accepts non-empty values', () {
      expect(Validators.requiredField('Food'), isNull);
    });

    test('includes the provided label in the message', () {
      final message = Validators.requiredField(null, label: 'Category');
      expect(message, contains('Category'));
    });
  });

  group('Validators.customCategory', () {
    test('is not required when isRequired is false', () {
      expect(Validators.customCategory(null, isRequired: false), isNull);
      expect(Validators.customCategory('', isRequired: false), isNull);
    });

    test('is required when isRequired is true', () {
      expect(Validators.customCategory(null, isRequired: true), isNotNull);
      expect(Validators.customCategory('', isRequired: true), isNotNull);
      expect(Validators.customCategory('  ', isRequired: true), isNotNull);
    });

    test('rejects values over 30 characters', () {
      final tooLong = 'A' * 31;
      expect(Validators.customCategory(tooLong, isRequired: true), isNotNull);
    });

    test('accepts a reasonable custom category', () {
      expect(Validators.customCategory('Gym Membership', isRequired: true), isNull);
    });
  });

  group('Validators.notes', () {
    test('accepts null and short notes', () {
      expect(Validators.notes(null), isNull);
      expect(Validators.notes('Lunch with team'), isNull);
    });

    test('rejects notes over 300 characters', () {
      final tooLong = 'x' * 301;
      expect(Validators.notes(tooLong), isNotNull);
    });
  });
}
