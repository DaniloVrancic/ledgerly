// The everyday flows, driven through the real screens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/data/repositories/repeat_repository.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';

import 'app_harness.dart';

void main() {
  testWidgets('an expense is Add, the digits and one chip, and its title is remembered', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();

    await tester.tap(find.byTooltip('Add'));
    await h.settle();
    // Chips wait for an amount.
    for (final k in ['1', '2']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    expect(find.text('€12.00'), findsOneWidget);
    await tester.tap(find.text('Housing').last);
    await h.settle();

    final entries = EntryRepository(h.db, h.clock);
    final saved = await h.read(() => entries.watchEntries(const EntryQuery()).first);
    expect(saved.single.amountMinor, -1200);
    expect(saved.single.displayTitle, 'Housing', reason: 'with no title, the subcategory name is used');
    expect(find.textContaining('Saved €12.00, Housing'), findsOneWidget);
    expect(await h.read(() => AccountRepository(h.db, h.clock).balanceOf(h.bank)), 98800);

    await h.dispose();
  });

  testWidgets('a typed title brings back its category, and Save confirms it', (tester) async {
    final h = await AppHarness.create(tester);
    final entries = EntryRepository(h.db, h.clock);
    await h.read(
      () => entries.addEntry(
        isExpense: true,
        accountId: h.cash,
        amountMinor: 400,
        categoryId: 'coffee',
        title: 'Coffee',
      ),
    );
    await h.show();

    await tester.tap(find.byTooltip('Add'));
    await h.settle();
    await tester.enterText(find.byType(TextField).first, 'coffee');
    await h.settle();
    expect(find.text('Save'), findsOneWidget, reason: 'a remembered title asks for Save');
    await tester.tap(find.text('4').last);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await h.settle();

    final list = await h.read(() => entries.watchEntries(const EntryQuery()).first);
    expect(list.first.categoryId, 'coffee');
    expect(list.first.accountId, h.cash);
    expect(list.first.amountMinor, -400);

    await h.dispose();
  });

  testWidgets('a due repeat is marked paid from Home with one tap', (tester) async {
    final h = await AppHarness.create(tester);
    final repeats = RepeatRepository(h.db, h.clock, EntryRepository(h.db, h.clock));
    final id = await h.read(
      () => repeats.create(
        title: 'Phone bill',
        kind: 'expense',
        categoryId: 'mobile',
        accountId: h.bank,
        amountMinor: 3500,
        every: Every.monthly,
        nextDay: '2026-10-25',
      ),
    );
    await h.show();

    expect(find.text('Phone bill'), findsOneWidget);
    expect(find.text('Due since 25 Oct, €35.00'), findsOneWidget);
    await tester.tap(find.text('Mark paid'));
    await h.settle();

    expect((await h.read(() => repeats.find(id)))!.nextDay, '2026-11-25');
    expect(find.text('Due since 25 Oct, €35.00'), findsNothing);
    expect(await h.read(() => AccountRepository(h.db, h.clock).balanceOf(h.bank)), 96500);

    await h.dispose();
  });

  testWidgets('a custom category is made in Categories and offered for its account', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();

    await tester.tap(find.text('More'));
    await h.settle();
    await tester.tap(find.text('Categories'));
    await h.settle();
    await tester.tap(find.text('New category'));
    await h.settle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Čišćenje');
    await tester.pump();
    await tester.ensureVisible(find.text('Save category'));
    await tester.tap(find.text('Save category'));
    await h.settle();

    final all = await h.read(() => CategoryRepository(h.db, h.clock).all());
    final made = all.where((c) => c.name == 'Čišćenje').single;
    expect(made.isCustom, isTrue);
    expect(find.text('Čišćenje'), findsWidgets);

    await h.dispose();
  });
}
