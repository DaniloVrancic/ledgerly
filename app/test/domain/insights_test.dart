import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/insights.dart';

void main() {
  const current = PeriodTotals(
    incomeMinor: 200000,
    spendingMinor: 140000,
    spendingByCategory: [CategoryAmount('housing', 46000), CategoryAmount('food', 42000)],
    incomeByCategory: [CategoryAmount('salary', 200000)],
  );
  PeriodTotals past(int food) => PeriodTotals(incomeMinor: 200000, spendingMinor: 100000, spendingByCategory: [CategoryAmount('food', food)], incomeByCategory: const []);

  test('net and savings rate', () {
    expect(current.netMinor, 60000);
    expect(current.savingsRate, closeTo(0.3, 0.0001));
    expect(PeriodTotals.empty.savingsRate, isNull);
  });

  test('change and share of income', () {
    expect(percentChange(110, 100), 10);
    expect(percentChange(5, 0), isNull);
    expect(shareOfIncome(46000, 200000), 0.23);
  });

  test('observations carry their figures', () {
    final list = insightsFor(current: current, previous: [past(30000), past(30000), past(30000)], nameOf: (id) => id == 'food' ? 'Food' : 'Housing');
    expect(list[0].text, 'You kept 30% of your income, €600.00.');
    expect(list[1].text, 'Housing took 23% of your income, €460.00.');
    expect(list[2].text, 'Food is €120.00 above its usual €300.00.');
    expect(list[2].categoryId, 'food');
  });
}
