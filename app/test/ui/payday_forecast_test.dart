// The payday forecast on Home: hidden without a salary, waiting while it is due, and otherwise
// the lowest before payday with its calculation one tap away, kept live as entries change.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/data/repositories/repeat_repository.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

import 'app_harness.dart';

void main() {
  Future<String> salary(AppHarness h, String nextDay) => h.read(
    () => RepeatRepository(h.db, h.clock, EntryRepository(h.db, h.clock)).create(
      title: 'Salary',
      kind: 'income',
      categoryId: 'salary',
      accountId: h.bank,
      amountMinor: 245000,
      every: Every.monthly,
      nextDay: nextDay,
    ),
  );

  Future<void> electricity(AppHarness h) => h.read(
    () => RepeatRepository(h.db, h.clock, EntryRepository(h.db, h.clock)).create(
      title: 'Electricity',
      kind: 'expense',
      categoryId: 'electricity',
      accountId: h.bank,
      amountMinor: 8900,
      every: Every.monthly,
      nextDay: '2026-10-29',
    ),
  );

  Future<void> groceries(AppHarness h, int amount) => h.read(
    () => EntryRepository(
      h.db,
      h.clock,
    ).addEntry(isExpense: true, accountId: h.bank, amountMinor: amount, categoryId: 'groceries'),
  );

  testWidgets('without an income repeat there is no forecast', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();
    expect(find.text('Lowest before payday'), findsNothing);
    await h.dispose();
  });

  testWidgets('the lowest before payday, its calculation, and live updates', (tester) async {
    final h = await AppHarness.create(tester);
    await salary(h, '2026-11-01');
    await electricity(h);
    await groceries(h, 9000);
    await h.show();

    // Spendable: Bank 1,000.00 + Cash 200 KM (€102.26) − €90 groceries = €1,012.26.
    // One day of history, so €90.00 a day, for 30 and 31 Oct.
    // Lowest: 1,012.26 − 89.00 Electricity (Due) − 90.00 × 2 = €743.26.
    expect(find.text('Lowest before payday'), findsOneWidget);
    expect(find.text('Estimate'), findsOneWidget);
    expect(find.text('€743.26'), findsOneWidget);
    expect(find.text('Around 31 Oct, after €89.00 of bills. Salary on 1 Nov.'), findsOneWidget);

    await tester.tap(find.text('Lowest before payday'));
    await h.settle();
    expect(find.text('How this estimate works'), findsOneWidget);
    expect(find.text('Spendable today'), findsOneWidget);
    expect(find.text('Normal daily spending, €90.00 × 2 days'), findsOneWidget);
    expect(find.text('Lowest, around 31 Oct'), findsOneWidget);
    expect(find.text('Due · Electricity'), findsOneWidget);
    expect(find.textContaining('average over the last day'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Close'));
    await h.settle();
    expect(find.text('How this estimate works'), findsNothing);

    // €50 more today: spendable €962.26, €140.00 a day, lowest 962.26 − 89.00 − 280.00.
    await groceries(h, 5000);
    await h.settle();
    expect(find.text('€593.26'), findsOneWidget);

    await h.dispose();
  });

  testWidgets('a salary that is due waits until it is marked paid', (tester) async {
    final h = await AppHarness.create(tester);
    await salary(h, '2026-10-28');
    await h.show();

    expect(find.text('Salary is due. Mark it paid to see the forecast.'), findsOneWidget);
    expect(find.text('Estimate'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Mark paid'));
    await h.settle();
    expect(find.text('Estimate'), findsOneWidget);
    expect(find.textContaining('Salary on 28 Nov.'), findsOneWidget);

    await h.dispose();
  });
}
