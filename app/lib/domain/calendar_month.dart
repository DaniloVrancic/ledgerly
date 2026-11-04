// The financial calendar's arithmetic: which days a month grid shows, and how strongly a day
// is shaded. A shade is always relative to the month and always shown with its number.

import '../core/day.dart';

/// Full weeks, Monday first, covering [month] of [year]. Days of the months around it fill
/// the first and last week.
List<String> monthGrid(int year, int month) {
  final first = Day.ymd(year, month, 1);
  final last = Day.ymd(year, month, Day.daysInMonth(year, month));
  final start = Day.add(first, -Day.weekday(first));
  final end = Day.add(last, 6 - Day.weekday(last));
  return [for (var i = 0; i <= Day.between(start, end); i++) Day.add(start, i)];
}

/// Every week of [year], Monday first, as 7 days each. Days outside the year are null.
List<List<String?>> yearWeeks(int year) {
  final first = Day.ymd(year, 1, 1);
  var day = Day.add(first, -Day.weekday(first));
  final weeks = <List<String?>>[];
  while (Day.year(day) <= year) {
    weeks.add([
      for (var i = 0; i < 7; i++)
        if (Day.year(Day.add(day, i)) == year) Day.add(day, i) else null,
    ]);
    day = Day.add(day, 7);
  }
  return weeks;
}

/// 0 for no spending, then 1 to 4 by the day's quartile among the month's spending days:
/// the share of spending days that spent as much or less, in quarters. With a single
/// spending day there is nothing to compare with, so it gets a middle step.
int heatStep(int spentMinor, List<int> monthSpends) {
  if (spentMinor <= 0) return 0;
  final days = monthSpends.where((s) => s > 0).toList();
  if (days.length < 2) return 2;
  final rank = days.where((s) => s <= spentMinor).length / days.length;
  return (rank * 4).ceil().clamp(1, 4);
}

/// A day that stands out: in the top shade and at least twice the month's median day.
bool isHighSpending(int spentMinor, List<int> monthSpends) {
  final days = monthSpends.where((s) => s > 0).toList()..sort();
  if (days.length < 3) return false;
  final median = days[days.length ~/ 2];
  return heatStep(spentMinor, monthSpends) == 4 && spentMinor >= 2 * median;
}
