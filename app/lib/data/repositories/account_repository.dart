// Accounts and their balances. A balance is never stored: it is the opening amount plus every
// posting on the account, so it can always be rebuilt.

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/money.dart';
import '../../domain/system_ids.dart';
import '../database/app_database.dart';
import 'repository.dart';

enum AccountKind {
  bank('Bank account'),
  cash('Cash'),
  card('Credit card'),
  savings('Savings');

  const AccountKind(this.label);
  final String label;
}

class AccountWithBalance {
  const AccountWithBalance(this.account, this.balanceMinor);

  final Account account;

  /// In the account's own currency. A credit card owed is negative.
  final int balanceMinor;

  String get id => account.id;
  String get name => account.name;
  String get currency => account.currency;

  /// Converted to EUR at the current rate.
  int get baseMinor => toBase(balanceMinor, account.currency);
}

class AccountRepository extends Repository {
  AccountRepository(super.db, super.clock);

  static const _balanceSql = '''
    SELECT a.*, a.opening_minor + COALESCE((
      SELECT SUM(p.amount_minor) FROM postings p JOIN entries e ON e.id = p.entry_id
      WHERE p.account_id = a.id AND e.deleted_at IS NULL AND p.deleted_at IS NULL
    ), 0) AS balance
    FROM accounts a
    WHERE a.deleted_at IS NULL
  ''';

  /// The person's accounts with balances, in their chosen order. The system account is left out.
  Stream<List<AccountWithBalance>> watchAccounts({bool includeArchived = false}) => db
      .customSelect(
        "$_balanceSql AND a.kind != 'system' ${includeArchived ? '' : 'AND a.archived = 0'} ORDER BY a.sort_order, a.created_at",
        readsFrom: {db.accounts, db.postings, db.entries},
      )
      .watch()
      .map(
        (rows) => [for (final r in rows) AccountWithBalance(db.accounts.map(r.data), r.read<int>('balance'))],
      );

  /// What other people still owe from shared payments, in EUR.
  Stream<int> watchOwedToMe() => db
      .customSelect(
        'SELECT COALESCE(SUM(p.base_minor), 0) AS owed FROM postings p JOIN entries e ON e.id = p.entry_id '
        'WHERE p.account_id = ? AND e.deleted_at IS NULL AND p.deleted_at IS NULL',
        variables: [Variable.withString(SystemIds.owedToMe)],
        readsFrom: {db.postings, db.entries},
      )
      .watch()
      .map((rows) => rows.first.read<int>('owed'));

  Future<int> balanceOf(String accountId) async {
    final row = await db
        .customSelect(
          '$_balanceSql AND a.id = ?',
          variables: [Variable.withString(accountId)],
          readsFrom: {db.accounts, db.postings},
        )
        .getSingle();
    return row.read<int>('balance');
  }

  Future<Account?> find(String id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<String> create({
    required String name,
    required AccountKind kind,
    required String currency,
    int openingMinor = 0,
  }) async {
    final id = newId();
    final count = await db.accounts.count().getSingle();
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            name: name.trim(),
            kind: kind.name,
            currency: currency,
            openingMinor: Value(openingMinor),
            sortOrder: Value(count),
            checkedOn: Value(today),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> update(String id, {String? name, AccountKind? kind, bool? archived}) =>
      (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(
          name: name == null ? const Value.absent() : Value(name.trim()),
          kind: kind == null ? const Value.absent() : Value(kind.name),
          archived: archived == null ? const Value.absent() : Value(archived),
          updatedAt: Value(now),
        ),
      );

  Future<void> markChecked(String id) => (db.update(
    db.accounts,
  )..where((a) => a.id.equals(id))).write(AccountsCompanion(checkedOn: Value(today), updatedAt: Value(now)));
}
