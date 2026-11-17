import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/data/repositories/entry_view.dart';
import 'package:ledgerly/domain/postings.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

import 'test_ledger.dart';

void main() {
  late TestLedger l;
  setUp(() async => l = await TestLedger.create());
  tearDown(() => l.dispose());

  Future<({int income, int spending})> october() async {
    final t = await l.entries.totals('2026-10-01', '2026-10-31');
    return (income: t.incomeMinor, spending: t.spendingMinor);
  }

  test('an expense lowers the balance and counts as spending', () async {
    await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 8500,
      categoryId: 'groceries',
      title: 'Groceries',
    );
    expect(await l.balance(l.bank), 91500);
    expect((await october()).spending, 8500);
    final totals = await l.entries.totals('2026-10-01', '2026-10-31');
    expect(
      totals.spendingByCategory.single.categoryId,
      'food',
      reason: 'subcategories roll up to their category',
    );
  });

  test('income counts as income only', () async {
    await l.entries.addEntry(
      isExpense: false,
      accountId: l.bank,
      amountMinor: 200000,
      categoryId: 'salary',
      title: 'Salary',
    );
    expect(await october(), (income: 200000, spending: 0));
    expect(await l.balance(l.bank), 300000);
  });

  test('a transfer moves money and changes neither income nor spending', () async {
    await l.entries.addTransfer(fromAccountId: l.cash, toAccountId: l.bank, amountMinor: 19558);
    expect(await october(), (income: 0, spending: 0));
    expect(await l.balance(l.cash), 20000 - 19558);
    expect(await l.balance(l.bank), 100000 + 10000);
  });

  test('a refund lowers spending in its category and is never income', () async {
    final (id, _) = await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 5990,
      categoryId: 'clothes',
      title: 'Clothes',
    );
    await l.entries.addRefund(ofEntryId: id, amountMinor: 2990);
    expect(await october(), (income: 0, spending: 3000));
    expect(await l.balance(l.bank), 100000 - 3000);
  });

  test('my share: only my part is spending, and the repayment is not income', () async {
    await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 4000,
      categoryId: 'dining',
      title: 'Dinner',
      shareMinor: 2500,
    );
    expect((await october()).spending, 2500);
    expect(await l.accounts.watchOwedToMe().first, 1500);
    await l.entries.addRepayment(accountId: l.bank, amountMinor: 1500);
    expect(await october(), (income: 0, spending: 2500));
    expect(await l.accounts.watchOwedToMe().first, 0);
    expect(await l.balance(l.bank), 100000 - 2500);
  });

  test('a balance check saves the difference as Untracked, outside income and spending', () async {
    final before = await l.balance(l.cash);
    await l.entries.reconcile(
      accountId: l.cash,
      realBalanceMinor: before - 1200,
      currentBalanceMinor: before,
    );
    expect(await l.balance(l.cash), before - 1200);
    expect(await october(), (income: 0, spending: 0));
  });

  test('a Later entry waits in Needs Review, counts as spending, and finishes with one category', () async {
    final (id, _) = await l.entries.addLater(accountId: l.bank, amountMinor: 1200);
    expect((await october()).spending, 1200);
    expect(await l.entries.watchEntries(const EntryQuery(needsReview: true)).first, hasLength(1));
    await l.entries.changeCategory(id, 'coffee');
    expect(await l.entries.watchEntries(const EntryQuery(needsReview: true)).first, isEmpty);
    expect((await l.entries.find(id))!.categoryId, 'coffee');
  });

  test('changes can be undone', () async {
    final (id, undoSave) = await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 1000,
      categoryId: 'coffee',
      title: 'Coffee',
    );
    final undoEdit = await l.entries.changeAmountOrAccount(id, amountMinor: 2500);
    expect(await l.balance(l.bank), 97500);
    await undoEdit();
    expect(await l.balance(l.bank), 99000);
    final undoTitle = await l.entries.updateDetails(id, title: 'Cappuccino', merchant: 'Kafić Šišmiš');
    expect((await l.entries.find(id))!.entry.title, 'Cappuccino');
    await undoTitle();
    expect((await l.entries.find(id))!.entry.title, 'Coffee');
    final undoDelete = await l.entries.delete(id);
    expect(await l.balance(l.bank), 100000);
    await undoDelete();
    expect(await l.balance(l.bank), 99000);
    await undoSave();
    expect(await l.entries.find(id), isNull);
  });

  test('moving to a BAM account freezes a new EUR value', () async {
    final (id, _) = await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 1200,
      categoryId: 'coffee',
    );
    await l.entries.changeAmountOrAccount(id, accountId: l.cash);
    final v = (await l.entries.find(id))!;
    expect(v.currency, 'BAM');
    expect(v.countedBaseMinor, -614);
  });

  test('search finds titles without diacritics, merchants, and amounts', () async {
    await l.entries.addEntry(
      isExpense: true,
      accountId: l.cash,
      amountMinor: 1250,
      categoryId: 'dining',
      title: 'Ćevapi',
      merchant: 'Željo',
    );
    await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 999,
      categoryId: 'streaming',
      title: 'Netflix',
    );
    Future<List<String>> find(String q) async =>
        (await l.entries.watchEntries(EntryQuery(search: q)).first).map((e) => e.displayTitle).toList();
    expect(await find('cevapi'), ['Ćevapi']);
    expect(await find('zeljo'), ['Ćevapi']);
    expect(await find('12.50'), ['Ćevapi']);
    expect(await find('9.99'), ['Netflix']);
  });

  test('filters by category include subcategories, and by account', () async {
    await l.entries.addEntry(isExpense: true, accountId: l.bank, amountMinor: 100, categoryId: 'groceries');
    await l.entries.addEntry(isExpense: true, accountId: l.cash, amountMinor: 100, categoryId: 'fuel');
    expect(await l.entries.watchEntries(const EntryQuery(categoryId: 'food')).first, hasLength(1));
    expect(
      (await l.entries.watchEntries(EntryQuery(accountId: l.cash)).first).single.type,
      EntryType.expense,
    );
  });

  test('titles are remembered with their usual category and account', () async {
    for (var i = 0; i < 3; i++) {
      await l.entries.addEntry(
        isExpense: true,
        accountId: l.cash,
        amountMinor: 400,
        categoryId: 'coffee',
        title: 'Coffee',
      );
    }
    await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 400,
      categoryId: 'coffee',
      title: 'coffee',
    );
    final memory = await l.entries.watchTitleMemory().first;
    expect(memory, hasLength(1));
    expect(memory.single.accountId, l.cash);
    expect(memory.single.count, 4);
  });

  test('the most used categories for an account', () async {
    await l.entries.addEntry(isExpense: true, accountId: l.cash, amountMinor: 400, categoryId: 'coffee');
    await l.entries.addEntry(isExpense: true, accountId: l.cash, amountMinor: 400, categoryId: 'coffee');
    await l.entries.addEntry(isExpense: true, accountId: l.cash, amountMinor: 180, categoryId: 'transit');
    expect(await l.entries.mostUsedCategories(l.cash, 'expense'), ['coffee', 'transit']);
  });

  test('calendar days: spending, income, count, top category and paid repeats', () async {
    final (bread, _) = await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 3000,
      categoryId: 'groceries',
      day: '2026-10-28',
    );
    await l.entries.addEntry(
      isExpense: true,
      accountId: l.bank,
      amountMinor: 1200,
      categoryId: 'transit',
      day: '2026-10-28',
    );
    await l.entries.addRefund(ofEntryId: bread, amountMinor: 500, day: '2026-10-28');
    await l.entries.addEntry(
      isExpense: false,
      accountId: l.bank,
      amountMinor: 200000,
      categoryId: 'salary',
      day: '2026-10-29',
    );
    await l.entries.addTransfer(fromAccountId: l.bank, toAccountId: l.cash, amountMinor: 5000);
    final rent = await l.repeats.create(
      title: 'Rent',
      kind: 'expense',
      categoryId: 'rent',
      accountId: l.bank,
      amountMinor: 46000,
      every: Every.monthly,
      nextDay: '2026-10-29',
    );
    await l.repeats.markPaid(rent);

    final days = await l.entries.watchDayTotals('2026-10-01', '2026-10-31').first;
    final tue = days['2026-10-28']!;
    expect(tue.spentMinor, 3000 + 1200 - 500, reason: 'the refund lowers spending');
    expect(tue.incomeMinor, 0);
    expect(tue.count, 3);
    expect(tue.topCategoryId, 'food');
    expect(tue.hasRepeat, isFalse);

    final wed = days['2026-10-29']!;
    expect(wed.incomeMinor, 200000);
    expect(wed.spentMinor, 46000, reason: 'the transfer never counts');
    expect(wed.count, 3, reason: 'salary, transfer and rent are all entries');
    expect(wed.hasRepeat, isTrue);
    expect(wed.netMinor, 200000 - 46000);
    expect(days.containsKey('2026-10-27'), isFalse);
  });

  test('a statement import adds the chosen rows, and Undo removes them all', () async {
    final (added, undo) = await l.entries.importStatement(l.bank, const [
      ImportDraft(day: '2026-10-01', amountMinor: -4520, title: 'KONZUM 123', categoryId: 'groceries'),
      ImportDraft(day: '2026-10-04', amountMinor: -160, title: 'Bus'),
      ImportDraft(day: '2026-10-03', amountMinor: 200000, title: 'Plata', categoryId: 'salary'),
    ]);
    expect(added, 3);
    final list = await l.entries.watchEntries(const EntryQuery()).first;
    expect(list, hasLength(3));
    expect(list.where((e) => e.needsReview).single.displayTitle, 'Bus');
    expect(await october(), (income: 200000, spending: 4520 + 160));

    final recorded = await l.entries.signedAmountsOnAccount(l.bank, '2026-09-28', '2026-10-07');
    expect(recorded.map((e) => e.amountMinor), containsAll([-4520, -160, 200000]));

    await undo();
    expect(await l.entries.watchEntries(const EntryQuery()).first, isEmpty);
    expect(await l.balance(l.bank), 100000);
  });

  test('money coming in is not imported without an income category, and nothing is added', () async {
    expect(
      () => l.entries.importStatement(l.bank, const [
        ImportDraft(day: '2026-10-01', amountMinor: -100, title: 'Kiosk'),
        ImportDraft(day: '2026-10-03', amountMinor: 5000, title: 'Unknown'),
      ]),
      throwsA(isA<RuleException>()),
    );
    expect(await l.entries.watchEntries(const EntryQuery()).first, isEmpty);
  });

  group('everyday spending', () {
    Future<EverydaySpending> window() => l.entries.watchEverydaySpending('2026-07-30', '2026-10-29').first;

    test('expenses minus refunds; transfers and balance checks never count', () async {
      final (id, _) = await l.entries.addEntry(
        isExpense: true,
        accountId: l.bank,
        amountMinor: 8500,
        categoryId: 'groceries',
      );
      await l.entries.addRefund(ofEntryId: id, amountMinor: 2000);
      await l.entries.addTransfer(fromAccountId: l.bank, toAccountId: l.cash, amountMinor: 5000);
      final before = await l.balance(l.bank);
      await l.entries.reconcile(
        accountId: l.bank,
        realBalanceMinor: before - 1200,
        currentBalanceMinor: before,
      );
      expect(await window(), (spentMinor: 6500, firstDay: '2026-10-29'));
    });

    test('monthly repeats are left out, even once stopped; weekly ones stay in', () async {
      Future<String> paid(String title, Every every, int amount) async {
        final id = await l.repeats.create(
          title: title,
          kind: 'expense',
          categoryId: 'rent',
          accountId: l.bank,
          amountMinor: amount,
          every: every,
          nextDay: '2026-10-29',
        );
        await l.repeats.markPaid(id);
        return id;
      }

      final rent = await paid('Rent', Every.monthly, 46000);
      await paid('Cleaner', Every.weekly, 3000);
      expect((await window()).spentMinor, 3000);
      await l.repeats.stop(rent);
      expect((await window()).spentMinor, 3000);
    });

    test('an entry before the window does not count but is the first day', () async {
      await l.entries.addEntry(
        isExpense: true,
        accountId: l.bank,
        amountMinor: 4000,
        categoryId: 'groceries',
        day: '2026-03-01',
      );
      expect(await window(), (spentMinor: 0, firstDay: '2026-03-01'));
    });

    test('nothing recorded', () async {
      expect(await window(), (spentMinor: 0, firstDay: null));
    });

    test('an amount saved for later counts as spending', () async {
      await l.entries.addLater(accountId: l.cash, amountMinor: 1955);
      expect((await window()).spentMinor, 1000, reason: '19.55 KM is €10.00');
    });
  });

  test('rules are enforced', () async {
    expect(
      () => l.entries.addEntry(isExpense: true, accountId: l.bank, amountMinor: 0, categoryId: 'coffee'),
      throwsA(isA<RuleException>()),
    );
    expect(
      () => l.entries.addTransfer(fromAccountId: l.bank, toAccountId: l.bank, amountMinor: 100),
      throwsA(isA<RuleException>()),
    );
  });
}
