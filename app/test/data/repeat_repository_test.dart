import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

import 'test_ledger.dart';

void main() {
  late TestLedger l;
  setUp(() async => l = await TestLedger.create());
  tearDown(() => l.dispose());

  Future<String> phoneBill({bool varies = false, Every every = Every.monthly, String next = '2026-10-25'}) =>
      l.repeats.create(
        title: 'Phone bill',
        kind: 'expense',
        categoryId: 'mobile',
        accountId: l.bank,
        amountMinor: 3500,
        every: every,
        nextDay: next,
        varies: varies,
      );

  test('mark paid records the entry and moves to the next date', () async {
    final id = await phoneBill();
    await l.repeats.markPaid(id);
    final r = (await l.repeats.find(id))!;
    expect(r.nextDay, '2026-11-25');
    final paid = await l.entries.watchEntries(const EntryQuery()).first;
    expect(paid.single.displayTitle, 'Phone bill');
    expect(paid.single.entry.repeatId, id);
    expect(await l.balance(l.bank), 100000 - 3500);
  });

  test('an amount that varies is taken from this time and remembered', () async {
    final id = await phoneBill(varies: true);
    await l.repeats.markPaid(id, amountMinor: 4120);
    expect(await l.balance(l.bank), 100000 - 4120);
    expect((await l.repeats.find(id))!.amountMinor, 4120);
  });

  test('undo removes the entry and puts the date back, so it can be paid again', () async {
    final id = await phoneBill();
    final undo = await l.repeats.markPaid(id);
    await undo();
    expect((await l.repeats.find(id))!.nextDay, '2026-10-25');
    expect(await l.entries.watchEntries(const EntryQuery()).first, isEmpty);
    await l.repeats.markPaid(id);
    expect(await l.entries.watchEntries(const EntryQuery()).first, hasLength(1));
  });

  test('skip moves on without paying', () async {
    final id = await phoneBill();
    final undo = await l.repeats.skip(id);
    expect((await l.repeats.find(id))!.nextDay, '2026-11-25');
    expect(await l.balance(l.bank), 100000);
    await undo();
    expect((await l.repeats.find(id))!.nextDay, '2026-10-25');
  });

  test('a daily repeat is dated the day it was for', () async {
    final id = await phoneBill(every: Every.daily, next: '2026-10-27');
    await l.repeats.markPaid(id);
    expect((await l.entries.watchEntries(const EntryQuery()).first).single.day, '2026-10-27');
    expect((await l.repeats.find(id))!.nextDay, '2026-10-28');
  });

  test('edits save straight away and a stopped repeat keeps its past entries', () async {
    final id = await phoneBill();
    await l.repeats.markPaid(id);
    await l.repeats.update(id, title: 'Mobile', amountMinor: 3900, every: Every.yearly);
    final r = (await l.repeats.find(id))!;
    expect((r.title, r.amountMinor, r.every), ('Mobile', 3900, 'yearly'));
    await l.repeats.stop(id);
    expect(await l.repeats.watchAll().first, isEmpty);
    expect(await l.entries.watchEntries(const EntryQuery()).first, hasLength(1));
  });

  test('a repeat is found by its title, ignoring case', () async {
    final id = await phoneBill();
    expect((await l.repeats.findByTitle('phone BILL', 'expense'))?.id, id);
    expect(await l.repeats.findByTitle('phone', 'expense'), isNull);
  });
}
