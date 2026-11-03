// Budgets through the real screens: create one, then see its state on Budgets, Home and More.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/budget_repository.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';

import 'app_harness.dart';

void main() {
  testWidgets('a Food budget made in the form shows its warning on Budgets and Home', (tester) async {
    final h = await AppHarness.create(tester);
    await h.read(
      () => EntryRepository(h.db, h.clock).addEntry(
        isExpense: true,
        accountId: h.bank,
        amountMinor: 33000,
        categoryId: 'groceries',
        title: 'Big shop',
      ),
    );
    await h.show();

    await tester.tap(find.text('More'));
    await h.settle();
    expect(find.text('Set a limit for a category'), findsOneWidget);
    await tester.tap(find.text('Budgets'));
    await h.settle();
    expect(find.text('No budgets yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New budget'));
    await h.settle();
    await tester.tap(find.text('Choose a category'));
    await h.settle();
    await tester.tap(find.text('Food').last);
    await h.settle();
    await tester.enterText(find.widgetWithText(TextField, 'Limit, EUR'), '400');
    await tester.tap(find.text('Save budget'));
    await h.settle();

    // €330 of €400 is 82%: the warning state, in words and with an icon.
    expect(find.text('At 82%'), findsOneWidget);
    expect(find.text('€330.00 of €400.00'), findsOneWidget);

    final saved = await h.read(() => h.db.select(h.db.budgets).get());
    expect(saved.single.categoryId, 'food');
    expect(saved.single.limitMinor, 40000);
    expect(saved.single.every, BudgetEvery.monthly);

    await tester.tap(find.text('Food'));
    await h.settle();
    expect(find.textContaining('a day for 3 days'), findsOneWidget, reason: '€70 left over 29 to 31 October');
    expect(find.text('Last six'), findsOneWidget);
    await tester.pageBack();
    await h.settle();
    await tester.pageBack();
    await h.settle();
    expect(find.text('1 budget, all within the limit'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await h.settle();
    expect(find.text('Food is at 82%'), findsOneWidget);
    expect(find.text('€70.00 left for 3 days'), findsOneWidget);

    await h.dispose();
  });
}
