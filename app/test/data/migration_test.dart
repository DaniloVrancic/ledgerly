// Opens a database made by an older version of the app and checks the upgrade keeps its data.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/clock.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/budget_repository.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';

void main() {
  late Directory dir;
  late File file;
  final clock = FixedClock(DateTime(2026, 10, 29, 12));

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = Directory.systemTemp.createTempSync('ledgerly_migration');
    file = File('${dir.path}/ledgerly.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<int> userVersion(AppDatabase db) async =>
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version');

  test('a version 1 database gains budgets and keeps its entries', () async {
    // A database as version 1 left it: everything except the budgets table.
    var db = AppDatabase(NativeDatabase(file));
    final account = await AccountRepository(
      db,
      clock,
    ).create(name: 'Main Bank', kind: AccountKind.bank, currency: 'EUR', openingMinor: 100000);
    await EntryRepository(db, clock).addEntry(
      isExpense: true,
      accountId: account,
      amountMinor: 1250,
      categoryId: 'groceries',
      title: 'Bread',
    );
    await db.customStatement('DROP TABLE budgets');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    expect(await userVersion(db), 2);
    final budgets = BudgetRepository(db, clock);
    await budgets.create(categoryId: 'food', limitMinor: 40000, every: BudgetEvery.monthly);
    expect(await budgets.watchBudgets().first, hasLength(1));
    expect(await AccountRepository(db, clock).balanceOf(account), 100000 - 1250);
    expect((await budgets.spending('2026-10-01', '2026-10-31'))['food'], 1250);
    await db.close();
  });
}
