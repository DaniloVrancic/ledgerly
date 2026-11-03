// A fresh in-memory database with two accounts and a fixed date, for the repository tests.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ledgerly/core/clock.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/data/repositories/goal_repository.dart';
import 'package:ledgerly/data/repositories/repeat_repository.dart';

class TestLedger {
  TestLedger._(this.db, this.clock)
      : accounts = AccountRepository(db, clock),
        categories = CategoryRepository(db, clock),
        entries = EntryRepository(db, clock),
        goals = GoalRepository(db, clock) {
    repeats = RepeatRepository(db, clock, entries);
  }

  final AppDatabase db;
  final FixedClock clock;
  final AccountRepository accounts;
  final CategoryRepository categories;
  final EntryRepository entries;
  final GoalRepository goals;
  late final RepeatRepository repeats;

  late String bank;
  late String cash;

  static Future<TestLedger> create() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final ledger = TestLedger._(AppDatabase(NativeDatabase.memory()), FixedClock(DateTime(2026, 10, 29, 12)));
    ledger.bank = await ledger.accounts.create(name: 'Main Bank', kind: AccountKind.bank, currency: 'EUR', openingMinor: 100000);
    ledger.cash = await ledger.accounts.create(name: 'Cash', kind: AccountKind.cash, currency: 'BAM', openingMinor: 20000);
    return ledger;
  }

  Future<void> dispose() => db.close();

  Future<int> balance(String id) => accounts.balanceOf(id);
}
