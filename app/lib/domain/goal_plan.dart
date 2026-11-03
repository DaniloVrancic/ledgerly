// Planning a savings goal. Money set aside for a goal stays in its account, but it is no longer
// free to use. The plan answers: how far along am I, how much per month do I need, and when
// will I get there at my current pace.

import '../core/day.dart';

class GoalPlan {
  const GoalPlan({
    required this.savedMinor,
    required this.targetMinor,
    required this.leftMinor,
    required this.progress,
    required this.monthsLeft,
    required this.perMonthNeededMinor,
    required this.averagePerMonthMinor,
    required this.projectedDay,
    required this.status,
  });

  final int savedMinor;
  final int targetMinor;
  final int leftMinor;

  /// From 0 to 1.
  final double progress;

  /// Whole months until the target date, at least 1. Null without a target date.
  final int? monthsLeft;

  /// What to set aside each month to reach the target on time. Null without a target date.
  final int? perMonthNeededMinor;

  /// The average set aside per month over the last three months.
  final int averagePerMonthMinor;

  /// When the goal is reached at the average pace. Null when nothing has been set aside lately.
  final String? projectedDay;

  final GoalStatus status;
}

enum GoalStatus {
  reached('Reached'),
  onTrack('On track'),
  behind('Behind'),
  noDeadline('No deadline'),
  overdue('Past its date');

  const GoalStatus(this.label);
  final String label;
}

class GoalMoveInput {
  const GoalMoveInput(this.day, this.amountMinor);
  final String day;
  final int amountMinor;
}

GoalPlan planGoal({
  required int targetMinor,
  required String? targetDay,
  required List<GoalMoveInput> moves,
  required String today,
}) {
  final saved = moves.fold<int>(0, (s, m) => s + m.amountMinor);
  final left = (targetMinor - saved).clamp(0, targetMinor);
  final progress = targetMinor <= 0 ? 1.0 : (saved / targetMinor).clamp(0.0, 1.0);

  final since = Day.add(today, -90);
  final recent = moves.where((m) => m.day.compareTo(since) > 0).fold<int>(0, (s, m) => s + m.amountMinor);
  final average = (recent / 3).round();

  int? months;
  int? perMonth;
  if (targetDay != null) {
    months = _monthsBetween(today, targetDay).clamp(1, 1200);
    perMonth = left == 0 ? 0 : (left / months).ceil();
  }

  String? projected;
  if (left > 0 && average > 0) {
    final monthsToGo = (left / average).ceil();
    projected = _addMonths(today, monthsToGo);
  }

  final GoalStatus status;
  if (left == 0) {
    status = GoalStatus.reached;
  } else if (targetDay == null) {
    status = GoalStatus.noDeadline;
  } else if (targetDay.compareTo(today) < 0) {
    status = GoalStatus.overdue;
  } else if (projected != null && projected.compareTo(targetDay) <= 0) {
    status = GoalStatus.onTrack;
  } else {
    status = GoalStatus.behind;
  }

  return GoalPlan(
    savedMinor: saved,
    targetMinor: targetMinor,
    leftMinor: left,
    progress: progress,
    monthsLeft: months,
    perMonthNeededMinor: perMonth,
    averagePerMonthMinor: average,
    projectedDay: projected,
    status: status,
  );
}

int _monthsBetween(String from, String to) {
  final months = (Day.year(to) - Day.year(from)) * 12 + Day.month(to) - Day.month(from);
  return Day.dayOfMonth(to) >= Day.dayOfMonth(from) ? months : months - 1;
}

String _addMonths(String day, int months) {
  final total = Day.month(day) - 1 + months;
  final y = Day.year(day) + total ~/ 12;
  final m = total % 12 + 1;
  return Day.ymd(y, m, Day.dayOfMonth(day).clamp(1, Day.daysInMonth(y, m)));
}
