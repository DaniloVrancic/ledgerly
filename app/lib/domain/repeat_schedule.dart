// Repeats: a title the person chose, how often, and the next date. Nothing posts by itself:
// a repeat turns Due on its date and waits until it is marked paid or skipped.

import '../core/day.dart';

enum Every {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const Every(this.label);
  final String label;

  /// How many times it happens in an average month, for monthly totals.
  double get perMonth => switch (this) {
    Every.daily => 365 / 12,
    Every.weekly => 52 / 12,
    Every.monthly => 1,
    Every.yearly => 1 / 12,
  };

  static Every parse(String name) => Every.values.byName(name);
}

/// The date after [day]. Monthly and yearly keep [anchorDay], so the 31st becomes the 30th
/// in a short month and returns to the 31st after it.
String advance(String day, Every every, int anchorDay) {
  switch (every) {
    case Every.daily:
      return Day.add(day, 1);
    case Every.weekly:
      return Day.add(day, 7);
    case Every.monthly:
    case Every.yearly:
      var y = Day.year(day);
      var m = Day.month(day);
      if (every == Every.yearly) {
        y += 1;
      } else {
        m += 1;
        if (m > 12) {
          m = 1;
          y += 1;
        }
      }
      return Day.ymd(y, m, anchorDay.clamp(1, Day.daysInMonth(y, m)));
  }
}

bool isDue(String nextDay, String today) => nextDay.compareTo(today) <= 0;

/// Every date a repeat falls on from [nextDay] to [end], skipping those before [start].
List<String> occurrences({
  required String nextDay,
  required Every every,
  required int anchorDay,
  required String start,
  required String end,
  int limit = 400,
}) {
  final out = <String>[];
  var d = nextDay;
  for (var i = 0; d.compareTo(end) <= 0 && i < limit; i++) {
    if (d.compareTo(start) >= 0) out.add(d);
    d = advance(d, every, anchorDay);
  }
  return out;
}

/// "Every day", "Every Friday", "Monthly, on the 5th", "Yearly, on 20 Apr".
String describeEvery(Every every, String nextDay, int anchorDay) {
  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return switch (every) {
    Every.daily => 'Every day',
    Every.weekly => 'Every ${weekdays[Day.weekday(nextDay)]}',
    Every.monthly => 'Monthly, on the ${ordinal(anchorDay)}',
    Every.yearly => 'Yearly, on ${Day.short(nextDay)}',
  };
}

String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}
