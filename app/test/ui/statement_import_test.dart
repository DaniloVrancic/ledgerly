// The statement import through the real screens, with a file handed over in place of the
// system picker.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/files.dart';
import 'package:ledgerly/app/navigation.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/features/statement_import/statement_import_screen.dart';

import 'app_harness.dart';

const statement =
    'Datum;Opis;Iznos\n'
    '01.10.2026;KONZUM;-45,20\n'
    '03.10.2026;Plata;2.000,00\n'
    '04.10.2026;Bus;-1,60\n'
    '04.10.2026;Bus;-1,60\n'
    'x;broken;\n';

void main() {
  testWidgets('matched, to add, duplicates and unreadable rows; only ticked rows are added', (tester) async {
    final h = await AppHarness.create(tester);
    final entries = EntryRepository(h.db, h.clock);
    await h.read(
      () => entries.addEntry(
        isExpense: true,
        accountId: h.bank,
        amountMinor: 4520,
        categoryId: 'groceries',
        day: '2026-10-02',
      ),
    );
    await h.show();

    rootNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderScope(
          overrides: [
            pickFileProvider.overrideWithValue(
              (_) async => (name: 'october.csv', bytes: Uint8List.fromList(utf8.encode(statement))),
            ),
          ],
          child: const StatementImportScreen(),
        ),
      ),
    );
    await h.settle();
    await tester.tap(find.text('Choose a CSV file'));
    await h.settle();

    expect(find.text('Check the columns'), findsOneWidget);
    expect(find.text('october.csv · 5 rows'), findsOneWidget);
    expect(find.text('KONZUM'), findsOneWidget, reason: 'the preview reads the guessed columns');
    await tester.scrollUntilVisible(find.text('Compare with my entries'), 300);
    await tester.tap(find.text('Compare with my entries'));
    await h.settle();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Income needs a category'), findsOneWidget);
    expect(find.text('Likely duplicates'), findsWidgets);
    // Income waits for a category and the duplicate is unticked, so one row is to be added.
    await tester.scrollUntilVisible(find.text('Add 1 entry'), 300);
    expect(find.text('Line 6: No date'), findsOneWidget);
    await tester.tap(find.text('Add 1 entry'));
    await h.settle();

    final all = await h.read(() => entries.watchEntries(const EntryQuery()).first);
    expect(all, hasLength(2));
    final bus = all.firstWhere((e) => e.displayTitle == 'Bus');
    expect(bus.amountMinor, -160);
    expect(bus.day, '2026-10-04');
    expect(bus.needsReview, isTrue);
    expect(find.text('Added 1 entry'), findsOneWidget);

    await h.dispose();
  });
}
