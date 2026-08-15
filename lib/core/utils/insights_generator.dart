import '../../domain/entities/summary.dart';

/// Turns computed summary numbers into the short, human-readable insight
/// strings shown on the Dashboard (spec examples: "You spent 38% of your
/// money on Food this month.", "Your highest expense was Rent."). Pure
/// function of already-computed summaries -- no I/O, easy to unit test.
class InsightsGenerator {
  InsightsGenerator._();

  static List<String> generate({
    required MonthlySummary current,
    required MonthlySummary? previous,
    required String currencySymbol,
  }) {
    final insights = <String>[];

    if (current.totalExpense > 0 && current.topCategories.isNotEmpty) {
      final top = current.topCategories.first;
      final pct = (top.total / current.totalExpense * 100).round();
      insights.add('You spent $pct% of your money on ${top.category} this month.');
    }

    if (previous != null && previous.totalExpense > 0 && current.topCategories.isNotEmpty) {
      final topCategory = current.topCategories.first.category;
      final prevForCategory = previous.topCategories
          .where((c) => c.category == topCategory)
          .fold(0.0, (s, c) => s + c.total);
      if (prevForCategory > 0) {
        final change =
            ((current.topCategories.first.total - prevForCategory) / prevForCategory * 100)
                .round();
        if (change != 0) {
          final direction = change > 0 ? 'increased' : 'decreased';
          insights.add(
            '$topCategory expenses $direction by ${change.abs()}% compared to last month.',
          );
        }
      }
    }

    if (current.topCategories.isNotEmpty) {
      insights.add('Your highest expense category was ${current.topCategories.first.category}.');
    }

    if (current.averageDailyExpense > 0) {
      insights.add(
        'Average daily spending is $currencySymbol${current.averageDailyExpense.toStringAsFixed(0)}.',
      );
    }

    if (previous != null) {
      for (final cat in current.topCategories) {
        final prevMatch = previous.topCategories.where((c) => c.category == cat.category);
        if (prevMatch.isEmpty) continue;
        final prevTotal = prevMatch.first.total;
        if (prevTotal > 0 && cat.total < prevTotal) {
          final pct = ((prevTotal - cat.total) / prevTotal * 100).round();
          if (pct >= 10) {
            insights.add('${cat.category} spending reduced by $pct% this month.');
            break; // one "reduced" callout is enough to avoid a noisy list
          }
        }
      }
    }

    return insights.take(5).toList();
  }
}
