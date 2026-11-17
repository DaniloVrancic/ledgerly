import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/payday_forecast.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

void main() {
  const today = '2026-10-29';

  ForecastRepeat repeat(
    String title,
    String nextDay, {
    bool income = false,
    Every every = Every.monthly,
    int amount = 10000,
    bool onSavings = false,
  }) => ForecastRepeat(
    title: title,
    isIncome: income,
    every: every,
    nextDay: nextDay,
    anchorDay: int.parse(nextDay.substring(8)),
    baseMinor: amount,
    onSavings: onSavings,
  );

  final salary = repeat('Salary', '2026-11-01', income: true, amount: 245000);

  ForecastOutcome run(
    List<ForecastRepeat> repeats, {
    int spendable = 110226,
    int spent = 0,
    String? firstDay = '2026-01-01',
  }) => forecastToPayday(
    today: today,
    spendableMinor: spendable,
    repeats: repeats,
    everydaySpendingMinor: spent,
    firstEntryDay: firstDay,
  );

  PaydayForecast forecast(
    List<ForecastRepeat> repeats, {
    int spendable = 110226,
    int spent = 0,
    String? firstDay = '2026-01-01',
  }) => run(repeats, spendable: spendable, spent: spent, firstDay: firstDay) as PaydayForecast;

  group('payday', () {
    test('no income repeat, or only a daily one, gives no payday', () {
      expect(run(const []), isA<NoPayday>());
      expect(run([repeat('Pocket money', '2026-10-30', income: true, every: Every.daily)]), isA<NoPayday>());
    });

    test('the earliest income repeat after today is payday', () {
      final f = forecast([repeat('Bonus', '2026-12-15', income: true, every: Every.yearly), salary]);
      expect(f.payday, '2026-11-01');
      expect(f.paydayTitle, 'Salary');
      expect(f.days, 2);
    });

    test('an income repeat that is Due waits until it is marked paid', () {
      expect(run([repeat('Salary', '2026-10-28', income: true)]), isA<PaydayDue>());
      final dueToday = run([repeat('Salary', today, income: true)]);
      expect(dueToday, isA<PaydayDue>());
      expect((dueToday as PaydayDue).title, 'Salary');
    });
  });

  group('bills', () {
    test('monthly and yearly expenses before payday, a Due one counted today', () {
      final f = forecast([
        salary,
        repeat('Electricity', today, amount: 8900),
        repeat('Netflix', '2026-10-31', amount: 1299),
        repeat('Rent', '2026-11-01', amount: 46000),
        repeat('Coffee', '2026-10-30', every: Every.weekly, amount: 500),
        repeat('Savings fee', '2026-10-30', onSavings: true, amount: 200),
      ]);
      expect(f.bills.map((b) => b.title), ['Electricity', 'Netflix']);
      expect(f.billsMinor, 10199);
      expect(f.bills.first.due, isTrue);
      expect(f.bills.first.day, today);
      expect(f.bills.last.due, isFalse);
      expect(f.bills.last.day, '2026-10-31');
    });

    test('a Due bill whose next date also falls before payday counts twice', () {
      final f = forecast([
        repeat('Salary', '2026-11-05', income: true),
        repeat('Phone', '2026-09-30', amount: 2000),
      ]);
      expect(f.bills.map((b) => (b.day, b.due)), [(today, true), ('2026-10-30', false)]);
    });
  });

  group('normal daily spending', () {
    test('averaged over 92 days with a long history', () {
      expect(forecast([salary], spent: 27600).perDayMinor, 300);
      expect(forecast([salary], spent: 27600).historyDays, 92);
    });

    test('averaged over the days since the first entry when that is more recent', () {
      final f = forecast([salary], spent: 27600, firstDay: '2026-10-20');
      expect(f.historyDays, 10);
      expect(f.perDayMinor, 2760);
    });

    test('rounds half up, and is never below zero', () {
      expect(forecast([salary], spent: 1).perDayMinor, 0);
      expect(forecast([salary], spent: 46).perDayMinor, 1, reason: '46 / 92 is exactly half a cent');
      expect(forecast([salary], spent: -5000).perDayMinor, 0);
    });

    test('no entries means no history and nothing a day', () {
      final f = forecast([salary], spent: 0, firstDay: null);
      expect(f.historyDays, 0);
      expect(f.perDayMinor, 0);
    });
  });

  group('lowest', () {
    test('spendable minus bills minus daily spending, on the day before payday', () {
      final f = forecast([
        salary,
        repeat('Electricity', today, amount: 8900),
        repeat('Netflix', '2026-10-31', amount: 1299),
      ], spent: 27600);
      expect(f.lowestMinor, 110226 - 10199 - 300 * 2);
      expect(f.lowestMinor, 99427);
      expect(f.lowestDay, '2026-10-31');
      expect(f.dailyTotalMinor, 600);
    });

    test('with payday tomorrow only Due bills count, and the lowest is today', () {
      final f = forecast([
        repeat('Salary', '2026-10-30', income: true),
        repeat('Electricity', today, amount: 8900),
      ], spent: 27600);
      expect(f.days, 0);
      expect(f.lowestMinor, 110226 - 8900);
      expect(f.lowestDay, today);
    });

    test('can go below zero', () {
      final f = forecast([salary, repeat('Electricity', today, amount: 10199)], spendable: 5000);
      expect(f.lowestMinor, -5199);
    });
  });
}
