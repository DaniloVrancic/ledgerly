import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/budget_repository.dart';

import 'test_ledger.dart';

void main() {
  late TestLedger l;
  late BudgetRepository budgets;
  setUp(() async {
    l = await TestLedger.create();
    budgets = BudgetRepository(l.db, l.clock);
  });
  tearDown(() => l.dispose());

  Future<Map<String, int>> october() => budgets.spending('2026-10-01', '2026-10-31');

  Future<String> spend(int amount, String category) async {
    final (id, _) = await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: amount,
      categoryId: category,
      title: 'Test',
    );
    return id;
  }

  test('spending counts per subcategory, its category and overall', () async {
    await spend(6000, 'groceries');
    await spend(4000, 'dining');
    await spend(2500, 'transport');
    final s = await october();
    expect(s['groceries'], 6000);
    expect(s['dining'], 4000);
    expect(s['food'], 10000);
    expect(s[BudgetRepository.overall], 12500);
  });

  test('a transfer never counts, a refund lowers spending', () async {
    final id = await spend(10000, 'groceries');
    await l.entries.addTransfer(fromAccountId: l.bank, toAccountId: l.cash, amountMinor: 5000);
    await l.entries.addRefund(ofEntryId: id, amountMinor: 2000);
    final s = await october();
    expect(s['food'], 8000);
    expect(s[BudgetRepository.overall], 8000);
  });

  test('overall agrees with the spending Home and Insights show', () async {
    await spend(6000, 'groceries');
    await l.entries.addLater(accountId: l.bank, amountMinor: 1500);
    final totals = await l.entries.totals('2026-10-01', '2026-10-31');
    expect((await october())[BudgetRepository.overall], totals.spendingMinor);
  });

  test('only one budget per category and cadence', () async {
    await budgets.create(categoryId: 'food', limitMinor: 40000, every: BudgetEvery.monthly);
    expect(
      () => budgets.create(categoryId: 'food', limitMinor: 30000, every: BudgetEvery.monthly),
      throwsA(isA<BudgetException>()),
    );
    await budgets.create(categoryId: 'food', limitMinor: 10000, every: BudgetEvery.weekly);
    await budgets.create(limitMinor: 170000, every: BudgetEvery.monthly);
    expect(
      () => budgets.create(limitMinor: 150000, every: BudgetEvery.monthly),
      throwsA(isA<BudgetException>()),
    );
    expect(await budgets.watchBudgets().first, hasLength(3));
  });

  test('limits must be above zero and categories must be for expenses', () async {
    expect(
      () => budgets.create(categoryId: 'food', limitMinor: 0, every: BudgetEvery.monthly),
      throwsA(isA<BudgetException>()),
    );
    expect(
      () => budgets.create(categoryId: 'salary', limitMinor: 100, every: BudgetEvery.monthly),
      throwsA(isA<BudgetException>()),
    );
    expect(
      () => budgets.create(categoryId: 'food', limitMinor: 100, every: 'yearly'),
      throwsA(isA<BudgetException>()),
    );
  });

  test('a deleted budget no longer blocks a new one, and delete can be undone', () async {
    final id = await budgets.create(categoryId: 'food', limitMinor: 40000, every: BudgetEvery.monthly);
    final undo = await budgets.delete(id);
    expect(await budgets.watchBudgets().first, isEmpty);
    await undo();
    expect((await budgets.watchBudgets().first).single.id, id);

    await budgets.delete(id);
    await budgets.create(categoryId: 'food', limitMinor: 35000, every: BudgetEvery.monthly);
    expect((await budgets.watchBudgets().first).single.limitMinor, 35000);
  });

  test('the limit can be changed', () async {
    final id = await budgets.create(categoryId: 'food', limitMinor: 40000, every: BudgetEvery.monthly);
    await budgets.update(id, limitMinor: 45000);
    expect((await budgets.watchBudgets().first).single.limitMinor, 45000);
  });
}
