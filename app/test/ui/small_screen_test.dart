// The main screens on a small phone (360 x 640) at normal and large text, with real data in
// them. Every layout overflow is collected, so one run lists all of them.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/budget_repository.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/data/repositories/repeat_repository.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

import 'app_harness.dart';

Future<void> fillLedger(AppHarness h) async {
  final entries = EntryRepository(h.db, h.clock);
  await h.read(
    () => entries.addEntry(
      isExpense: false,
      accountId: h.bank,
      amountMinor: 245000,
      categoryId: 'salary',
      title: 'Salary for October with a long title',
      day: '2026-10-28',
    ),
  );
  for (final (cat, amount, title) in [
    ('groceries', 33000, 'Weekly shopping at the big supermarket'),
    ('dining', 4250, 'Dinner'),
    ('transit', 160, 'Bus'),
    ('rent', 46000, 'Rent'),
  ]) {
    await h.read(
      () => entries.addEntry(
        isExpense: true,
        accountId: h.bank,
        amountMinor: amount,
        categoryId: cat,
        title: title,
      ),
    );
  }
  await h.read(() => entries.addLater(accountId: h.cash, amountMinor: 1200));
  await h.read(
    () => BudgetRepository(
      h.db,
      h.clock,
    ).create(categoryId: 'food', limitMinor: 40000, every: BudgetEvery.monthly),
  );
  await h.read(
    () => RepeatRepository(h.db, h.clock, entries).create(
      title: 'Electricity and heating',
      kind: 'expense',
      categoryId: 'electricity',
      accountId: h.bank,
      amountMinor: 8900,
      every: Every.monthly,
      nextDay: '2026-10-29',
    ),
  );
  // So Home shows the payday forecast card.
  await h.read(
    () => RepeatRepository(h.db, h.clock, entries).create(
      title: 'Salary',
      kind: 'income',
      categoryId: 'salary',
      accountId: h.bank,
      amountMinor: 245000,
      every: Every.monthly,
      nextDay: '2026-11-01',
    ),
  );
}

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('no overflow on a 360 x 640 phone at ${(scale * 100).round()}% text', (tester) async {
      final problems = <String>[];
      final semantics = tester.ensureSemantics();
      final h = await AppHarness.create(tester);
      await fillLedger(h);
      await h.show();
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final original = FlutterError.onError;
      var where = 'Home';
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed')) {
          final at = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(details.toString())?.group(0) ?? '';
          problems.add('$where: ${text.split('\n').first} $at');
        } else {
          original?.call(details);
        }
      };

      // Scrolls [target] a third of the way down the screen, clear of the Add button, then taps it.
      Future<void> tapRevealed(Finder target) async {
        await Scrollable.ensureVisible(tester.element(target), alignment: 0.3);
        await h.settle();
        await tester.tap(target);
      }

      Future<void> visit(String name, Future<void> Function() go) async {
        where = name;
        await go();
        await h.settle();
      }

      await visit('Home', () async => tester.pump());
      await visit('Entries', () => tester.tap(find.text('Entries').last));
      await visit('Calendar', () => tester.tap(find.text('Calendar')));
      await visit('Day sheet', () async {
        final day = find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.label?.startsWith('29 Oct 2026') ?? false),
        );
        await tapRevealed(day);
      });
      await visit(
        'Close sheet',
        () async => Navigator.of(tester.element(find.text('Add on this day'))).pop(),
      );
      await visit('Calendar year', () => tapRevealed(find.text('Year')));
      await visit('Insights', () => tester.tap(find.text('Insights').last));
      await visit('More', () => tester.tap(find.text('More').last));
      await visit('Budgets', () => tapRevealed(find.text('Budgets')));
      await visit('Budget details', () => tapRevealed(find.text('Food')));
      await visit('Back', () => tester.pageBack());
      await visit('Back', () => tester.pageBack());
      await visit('Repeats', () => tapRevealed(find.text('Repeats')));
      await visit('Back', () => tester.pageBack());
      await visit('Settings', () async {
        await tester.scrollUntilVisible(find.text('Settings'), 200, scrollable: find.byType(Scrollable).last);
        await tapRevealed(find.text('Settings'));
      });
      await visit('Back', () => tester.pageBack());
      await visit('Add sheet', () => tester.tap(find.byTooltip('Add')));
      await visit('Add sheet with amount', () async {
        await tapRevealed(find.text('4').last);
        await tapRevealed(find.text('2').last);
      });

      await h.dispose();
      semantics.dispose();
      // Restored before any expect, as the test binding checks for it.
      FlutterError.onError = original;
      expect(problems, isEmpty, reason: problems.toSet().join('\n'));
    });
  }
}
