import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/period.dart';
import 'package:ledgerly/domain/budget_plan.dart';

void main() {
  final october = periodOf('2026-10-15');

  BudgetView food(int spent, {String today = '2026-10-15'}) =>
      viewBudget(limitMinor: 40000, spentMinor: spent, period: october, today: today);

  test('spent, left and share of the limit', () {
    final v = food(10000);
    expect(v.leftMinor, 30000);
    expect(v.ratio, 0.25);
    expect(v.state, BudgetState.normal);
  });

  test('safe to spend per day and the pace on the 15th of October', () {
    final v = food(20000);
    expect(v.daysLeft, 17);
    expect(v.safePerDayMinor, 1176);
    expect(v.pace, closeTo(15 / 31, 0.0001));
  });

  test('warning from exactly 80%, over from exactly 100%', () {
    expect(food(31999).state, BudgetState.normal);
    expect(food(32000).state, BudgetState.warning);
    expect(food(39999).state, BudgetState.warning);
    expect(food(40000).state, BudgetState.over);
    expect(food(41000).leftMinor, -1000);
  });

  test('nothing is safe to spend once over', () {
    expect(food(41000).safePerDayMinor, 0);
  });

  test('on the last day everything left is for today', () {
    final v = food(30000, today: '2026-10-31');
    expect(v.daysLeft, 1);
    expect(v.safePerDayMinor, 10000);
    expect(v.pace, 1);
  });

  test('a week runs Monday to Sunday', () {
    final w = weekOf('2026-10-29');
    expect(w.start, '2026-10-26');
    expect(w.end, '2026-11-01');
    expect(w.label, '26 Oct to 1 Nov');
    expect(weekOf('2026-10-26'), w);
    expect(weekOf('2026-11-01'), w);
    expect(previousWeek(w).start, '2026-10-19');
  });
}
