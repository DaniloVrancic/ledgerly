// Turns a period's totals into plain observations: how income and spending compare with the
// month before and the usual, and how much of income each category takes.

import '../core/money.dart';

class CategoryAmount {
  const CategoryAmount(this.categoryId, this.amountMinor);
  final String categoryId;

  /// In EUR minor units, positive.
  final int amountMinor;
}

/// Income and spending for one period, in EUR.
class PeriodTotals {
  const PeriodTotals({required this.incomeMinor, required this.spendingMinor, required this.spendingByCategory, required this.incomeByCategory});

  static const empty = PeriodTotals(incomeMinor: 0, spendingMinor: 0, spendingByCategory: [], incomeByCategory: []);

  final int incomeMinor;

  /// Expenses minus refunds.
  final int spendingMinor;

  /// Top-level categories, largest first.
  final List<CategoryAmount> spendingByCategory;
  final List<CategoryAmount> incomeByCategory;

  /// Income minus spending.
  int get netMinor => incomeMinor - spendingMinor;

  /// Net divided by income. Null when there was no income.
  double? get savingsRate => incomeMinor == 0 ? null : netMinor / incomeMinor;

  int spendingFor(String categoryId) =>
      spendingByCategory.where((c) => c.categoryId == categoryId).fold(0, (s, c) => s + c.amountMinor);
}

/// The percentage change from [before] to [now], or null when there was nothing before.
int? percentChange(int now, int before) => before == 0 ? null : (((now - before) / before) * 100).round();

/// The share of income a category took, from 0 to 1. Null without income.
double? shareOfIncome(int amountMinor, int incomeMinor) => incomeMinor == 0 ? null : amountMinor / incomeMinor;

class Insight {
  const Insight(this.text, {this.categoryId});
  final String text;
  final String? categoryId;
}

/// A few observations, each with the figures it relies on. [previous] are earlier periods,
/// most recent last; up to three are used for the usual level.
List<Insight> insightsFor({required PeriodTotals current, required List<PeriodTotals> previous, required String Function(String id) nameOf}) {
  final out = <Insight>[];
  final recent = previous.length > 3 ? previous.sublist(previous.length - 3) : previous;

  if (current.incomeMinor > 0) {
    final rate = current.savingsRate!;
    out.add(Insight(rate >= 0
        ? 'You kept ${(rate * 100).round()}% of your income, ${formatMoney(current.netMinor, 'EUR')}.'
        : 'You spent ${formatMoney(-current.netMinor, 'EUR')} more than you earned.'));
  }

  if (current.spendingByCategory.isNotEmpty && current.incomeMinor > 0) {
    final top = current.spendingByCategory.first;
    final share = shareOfIncome(top.amountMinor, current.incomeMinor)!;
    out.add(Insight('${nameOf(top.categoryId)} took ${(share * 100).round()}% of your income, ${formatMoney(top.amountMinor, 'EUR')}.', categoryId: top.categoryId));
  }

  if (recent.isNotEmpty) {
    Insight? biggest;
    var biggestGap = 0;
    for (final c in current.spendingByCategory) {
      final usual = (recent.fold<int>(0, (s, p) => s + p.spendingFor(c.categoryId)) / recent.length).round();
      final gap = c.amountMinor - usual;
      if (usual > 0 && gap.abs() > biggestGap && gap.abs() >= 1000) {
        biggestGap = gap.abs();
        biggest = Insight(
          '${nameOf(c.categoryId)} is ${formatMoney(gap.abs(), 'EUR')} ${gap > 0 ? 'above' : 'below'} its usual ${formatMoney(usual, 'EUR')}.',
          categoryId: c.categoryId,
        );
      }
    }
    if (biggest != null) out.add(biggest);
  }
  return out;
}
