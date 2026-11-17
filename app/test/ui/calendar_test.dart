// The calendar through the real screens: open a day, add an entry dated that day, and use the
// year view to jump to a month.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';

import 'app_harness.dart';

void main() {
  testWidgets('a day opens its entries, and Add on this day dates the new entry', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await AppHarness.create(tester);
    final entries = EntryRepository(h.db, h.clock);
    await h.read(
      () => entries.addEntry(
        isExpense: true,
        accountId: h.bank,
        amountMinor: 3000,
        categoryId: 'groceries',
        title: 'Bread',
        day: '2026-10-28',
      ),
    );
    await h.show();

    await tester.tap(find.text('Entries'));
    await h.settle();
    await tester.tap(find.text('Calendar'));
    await h.settle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Less to more spent'), findsOneWidget, reason: 'the legend explains the shade');

    await tester.tap(find.bySemanticsLabel(RegExp(r'^28 Oct 2026: spent €30\.00')));
    await h.settle();
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('Most went to Food.'), findsOneWidget);

    await tester.tap(find.text('Add on this day'));
    await h.settle();
    await tester.tap(find.text('5').last);
    await tester.pump();
    await tester.tap(find.text('Housing').last);
    await h.settle();

    final saved = await h.read(
      () => entries.watchEntries(const EntryQuery(start: '2026-10-28', end: '2026-10-28')).first,
    );
    expect(saved.map((e) => e.amountMinor), containsAll([-3000, -500]));

    await tester.tap(find.text('Year'));
    await h.settle();
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Dec'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^March 2026')));
    await h.settle();
    expect(find.text('March 2026'), findsOneWidget);

    await h.dispose();
    semantics.dispose();
  });
}
