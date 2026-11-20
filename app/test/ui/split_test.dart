// Split payments, driven through the Add sheet and the entry details.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/domain/postings.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

import 'app_harness.dart';

void main() {
  Future<void> typeAmount(WidgetTester tester, String digits) async {
    for (final k in digits.split('')) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
  }

  Future<void> tapVisible(WidgetTester tester, AppHarness h, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await h.settle();
  }

  Future<void> choose(WidgetTester tester, AppHarness h, Finder button, String category) async {
    await tapVisible(tester, h, button);
    await tester.enterText(find.widgetWithText(TextField, 'Search categories'), category);
    await h.settle();
    await tester.tap(find.widgetWithText(ListTile, category));
    await h.settle();
  }

  Future<void> openSplit(WidgetTester tester, AppHarness h) async {
    await tester.tap(find.byTooltip('Add'));
    await h.settle();
    await typeAmount(tester, '42.50');
    await tapVisible(tester, h, find.text('More details'));
    await tapVisible(tester, h, find.text('Split across categories'));
  }

  FilledButton button(WidgetTester tester, String label) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

  testWidgets('an expense split on the Add sheet is saved as one entry with its parts', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();
    await openSplit(tester, h);

    expect(button(tester, 'Save').onPressed, isNull, reason: 'nothing is divided yet');
    await choose(tester, h, find.text('Choose a category').first, 'Groceries');
    await tester.enterText(find.widgetWithText(TextField, 'Part 1'), '30.00');
    await h.settle();
    expect(find.text('Remaining'), findsOneWidget);
    await choose(tester, h, find.text('Choose a category').first, 'Household');
    await tester.enterText(find.widgetWithText(TextField, 'Part 2'), '12.50');
    await h.settle();
    expect(find.text('Fully split'), findsOneWidget);
    await tapVisible(tester, h, find.widgetWithText(FilledButton, 'Save'));

    final entries = EntryRepository(h.db, h.clock);
    final saved = (await h.read(() => entries.watchEntries(const EntryQuery()).first)).single;
    expect(saved.isSplit, isTrue);
    expect(
      {for (final p in saved.parts) p.categoryId: p.amountMinor},
      {'groceries': -3000, 'household': -1250},
    );
    expect(saved.displayTitle, 'Split purchase');
    expect(find.textContaining('Saved €42.50, Split purchase, split across 2'), findsOneWidget);
    expect(find.text('Split across 2 categories · Main Bank'), findsOneWidget, reason: 'Home shows one row');

    await h.dispose();
  });

  testWidgets('a split never repeats, has no share and cannot be saved by a chip', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();
    await openSplit(tester, h);

    expect(find.text('A split is saved as a one-off.'), findsOneWidget);
    expect(
      tester.widget<SegmentedButton<Every?>>(find.byType(SegmentedButton<Every?>)).onSelectionChanged,
      isNull,
    );
    expect(find.text('My share, optional'), findsNothing);
    await tapVisible(tester, h, find.text('More details'));
    expect(find.text('Later'), findsNothing);
    expect(find.text('Housing'), findsNothing, reason: 'chips give way to the parts');
    expect(find.text('Choose a category for each part under More details.'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Save'),
      findsOneWidget,
      reason: 'closing More details keeps Save',
    );

    await h.dispose();
  });

  testWidgets('details show the parts, and one part makes it a simple entry again', (tester) async {
    final h = await AppHarness.create(tester);
    final entries = EntryRepository(h.db, h.clock);
    final (id, _) = await h.read(
      () => entries.addSplit(
        accountId: h.bank,
        parts: const [SplitPart('groceries', 3000), SplitPart('household', 1250)],
        title: 'Mercator',
      ),
    );
    await h.show();

    await tapVisible(tester, h, find.text('Mercator'));
    expect(find.text('Split across 2 categories'), findsOneWidget);
    expect(find.text('Food · Groceries'), findsOneWidget);
    expect(find.text('Split this'), findsNothing);
    await tapVisible(tester, h, find.text('Edit split'));
    await tester.tap(find.byTooltip('Remove part 2'));
    await h.settle();
    expect(find.text('Over by'), findsNothing);
    expect(find.text('Remaining'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Amount, EUR').last, '30.00');
    await h.settle();
    await tapVisible(tester, h, find.text('Save split'));

    final v = (await h.read(() => entries.find(id)))!;
    expect(v.isSplit, isFalse);
    expect(v.isSimple, isTrue);
    expect(v.amountMinor, -3000);
    expect(find.text('Split this'), findsOneWidget, reason: 'a simple expense can be split again');

    await h.dispose();
  });
}
