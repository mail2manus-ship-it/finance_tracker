import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_finance_tracker/core/utils/insights_generator.dart';
import 'package:my_personal_finance_tracker/domain/entities/summary.dart';

void main() {
  group('InsightsGenerator.generate', () {
    test('returns an empty list when there is no expense data', () {
      final insights = InsightsGenerator.generate(
        current: MonthlySummary.empty,
        previous: null,
        currencySymbol: '₹',
      );
      expect(insights, isEmpty);
    });

    test('reports the top category percentage of total spend', () {
      final current = MonthlySummary(
        totalIncome: 0,
        totalExpense: 1000,
        totalSavings: -1000,
        topCategories: const [
          CategoryTotal(category: 'Food', total: 380, count: 5),
          CategoryTotal(category: 'Travel', total: 200, count: 2),
        ],
        transactionCount: 7,
        averageDailyExpense: 50,
        averageDailyIncome: 0,
        highestExpenseDay: null,
        highestIncomeDay: null,
      );

      final insights = InsightsGenerator.generate(
        current: current,
        previous: null,
        currencySymbol: '₹',
      );

      expect(insights.any((s) => s.contains('38%') && s.contains('Food')), isTrue);
      expect(insights.any((s) => s.contains('highest expense category was Food')), isTrue);
      expect(insights.any((s) => s.contains('Average daily spending is ₹50')), isTrue);
    });

    test('flags a month-over-month increase in the top category', () {
      final previous = MonthlySummary(
        totalIncome: 0,
        totalExpense: 500,
        totalSavings: -500,
        topCategories: const [CategoryTotal(category: 'Travel', total: 500, count: 3)],
        transactionCount: 3,
        averageDailyExpense: 16,
        averageDailyIncome: 0,
        highestExpenseDay: null,
        highestIncomeDay: null,
      );
      final current = MonthlySummary(
        totalIncome: 0,
        totalExpense: 600,
        totalSavings: -600,
        topCategories: const [CategoryTotal(category: 'Travel', total: 600, count: 4)],
        transactionCount: 4,
        averageDailyExpense: 20,
        averageDailyIncome: 0,
        highestExpenseDay: null,
        highestIncomeDay: null,
      );

      final insights = InsightsGenerator.generate(
        current: current,
        previous: previous,
        currencySymbol: '₹',
      );

      expect(
        insights.any((s) => s.contains('Travel') && s.contains('increased by 20%')),
        isTrue,
      );
    });

    test('flags a month-over-month reduction in a category', () {
      final previous = MonthlySummary(
        totalIncome: 0,
        totalExpense: 400,
        totalSavings: -400,
        topCategories: const [CategoryTotal(category: 'Electricity Bill', total: 400, count: 1)],
        transactionCount: 1,
        averageDailyExpense: 13,
        averageDailyIncome: 0,
        highestExpenseDay: null,
        highestIncomeDay: null,
      );
      final current = MonthlySummary(
        totalIncome: 0,
        totalExpense: 300,
        totalSavings: -300,
        topCategories: const [CategoryTotal(category: 'Electricity Bill', total: 300, count: 1)],
        transactionCount: 1,
        averageDailyExpense: 10,
        averageDailyIncome: 0,
        highestExpenseDay: null,
        highestIncomeDay: null,
      );

      final insights = InsightsGenerator.generate(
        current: current,
        previous: previous,
        currencySymbol: '₹',
      );

      expect(
        insights.any((s) => s.contains('Electricity Bill') && s.contains('reduced by 25%')),
        isTrue,
      );
    });

    test('never returns more than 5 insights', () {
      final current = MonthlySummary(
        totalIncome: 0,
        totalExpense: 1000,
        totalSavings: -1000,
        topCategories: const [
          CategoryTotal(category: 'Food', total: 300, count: 5),
          CategoryTotal(category: 'Travel', total: 250, count: 4),
          CategoryTotal(category: 'Rent', total: 200, count: 1),
          CategoryTotal(category: 'Shopping', total: 150, count: 3),
          CategoryTotal(category: 'Medical', total: 100, count: 2),
        ],
        transactionCount: 15,
        averageDailyExpense: 33,
        averageDailyIncome: 0,
        highestExpenseDay: null,
        highestIncomeDay: null,
      );

      final insights = InsightsGenerator.generate(
        current: current,
        previous: null,
        currencySymbol: '₹',
      );

      expect(insights.length, lessThanOrEqualTo(5));
    });
  });
}
