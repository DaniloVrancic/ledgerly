// Export and import through the real screens: a password-protected export is checked and
// saved, then opened again, with a wrong password first, and confirmed with REPLACE.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/export/ledgerly_file.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';

import 'app_harness.dart';

/// Opens More, then Settings, then the row with [title].
Future<void> openSettingsRow(AppHarness h, String title) async {
  final tester = h.tester;
  await tester.tap(find.text('More').last);
  await h.settle();
  await tester.tap(find.text('Settings'));
  await h.settle();
  await tester.scrollUntilVisible(find.text(title), 300, scrollable: find.byType(Scrollable).last);
  await tester.ensureVisible(find.text(title));
  await h.settle();
  await tester.tap(find.text(title));
  await h.settle();
}

void main() {
  testWidgets('export with a password, then import it back after REPLACE', (tester) async {
    final h = await AppHarness.create(tester);
    await h.read(
      () => EntryRepository(h.db, h.clock).addEntry(
        isExpense: true,
        accountId: h.bank,
        amountMinor: 1250,
        categoryId: 'groceries',
        title: 'Bread',
      ),
    );
    await h.show();

    await openSettingsRow(h, 'Export all data');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'ledgerly-pass');
    await tester.enterText(find.widgetWithText(TextField, 'The same password again'), 'ledgerly-pass');
    await tester.tap(find.text('Export'));
    await h.settle();

    final bytes = h.saved['ledgerly-20261029.ledgerly'];
    expect(bytes, isNotNull);
    expect(isEncryptedLedgerly(bytes!), isTrue);
    await tester.scrollUntilVisible(
      find.textContaining('verified'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('1 entries, 2 accounts'), findsOneWidget);
    expect(find.textContaining('protected with a password'), findsOneWidget);

    await tester.pageBack();
    await h.settle();
    await tester.pageBack();
    await h.settle();

    h.nextPick = (name: 'ledgerly-20261029.ledgerly', bytes: bytes);
    await openSettingsRow(h, 'Import a Ledgerly file');
    await tester.tap(find.text('Choose a .ledgerly file'));
    await h.settle();
    expect(find.text('This file has a password'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'not it');
    await tester.tap(find.text('Open'));
    await h.settle();
    expect(
      find.textContaining('That password does not open this file. Nothing was changed.'),
      findsOneWidget,
    );

    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'ledgerly-pass');
    await tester.tap(find.text('Open'));
    await h.settle();
    expect(find.text('In this file'), findsOneWidget);
    expect(find.textContaining('by Ledgerly 1.0.0+1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Replace all data'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final replace = find.widgetWithText(FilledButton, 'Replace all data');
    expect(
      tester.widget<FilledButton>(replace).onPressed,
      isNull,
      reason: 'nothing happens until REPLACE is typed',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Type REPLACE to confirm'), 'REPLACE');
    await tester.pump();
    await tester.tap(replace);
    await h.settle();

    expect(h.replacedWith, hasLength(1));
    expect(h.replacedWith.single.counts['entries'], 1);
    expect(h.replacedWith.single.database.existsSync(), isTrue);

    await h.dispose();
  });

  testWidgets('a file that is not a Ledgerly file says so and changes nothing', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();
    h.nextPick = (name: 'notes.txt', bytes: Uint8List.fromList('just some notes'.codeUnits));
    await openSettingsRow(h, 'Import a Ledgerly file');
    await tester.tap(find.text('Choose a .ledgerly file'));
    await h.settle();
    expect(find.text('This is not a Ledgerly data file. Nothing was changed.'), findsOneWidget);
    expect(find.text('Replace all data'), findsNothing);
    expect(h.replacedWith, isEmpty);
    await h.dispose();
  });
}
