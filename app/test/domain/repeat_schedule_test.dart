import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

void main() {
  test('daily, weekly and yearly steps', () {
    expect(advance('2026-10-29', Every.daily, 29), '2026-10-30');
    expect(advance('2026-10-29', Every.weekly, 29), '2026-11-05');
    expect(advance('2026-04-20', Every.yearly, 20), '2027-04-20');
  });

  test('monthly keeps its day through short months', () {
    var d = '2026-01-31';
    final seen = <String>[];
    for (var i = 0; i < 3; i++) {
      d = advance(d, Every.monthly, 31);
      seen.add(d);
    }
    expect(seen, ['2026-02-28', '2026-03-31', '2026-04-30']);
  });

  test('a repeat is due on and after its date', () {
    expect(isDue('2026-10-25', '2026-10-29'), isTrue);
    expect(isDue('2026-10-29', '2026-10-29'), isTrue);
    expect(isDue('2026-10-30', '2026-10-29'), isFalse);
  });

  test('occurrences in a range', () {
    final days = occurrences(nextDay: '2026-11-05', every: Every.weekly, anchorDay: 5, start: '2026-11-01', end: '2026-11-30');
    expect(days, ['2026-11-05', '2026-11-12', '2026-11-19', '2026-11-26']);
  });

  test('descriptions', () {
    expect(describeEvery(Every.monthly, '2026-11-01', 1), 'Monthly, on the 1st');
    expect(describeEvery(Every.weekly, '2026-10-30', 30), 'Every Friday');
    expect(ordinal(12), '12th');
    expect(ordinal(22), '22nd');
  });
}
