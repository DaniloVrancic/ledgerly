// How a budget stands in its period: what is spent and left, how far the period has gone,
// and how much can still be spent each day without going over.

import '../core/day.dart';
import '../core/period.dart';

/// Warning from 80% of the limit, over from 100%.
enum BudgetState { normal, warning, over }

class BudgetView {
  const BudgetView({
    required this.limitMinor,
    required this.spentMinor,
    required this.period,
    required this.pace,
    required this.daysLeft,
  });

  /// In EUR minor units.
  final int limitMinor;

  /// Expenses minus refunds in the period, in EUR minor units.
  final int spentMinor;
  final Period period;

  /// The share of the period that has passed, from 0 to 1. Shown as a marker on the bar.
  final double pace;

  /// Days from today to the end of the period, today included. At least 1.
  final int daysLeft;

  /// Negative when over the limit.
  int get leftMinor => limitMinor - spentMinor;

  double get ratio => spentMinor / limitMinor;

  BudgetState get state => spentMinor >= limitMinor
      ? BudgetState.over
      : spentMinor * 5 >= limitMinor * 4
      ? BudgetState.warning
      : BudgetState.normal;

  /// What is left divided by the days left, rounded half up to the cent. Zero once over.
  int get safePerDayMinor {
    final left = leftMinor < 0 ? 0 : leftMinor;
    return (2 * left + daysLeft) ~/ (2 * daysLeft);
  }
}

/// A budget of [limitMinor] with [spentMinor] spent so far in [period], seen on [today].
BudgetView viewBudget({
  required int limitMinor,
  required int spentMinor,
  required Period period,
  required String today,
}) {
  final left = Day.between(today, period.end) + 1;
  return BudgetView(
    limitMinor: limitMinor,
    spentMinor: spentMinor,
    period: period,
    pace: period.paceOn(today),
    daysLeft: left.clamp(1, period.days),
  );
}
