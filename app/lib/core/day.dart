// A day is a local calendar date stored as "YYYY-MM-DD". Entries keep their day even when
// the phone changes time zone, and the text sorts correctly in the database.

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int n) => n.toString().padLeft(2, '0');

abstract final class Day {
  static String of(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';
  static String ymd(int y, int m, int d) => '$y-${_two(m)}-${_two(d)}';
  static DateTime parse(String day) => DateTime.utc(year(day), month(day), dayOfMonth(day));

  static int year(String day) => int.parse(day.substring(0, 4));
  static int month(String day) => int.parse(day.substring(5, 7));
  static int dayOfMonth(String day) => int.parse(day.substring(8, 10));

  static String add(String day, int days) => of(parse(day).add(Duration(days: days)));
  static int between(String from, String to) => parse(to).difference(parse(from)).inDays;
  static int daysInMonth(int y, int m) => DateTime.utc(y, m + 1, 0).day;

  /// Monday is 0, Sunday is 6.
  static int weekday(String day) => parse(day).weekday - 1;

  static String monthName(int m) => _months[m - 1];
  static String shortMonth(int m) => _months[m - 1].substring(0, 3);

  /// "29 Oct".
  static String short(String day) => '${dayOfMonth(day)} ${shortMonth(month(day))}';

  /// "29 Oct 2026".
  static String long(String day) => '${short(day)} ${year(day)}';

  /// "Today", "Yesterday", "Tue, 27 Oct", or with the year when it is not this year.
  static String label(String day, String today) {
    if (day == today) return 'Today';
    if (day == add(today, -1)) return 'Yesterday';
    final base = '${_weekdays[weekday(day)]}, ${short(day)}';
    return year(day) == year(today) ? base : '$base ${year(day)}';
  }
}
