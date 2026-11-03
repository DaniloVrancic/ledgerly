import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/calendar_month.dart';

void main() {
  test('a month grid is full weeks starting on Monday', () {
    // 1 February 2026 is a Sunday, and the 28th a Saturday.
    final feb = monthGrid(2026, 2);
    expect(feb.first, '2026-01-26');
    expect(feb.last, '2026-03-01');
    expect(feb.length, 35);

    final nov = monthGrid(2026, 11);
    expect(nov.first, '2026-10-26');
    expect(nov.last, '2026-12-06');
    expect(nov.length, 42);
  });

  test('a month that starts on Monday and ends on Sunday needs no filler', () {
    // June 2026 runs Monday the 1st to Tuesday the 30th; March 2027 starts on a Monday.
    expect(monthGrid(2027, 3).first, '2027-03-01');
    expect(monthGrid(2026, 6).first, '2026-06-01');
  });

  test('the year is split into Monday weeks with days outside it left empty', () {
    final weeks = yearWeeks(2026);
    expect(weeks.first, [null, null, null, '2026-01-01', '2026-01-02', '2026-01-03', '2026-01-04']);
    expect(weeks.last.first, '2026-12-28');
    expect(weeks.last.last, null, reason: '3 January 2027 is outside the year');
    expect(weeks.expand((w) => w).whereType<String>().length, 365);
  });

  test('heat steps follow the month and leave days without spending unshaded', () {
    const month = [0, 100, 200, 300, 400];
    expect(heatStep(0, month), 0);
    expect(heatStep(100, month), 1);
    expect(heatStep(200, month), 2);
    expect(heatStep(300, month), 3);
    expect(heatStep(400, month), 4);
    expect(heatStep(500, const [0, 0, 500]), 2, reason: 'a single spending day has nothing to compare with');
    expect(heatStep(0, const []), 0);
  });

  test('a high-spending day is in the top step and at least twice the usual day', () {
    expect(isHighSpending(500, const [100, 100, 100, 500]), isTrue);
    expect(isHighSpending(400, const [100, 200, 300, 400]), isFalse);
    expect(isHighSpending(900, const [900]), isFalse, reason: 'too few days to call one high');
  });
}
