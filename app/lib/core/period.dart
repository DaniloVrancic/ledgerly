// A financial month starts on a chosen day, such as payday. The default is the 1st.

import 'day.dart';

class Period {
  const Period({required this.start, required this.end, required this.label, required this.short});

  final String start;
  final String end;

  /// "October 2026", or "28 Oct to 27 Nov" when the month starts on another day.
  final String label;

  /// "Oct", or "28 Oct".
  final String short;

  int get days => Day.between(start, end) + 1;

  bool contains(String day) => day.compareTo(start) >= 0 && day.compareTo(end) <= 0;

  /// The share of the period that has passed by [today], from 0 to 1.
  double paceOn(String today) {
    final elapsed = (Day.between(start, today) + 1).clamp(0, days);
    return elapsed / days;
  }

  @override
  bool operator ==(Object other) => other is Period && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// The financial month that contains [day].
Period periodOf(String day, {int startDay = 1}) {
  var y = Day.year(day);
  var m = Day.month(day);
  int at(int yy, int mm) => startDay.clamp(1, Day.daysInMonth(yy, mm));
  if (Day.dayOfMonth(day) < at(y, m)) {
    m -= 1;
    if (m == 0) {
      m = 12;
      y -= 1;
    }
  }
  final start = Day.ymd(y, m, at(y, m));
  final ny = m == 12 ? y + 1 : y;
  final nm = m == 12 ? 1 : m + 1;
  final end = Day.add(Day.ymd(ny, nm, at(ny, nm)), -1);
  final plain = startDay == 1;
  return Period(
    start: start,
    end: end,
    label: plain ? '${Day.monthName(m)} $y' : '${Day.short(start)} to ${Day.short(end)}',
    short: plain ? Day.shortMonth(m) : Day.short(start),
  );
}

Period previousPeriod(Period p, {int startDay = 1}) => periodOf(Day.add(p.start, -1), startDay: startDay);
Period nextPeriod(Period p, {int startDay = 1}) => periodOf(Day.add(p.end, 1), startDay: startDay);

/// The week, Monday to Sunday, that contains [day]. Weekly budgets use it.
Period weekOf(String day) {
  final start = Day.add(day, -Day.weekday(day));
  final end = Day.add(start, 6);
  return Period(
    start: start,
    end: end,
    label: '${Day.short(start)} to ${Day.short(end)}',
    short: Day.short(start),
  );
}

Period previousWeek(Period p) => weekOf(Day.add(p.start, -1));

/// The [count] periods ending with the one that contains [day], oldest first.
List<Period> lastPeriods(String day, int count, {int startDay = 1}) {
  final out = <Period>[periodOf(day, startDay: startDay)];
  while (out.length < count) {
    out.insert(0, previousPeriod(out.first, startDay: startDay));
  }
  return out;
}
