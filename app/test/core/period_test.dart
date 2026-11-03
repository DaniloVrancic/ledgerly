import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/day.dart';
import 'package:ledgerly/core/period.dart';

void main() {
  test('a month starting on the 1st is the calendar month', () {
    final p = periodOf('2026-10-29');
    expect(p.start, '2026-10-01');
    expect(p.end, '2026-10-31');
    expect(p.label, 'October 2026');
    expect(p.days, 31);
  });

  test('a month can start on payday', () {
    final p = periodOf('2026-11-03', startDay: 28);
    expect(p.start, '2026-10-28');
    expect(p.end, '2026-11-27');
    expect(p.label, '28 Oct to 27 Nov');
  });

  test('a start day past the end of a short month uses its last day', () {
    final p = periodOf('2026-02-15', startDay: 31);
    expect(p.start, '2026-01-31');
    expect(p.end, '2026-02-27');
  });

  test('periods follow each other without gaps', () {
    final p = periodOf('2026-01-10', startDay: 28);
    final prev = previousPeriod(p, startDay: 28);
    expect(Day.add(prev.end, 1), p.start);
    expect(lastPeriods('2026-10-29', 3).map((x) => x.short), ['Aug', 'Sep', 'Oct']);
  });

  test('pace is the share of the period that has passed', () {
    final p = periodOf('2026-10-01');
    expect(p.paceOn('2026-10-31'), 1);
    expect(p.paceOn('2026-09-30'), 0);
  });

  test('day labels', () {
    expect(Day.label('2026-10-29', '2026-10-29'), 'Today');
    expect(Day.label('2026-10-28', '2026-10-29'), 'Yesterday');
    expect(Day.label('2026-10-27', '2026-10-29'), 'Tue, 27 Oct');
    expect(Day.label('2025-10-27', '2026-10-29'), 'Mon, 27 Oct 2025');
  });
}
