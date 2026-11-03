import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/goal_plan.dart';

void main() {
  test('progress and what is left', () {
    final plan = planGoal(targetMinor: 150000, targetDay: null, moves: const [GoalMoveInput('2026-09-01', 50000)], today: '2026-11-01');
    expect(plan.savedMinor, 50000);
    expect(plan.leftMinor, 100000);
    expect(plan.progress, closeTo(1 / 3, 0.001));
    expect(plan.status, GoalStatus.noDeadline);
  });

  test('what to set aside each month to reach the date', () {
    final plan = planGoal(targetMinor: 120000, targetDay: '2027-05-01', moves: const [], today: '2026-11-01');
    expect(plan.monthsLeft, 6);
    expect(plan.perMonthNeededMinor, 20000);
    expect(plan.status, GoalStatus.behind);
  });

  test('on track when the recent pace reaches the date in time', () {
    final moves = [for (final d in ['2026-08-15', '2026-09-15', '2026-10-15']) GoalMoveInput(d, 30000)];
    final plan = planGoal(targetMinor: 180000, targetDay: '2027-06-01', moves: moves, today: '2026-11-01');
    expect(plan.averagePerMonthMinor, 30000);
    expect(plan.projectedDay, '2027-02-01', reason: '90,000 left at 30,000 a month is 3 months');
    expect(plan.status, GoalStatus.onTrack);
  });

  test('taking money out counts against the goal', () {
    final plan = planGoal(targetMinor: 10000, targetDay: null, moves: const [GoalMoveInput('2026-10-01', 8000), GoalMoveInput('2026-10-20', -3000)], today: '2026-11-01');
    expect(plan.savedMinor, 5000);
  });

  test('reached', () {
    final plan = planGoal(targetMinor: 10000, targetDay: '2026-12-01', moves: const [GoalMoveInput('2026-10-01', 10000)], today: '2026-11-01');
    expect(plan.status, GoalStatus.reached);
    expect(plan.leftMinor, 0);
    expect(plan.perMonthNeededMinor, 0);
  });

  test('past its date', () {
    final plan = planGoal(targetMinor: 10000, targetDay: '2026-10-01', moves: const [], today: '2026-11-01');
    expect(plan.status, GoalStatus.overdue);
  });
}
