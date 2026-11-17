// Will I make it to payday: the lowest spendable balance before the next salary, from
// today's spendable balance, the bills before payday and normal daily spending. An estimate.

import '../core/day.dart';
import 'repeat_schedule.dart';

/// How many past days set normal daily spending.
const forecastWindowDays = 92;

/// A repeat as the forecast sees it. Amounts are in EUR.
class ForecastRepeat {
  const ForecastRepeat({
    required this.title,
    required this.isIncome,
    required this.every,
    required this.nextDay,
    required this.anchorDay,
    required this.baseMinor,
    required this.onSavings,
  });

  final String title;
  final bool isIncome;
  final Every every;
  final String nextDay;
  final int anchorDay;
  final int baseMinor;

  /// Kept on a Savings account, so it never touches the spendable balance.
  final bool onSavings;
}

class ForecastBill {
  const ForecastBill({required this.title, required this.day, required this.baseMinor, required this.due});

  final String title;
  final String day;
  final int baseMinor;

  /// Already Due and not paid: counted today.
  final bool due;
}

sealed class ForecastOutcome {
  const ForecastOutcome();
}

/// No income repeat to forecast to.
class NoPayday extends ForecastOutcome {
  const NoPayday();
}

/// An income repeat is Due and not marked paid, so the next payday is not known yet.
class PaydayDue extends ForecastOutcome {
  const PaydayDue(this.title);
  final String title;
}

class PaydayForecast extends ForecastOutcome {
  const PaydayForecast({
    required this.spendableMinor,
    required this.payday,
    required this.paydayTitle,
    required this.days,
    required this.bills,
    required this.perDayMinor,
    required this.historyDays,
    required this.lowestMinor,
    required this.lowestDay,
  });

  final int spendableMinor;
  final String payday;
  final String paydayTitle;

  /// Days strictly between today and payday.
  final int days;
  final List<ForecastBill> bills;
  final int perDayMinor;

  /// The days normal daily spending was averaged over: up to [forecastWindowDays].
  final int historyDays;
  final int lowestMinor;
  final String lowestDay;

  int get billsMinor => bills.fold(0, (s, b) => s + b.baseMinor);
  int get dailyTotalMinor => perDayMinor * days;
}

/// [everydaySpendingMinor] is counted spending over the last [forecastWindowDays] days without
/// monthly and yearly repeats; [firstEntryDay] is the person's first entry, or null with none.
ForecastOutcome forecastToPayday({
  required String today,
  required int spendableMinor,
  required List<ForecastRepeat> repeats,
  required int everydaySpendingMinor,
  required String? firstEntryDay,
}) {
  int byDayThenTitle(String d1, String t1, String d2, String t2) {
    final d = d1.compareTo(d2);
    return d != 0 ? d : t1.compareTo(t2);
  }

  // A daily income repeat would make payday always tomorrow.
  final income = repeats.where((r) => r.isIncome && r.every != Every.daily).toList()
    ..sort((a, b) => byDayThenTitle(a.nextDay, a.title, b.nextDay, b.title));
  if (income.isEmpty) return const NoPayday();
  final first = income.first;
  if (isDue(first.nextDay, today)) return PaydayDue(first.title);

  final payday = first.nextDay;
  final days = Day.between(today, payday) - 1;
  final tomorrow = Day.add(today, 1);
  final beforePayday = Day.add(payday, -1);

  // Daily and weekly repeats are left to normal daily spending, so they are not counted twice.
  final bills = <ForecastBill>[];
  for (final r in repeats) {
    if (r.isIncome || r.onSavings || (r.every != Every.monthly && r.every != Every.yearly)) continue;
    var from = r.nextDay;
    if (isDue(from, today)) {
      bills.add(ForecastBill(title: r.title, day: today, baseMinor: r.baseMinor, due: true));
      from = advance(from, r.every, r.anchorDay);
    }
    for (final d in occurrences(
      nextDay: from,
      every: r.every,
      anchorDay: r.anchorDay,
      start: tomorrow,
      end: beforePayday,
    )) {
      bills.add(ForecastBill(title: r.title, day: d, baseMinor: r.baseMinor, due: false));
    }
  }
  bills.sort((a, b) => byDayThenTitle(a.day, a.title, b.day, b.title));

  final windowStart = Day.add(today, -(forecastWindowDays - 1));
  var historyDays = 0;
  if (firstEntryDay != null && firstEntryDay.compareTo(today) <= 0) {
    final from = firstEntryDay.compareTo(windowStart) > 0 ? firstEntryDay : windowStart;
    historyDays = Day.between(from, today) + 1;
  }
  final spent = everydaySpendingMinor < 0 ? 0 : everydaySpendingMinor;
  // Rounded half up to the cent.
  final perDay = historyDays == 0 ? 0 : (2 * spent + historyDays) ~/ (2 * historyDays);

  final billsMinor = bills.fold<int>(0, (s, b) => s + b.baseMinor);
  // Spending and bills only lower the balance before payday, so the last day is the lowest.
  return PaydayForecast(
    spendableMinor: spendableMinor,
    payday: payday,
    paydayTitle: first.title,
    days: days,
    bills: bills,
    perDayMinor: perDay,
    historyDays: historyDays,
    lowestMinor: spendableMinor - billsMinor - perDay * days,
    lowestDay: days > 0 ? beforePayday : today,
  );
}
