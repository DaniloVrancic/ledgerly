import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';

import 'test_ledger.dart';

void main() {
  late TestLedger l;
  setUp(() async => l = await TestLedger.create());
  tearDown(() => l.dispose());

  test('a new install has the default categories', () async {
    final all = await l.categories.all();
    expect(all.where((c) => c.parentId == null && c.kind == 'expense').map((c) => c.name), contains('Food'));
    expect(all.firstWhere((c) => c.id == 'groceries').parentId, 'food');
  });

  test('custom categories and subcategories, with Bosnian characters', () async {
    final id = await l.categories.create(name: 'Čišćenje', kind: CategoryKind.expense, icon: 'sparkle', colorSlot: 3);
    final sub = await l.categories.create(name: 'Prozori', kind: CategoryKind.expense, parentId: id, icon: 'home', colorSlot: 3);
    final all = await l.categories.all();
    expect(all.firstWhere((c) => c.id == id).isCustom, isTrue);
    expect(all.firstWhere((c) => c.id == sub).parentId, id);
  });

  test('names are required and short', () async {
    expect(() => l.categories.create(name: '  ', kind: CategoryKind.expense, icon: 'dots', colorSlot: 0), throwsA(isA<CategoryException>()));
    expect(() => l.categories.create(name: 'x' * 33, kind: CategoryKind.expense, icon: 'dots', colorSlot: 0), throwsA(isA<CategoryException>()));
  });

  test('a category can be limited to accounts, and the limit can change', () async {
    final id = await l.categories.create(name: 'Pets', kind: CategoryKind.expense, icon: 'paw', colorSlot: 9, accountIds: {l.cash});
    expect((await l.categories.watchAccountLimits().first)[id], {l.cash});
    await l.categories.setAccounts(id, {});
    expect((await l.categories.watchAccountLimits().first)[id], isNull);
  });

  test('archiving hides it from new entries but keeps its history', () async {
    await l.entries.addEntry(isExpense: true, accountId: l.bank, amountMinor: 1000, categoryId: 'cinema');
    final undo = await l.categories.setArchived('entertainment', true);
    final all = await l.categories.all();
    expect(all.firstWhere((c) => c.id == 'cinema').archived, isTrue);
    expect((await l.entries.totals('2026-10-01', '2026-10-31')).spendingFor('entertainment'), 1000);
    await undo();
    expect((await l.categories.all()).firstWhere((c) => c.id == 'cinema').archived, isFalse);
  });

  test('a category in use is never destroyed: its entries must move first', () async {
    await l.entries.addEntry(isExpense: true, accountId: l.bank, amountMinor: 1000, categoryId: 'cinema');
    expect(await l.categories.usageCount('entertainment'), 1);
    expect(() => l.categories.deleteAndMove('entertainment'), throwsA(isA<CategoryException>()));
    await l.categories.deleteAndMove('entertainment', moveTo: 'other');
    final totals = await l.entries.totals('2026-10-01', '2026-10-31');
    expect(totals.spendingFor('other'), 1000);
    expect((await l.categories.all()).any((c) => c.id == 'entertainment' || c.id == 'cinema'), isFalse);
    expect(await l.entries.watchEntries(const EntryQuery()).first, hasLength(1));
  });

  test('an unused category can be deleted, and the app keeps its own', () async {
    final id = await l.categories.create(name: 'Hobby', kind: CategoryKind.expense, icon: 'game', colorSlot: 6);
    await l.categories.deleteAndMove(id);
    expect((await l.categories.all()).any((c) => c.id == id), isFalse);
    expect(() => l.categories.deleteAndMove('uncategorised', moveTo: 'other'), throwsA(isA<CategoryException>()));
  });
}
