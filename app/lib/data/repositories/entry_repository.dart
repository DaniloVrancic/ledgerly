// Entries and their postings: saving, changing, deleting, and the totals the screens show.

import 'package:drift/drift.dart';

import '../../core/day.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/text.dart';
import '../../domain/insights.dart';
import '../../domain/postings.dart';
import '../../domain/system_ids.dart';
import '../../domain/title_memory.dart';
import '../database/app_database.dart';
import 'entry_view.dart';
import 'repository.dart';

/// What to show in a list of entries. Every field is optional.
class EntryQuery {
  const EntryQuery({
    this.start,
    this.end,
    this.accountId,
    this.categoryId,
    this.type,
    this.search,
    this.needsReview,
    this.limit = 200,
  });

  final String? start;
  final String? end;
  final String? accountId;

  /// A category matches its subcategories too.
  final String? categoryId;
  final EntryType? type;

  /// Words in the title, merchant or note, or an amount such as "12.50".
  final String? search;
  final bool? needsReview;
  final int limit;

  // Equality lets screens watch the same query without reloading it.
  @override
  bool operator ==(Object other) =>
      other is EntryQuery &&
      other.start == start &&
      other.end == end &&
      other.accountId == accountId &&
      other.categoryId == categoryId &&
      other.type == type &&
      other.search == search &&
      other.needsReview == needsReview &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(start, end, accountId, categoryId, type, search, needsReview, limit);

  EntryQuery copyWith({
    String? start,
    String? end,
    String? accountId,
    String? categoryId,
    EntryType? type,
    String? search,
    int? limit,
  }) => EntryQuery(
    start: start ?? this.start,
    end: end ?? this.end,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    type: type ?? this.type,
    search: search ?? this.search,
    needsReview: needsReview,
    limit: limit ?? this.limit,
  );
}

class EntryRepository extends Repository {
  EntryRepository(super.db, super.clock);

  // ---- Saving ----

  /// An expense or income on one category. Returns the new entry's id and its Undo.
  Future<(String, Undo)> addEntry({
    required bool isExpense,
    required String accountId,
    required int amountMinor,
    required String categoryId,
    String? title,
    String? merchant,
    String? note,
    String? day,
    int? shareMinor,
    String? repeatId,
    String? repeatDay,
  }) async {
    final account = await _account(accountId);
    final postings = entryPostings(
      isExpense: isExpense,
      accountId: accountId,
      currency: account.currency,
      amountMinor: amountMinor,
      categoryId: categoryId,
      shareMinor: shareMinor,
    );
    return _insert(
      type: isExpense ? EntryType.expense : EntryType.income,
      day: day ?? today,
      title: title,
      merchant: merchant,
      note: note,
      postings: postings,
      repeatId: repeatId,
      repeatDay: repeatDay,
    );
  }

  /// Saved with only an amount. It waits in Needs Review and counts as spending meanwhile.
  Future<(String, Undo)> addLater({
    required String accountId,
    required int amountMinor,
    String? title,
    String? day,
  }) async {
    final account = await _account(accountId);
    final postings = entryPostings(
      isExpense: true,
      accountId: accountId,
      currency: account.currency,
      amountMinor: amountMinor,
      categoryId: SystemIds.uncategorised,
    );
    return _insert(
      type: EntryType.expense,
      day: day ?? today,
      title: title,
      postings: postings,
      needsReview: true,
    );
  }

  /// Money moved between two accounts. Never income or spending.
  Future<(String, Undo)> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinor,
    String? title,
    String? note,
    String? day,
  }) async {
    final from = await _account(fromAccountId);
    final to = await _account(toAccountId);
    final postings = transferPostings(
      fromAccountId: from.id,
      fromCurrency: from.currency,
      toAccountId: to.id,
      toCurrency: to.currency,
      amountMinor: amountMinor,
    );
    return _insert(
      type: EntryType.transfer,
      day: day ?? today,
      title: title ?? 'To ${to.name}',
      note: note,
      postings: postings,
    );
  }

  /// Money back for an expense, on its category, so spending there goes down.
  Future<(String, Undo)> addRefund({required String ofEntryId, required int amountMinor, String? day}) async {
    final of = await find(ofEntryId);
    if (of == null || of.type != EntryType.expense || of.categoryId == null) {
      throw RuleException('Only an expense can be refunded.');
    }
    final postings = refundPostings(
      accountId: of.accountId,
      currency: of.currency,
      amountMinor: amountMinor,
      categoryId: of.categoryId!,
    );
    return _insert(
      type: EntryType.refund,
      day: day ?? today,
      title: '${of.displayTitle} refund',
      postings: postings,
      refundOfId: of.id,
    );
  }

  /// Someone paid back their part of a shared expense. It clears "Owed to me" and is not income.
  Future<(String, Undo)> addRepayment({
    required String accountId,
    required int amountMinor,
    String? title,
    String? day,
  }) async {
    final account = await _account(accountId);
    final postings = repaymentPostings(
      accountId: accountId,
      currency: account.currency,
      amountMinor: amountMinor,
    );
    return _insert(
      type: EntryType.transfer,
      day: day ?? today,
      title: title ?? 'Paid back',
      postings: postings,
    );
  }

  /// A balance check. The difference is saved as Untracked, which reports leave out.
  Future<(String?, Undo)> reconcile({
    required String accountId,
    required int realBalanceMinor,
    required int currentBalanceMinor,
  }) async {
    final account = await _account(accountId);
    final postings = adjustmentPostings(
      accountId: accountId,
      currency: account.currency,
      differenceMinor: realBalanceMinor - currentBalanceMinor,
    );
    await (db.update(db.accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(checkedOn: Value(today), updatedAt: Value(now)),
    );
    if (postings.isEmpty) return (null, () async {});
    return _insert(type: EntryType.adjustment, day: today, title: 'Untracked', postings: postings);
  }

  // ---- Changing ----

  /// Changes text and the day. Saves at once, like every field in the details screen.
  Future<Undo> updateDetails(
    String id, {
    String? title,
    String? merchant,
    String? note,
    String? day,
    bool clearMerchant = false,
  }) async {
    final before = (await find(id))!;
    final e = before.entry;
    final nextTitle = title ?? e.title;
    final nextMerchant = clearMerchant ? null : (merchant ?? e.merchant);
    final nextNote = note ?? e.note;
    await (db.update(db.entries)..where((x) => x.id.equals(id))).write(
      EntriesCompanion(
        title: Value(_blankToNull(nextTitle)),
        merchant: Value(_blankToNull(nextMerchant)),
        note: Value(_blankToNull(nextNote)),
        day: day == null ? const Value.absent() : Value(day),
        searchText: Value(_searchText(nextTitle, nextMerchant, nextNote)),
        updatedAt: Value(now),
      ),
    );
    return () => _restore(before);
  }

  /// Moves an entry to another category. Finishing a Needs Review entry does exactly this.
  Future<Undo> changeCategory(String id, String categoryId) async {
    final before = (await find(id))!;
    await db.transaction(() async {
      await (db.update(db.postings)..where((p) => p.entryId.equals(id) & p.categoryId.isNotNull())).write(
        PostingsCompanion(categoryId: Value(categoryId), updatedAt: Value(now)),
      );
      await (db.update(db.entries)..where((e) => e.id.equals(id))).write(
        EntriesCompanion(needsReview: const Value(false), updatedAt: Value(now)),
      );
    });
    return () => _restore(before);
  }

  /// Changes the amount or account of a simple entry. The EUR value is frozen again.
  Future<Undo> changeAmountOrAccount(String id, {int? amountMinor, String? accountId}) async {
    final before = (await find(id))!;
    if (!before.isSimple) throw RuleException('Delete and add this entry again to change its amount.');
    final p = before.postings.single;
    final account = await _account(accountId ?? p.accountId);
    final magnitude = amountMinor ?? p.amountMinor.abs();
    if (magnitude <= 0) throw RuleException('Enter an amount above zero.');
    final signed = p.amountMinor < 0 ? -magnitude : magnitude;
    await (db.update(db.postings)..where((x) => x.id.equals(p.id))).write(
      PostingsCompanion(
        accountId: Value(account.id),
        currency: Value(account.currency),
        amountMinor: Value(signed),
        baseMinor: Value(toBase(signed, account.currency)),
        updatedAt: Value(now),
      ),
    );
    await _touch(id);
    return () => _restore(before);
  }

  /// Deletes an entry. It is kept as deleted, so Undo can bring it back and a sync can send it.
  Future<Undo> delete(String id) async {
    await _setDeleted(id, now);
    return () => _setDeleted(id, null);
  }

  /// A copy dated today.
  Future<(String, Undo)> duplicate(String id) async {
    final v = (await find(id))!;
    final drafts = [
      for (final p in v.postings)
        PostingDraft(
          accountId: p.accountId,
          categoryId: p.categoryId,
          amountMinor: p.amountMinor,
          currency: p.currency,
          baseMinor: p.baseMinor,
        ),
    ];
    return _insert(
      type: v.type,
      day: today,
      title: v.entry.title,
      merchant: v.entry.merchant,
      note: v.entry.note,
      postings: drafts,
      needsReview: v.needsReview,
    );
  }

  // ---- Reading ----

  Future<EntryView?> find(String id) async {
    final e = await (db.select(db.entries)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (e == null) return null;
    return EntryView(
      e,
      await (db.select(db.postings)..where((p) => p.entryId.equals(id) & p.deletedAt.isNull())).get(),
    );
  }

  Stream<EntryView?> watchOne(String id) => (db.select(db.entries)..where((x) => x.id.equals(id)))
      .watchSingleOrNull()
      .asyncMap((e) async => e == null || e.deletedAt != null ? null : find(id));

  /// Entries, newest first, for lists and drill-downs.
  Stream<List<EntryView>> watchEntries(EntryQuery q) {
    final where = <String>['e.deleted_at IS NULL'];
    final vars = <Variable<Object>>[];
    void add(String clause, List<Object> values) {
      where.add(clause);
      vars.addAll(values.map((v) => v is int ? Variable.withInt(v) : Variable.withString(v as String)));
    }

    if (q.start != null) add('e.day >= ?', [q.start!]);
    if (q.end != null) add('e.day <= ?', [q.end!]);
    if (q.type != null) add('e.type = ?', [q.type!.name]);
    if (q.needsReview != null) add('e.needs_review = ?', [q.needsReview! ? 1 : 0]);
    if (q.accountId != null) {
      add(
        'EXISTS (SELECT 1 FROM postings p WHERE p.entry_id = e.id AND p.account_id = ? AND p.deleted_at IS NULL)',
        [q.accountId!],
      );
    }
    if (q.categoryId != null) {
      add(
        'EXISTS (SELECT 1 FROM postings p JOIN categories c ON c.id = p.category_id WHERE p.entry_id = e.id AND p.deleted_at IS NULL AND (c.id = ? OR c.parent_id = ?))',
        [q.categoryId!, q.categoryId!],
      );
    }
    final search = q.search?.trim() ?? '';
    if (search.isNotEmpty) {
      final amount = amountQuery(search);
      if (amount != null) {
        add(
          'EXISTS (SELECT 1 FROM postings p WHERE p.entry_id = e.id AND p.deleted_at IS NULL AND ABS(p.amount_minor) = ?)',
          [amount],
        );
      } else {
        for (final word in fold(search).split(RegExp(r'\s+'))) {
          add("e.search_text LIKE ? ESCAPE '\\'", [
            '%${word.replaceAll('%', r'\%').replaceAll('_', r'\_')}%',
          ]);
        }
      }
    }
    final sql =
        'SELECT e.* FROM entries e WHERE ${where.join(' AND ')} ORDER BY e.day DESC, e.created_at DESC LIMIT ${q.limit}';
    return db.customSelect(sql, variables: vars, readsFrom: {db.entries, db.postings}).watch().asyncMap((
      rows,
    ) async {
      final entries = rows.map((r) => db.entries.map(r.data)).toList();
      if (entries.isEmpty) return <EntryView>[];
      final postings = await (db.select(
        db.postings,
      )..where((p) => p.entryId.isIn(entries.map((e) => e.id)) & p.deletedAt.isNull())).get();
      final byEntry = <String, List<Posting>>{};
      for (final p in postings) {
        byEntry.putIfAbsent(p.entryId, () => []).add(p);
      }
      return [for (final e in entries) EntryView(e, byEntry[e.id] ?? const [])];
    });
  }

  /// Income and spending for a period, by top-level category, in EUR.
  Stream<PeriodTotals> watchTotals(String start, String end) => db
      .customSelect(
        '''
        SELECT COALESCE(c.parent_id, c.id) AS category, c.kind AS kind, SUM(p.base_minor) AS total
        FROM postings p
        JOIN entries e ON e.id = p.entry_id
        JOIN categories c ON c.id = p.category_id
        WHERE e.deleted_at IS NULL AND p.deleted_at IS NULL AND e.day BETWEEN ? AND ? AND c.kind IN ('expense', 'income')
        GROUP BY category, c.kind
        ''',
        variables: [Variable.withString(start), Variable.withString(end)],
        readsFrom: {db.postings, db.entries, db.categories},
      )
      .watch()
      .map(_toTotals);

  Future<PeriodTotals> totals(String start, String end) => watchTotals(start, end).first;

  PeriodTotals _toTotals(List<QueryRow> rows) {
    final spending = <CategoryAmount>[];
    final income = <CategoryAmount>[];
    for (final r in rows) {
      final total = r.read<int>('total');
      if (r.read<String>('kind') == 'expense') {
        if (total != 0) spending.add(CategoryAmount(r.read<String>('category'), -total));
      } else if (total != 0) {
        income.add(CategoryAmount(r.read<String>('category'), total));
      }
    }
    spending.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    income.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return PeriodTotals(
      incomeMinor: income.fold(0, (s, c) => s + c.amountMinor),
      spendingMinor: spending.fold(0, (s, c) => s + c.amountMinor),
      spendingByCategory: spending,
      incomeByCategory: income,
    );
  }

  /// Each day's spending, income, entry count, top category and paid repeats, for the calendar.
  /// Days without entries are left out.
  Stream<Map<String, DayTotals>> watchDayTotals(String start, String end) => db
      .customSelect(
        '''
        SELECT e.day AS day, COALESCE(c.parent_id, c.id) AS category, c.kind AS kind, SUM(p.base_minor) AS total
        FROM postings p
        JOIN entries e ON e.id = p.entry_id
        JOIN categories c ON c.id = p.category_id
        WHERE e.deleted_at IS NULL AND p.deleted_at IS NULL AND e.day BETWEEN ? AND ? AND c.kind IN ('expense', 'income')
        GROUP BY e.day, category, c.kind
        ''',
        variables: [Variable.withString(start), Variable.withString(end)],
        readsFrom: {db.postings, db.entries, db.categories},
      )
      .watch()
      .asyncMap((rows) async {
        final days = await db
            .customSelect(
              'SELECT day, COUNT(*) AS n, MAX(repeat_id IS NOT NULL) AS paid FROM entries '
              'WHERE deleted_at IS NULL AND day BETWEEN ? AND ? GROUP BY day',
              variables: [Variable.withString(start), Variable.withString(end)],
            )
            .get();
        final spent = <String, int>{};
        final income = <String, int>{};
        final top = <String, (String, int)>{};
        for (final r in rows) {
          final day = r.read<String>('day');
          final total = r.read<int>('total');
          if (r.read<String>('kind') == 'expense') {
            spent[day] = (spent[day] ?? 0) - total;
            final best = top[day];
            if (-total > 0 && (best == null || -total > best.$2)) {
              top[day] = (r.read<String>('category'), -total);
            }
          } else {
            income[day] = (income[day] ?? 0) + total;
          }
        }
        return {
          for (final d in days)
            d.read<String>('day'): DayTotals(
              spentMinor: spent[d.read<String>('day')] ?? 0,
              incomeMinor: income[d.read<String>('day')] ?? 0,
              count: d.read<int>('n'),
              topCategoryId: top[d.read<String>('day')]?.$1,
              hasRepeat: d.read<int>('paid') == 1,
            ),
        };
      });

  /// Spending inside one category, split by its subcategories, in EUR.
  Stream<List<CategoryAmount>> watchSubcategoryTotals(String parentId, String start, String end) => db
      .customSelect(
        '''
        SELECT c.id AS category, -SUM(p.base_minor) AS total
        FROM postings p JOIN entries e ON e.id = p.entry_id JOIN categories c ON c.id = p.category_id
        WHERE e.deleted_at IS NULL AND p.deleted_at IS NULL AND e.day BETWEEN ? AND ? AND (c.id = ? OR c.parent_id = ?)
        GROUP BY c.id ORDER BY total DESC
        ''',
        variables: [
          Variable.withString(start),
          Variable.withString(end),
          Variable.withString(parentId),
          Variable.withString(parentId),
        ],
        readsFrom: {db.postings, db.entries, db.categories},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            if (r.read<int>('total') != 0) CategoryAmount(r.read<String>('category'), r.read<int>('total')),
        ],
      );

  /// Every title with the category and account it was used with, for title memory.
  Stream<List<TitleMemory>> watchTitleMemory() => db
      .customSelect(
        '''
        SELECT e.title AS title, e.type AS kind, p.category_id AS category, p.account_id AS account,
               COUNT(*) AS n, SUM(e.day >= ?) AS recent, MAX(e.day || ':' || ABS(p.amount_minor)) AS last
        FROM entries e JOIN postings p ON p.entry_id = e.id AND p.category_id IS NOT NULL AND p.deleted_at IS NULL
        WHERE e.deleted_at IS NULL AND e.title IS NOT NULL AND e.needs_review = 0 AND e.type IN ('expense', 'income')
        GROUP BY lower(e.title), e.type, p.category_id, p.account_id
        ''',
        variables: [Variable.withString(Day.add(today, -90))],
        readsFrom: {db.entries, db.postings},
      )
      .watch()
      .map(
        (rows) => rememberTitles([
          for (final r in rows)
            TitleUse(
              title: r.read<String>('title'),
              kind: r.read<String>('kind'),
              categoryId: r.read<String>('category'),
              accountId: r.read<String>('account'),
              count: r.read<int>('n'),
              recentCount: r.read<int>('recent'),
              lastAmountMinor: int.parse(r.read<String>('last').split(':').last),
            ),
        ]),
      );

  /// Categories used most on an account in the last 90 days, for the chips on the Add sheet.
  Future<List<String>> mostUsedCategories(String accountId, String kind, {int limit = 6}) async {
    final rows = await db
        .customSelect(
          '''
      SELECT p.category_id AS category, COUNT(*) AS n
      FROM postings p JOIN entries e ON e.id = p.entry_id JOIN categories c ON c.id = p.category_id
      WHERE e.deleted_at IS NULL AND p.deleted_at IS NULL AND p.account_id = ? AND c.kind = ? AND e.day >= ?
        AND c.archived = 0 AND c.deleted_at IS NULL AND c.id NOT IN (?, ?)
      GROUP BY p.category_id ORDER BY n DESC LIMIT ?
      ''',
          variables: [
            Variable.withString(accountId),
            Variable.withString(kind),
            Variable.withString(Day.add(today, -90)),
            Variable.withString(SystemIds.uncategorised),
            Variable.withString(SystemIds.untracked),
            Variable.withInt(limit),
          ],
          readsFrom: {db.postings, db.entries, db.categories},
        )
        .get();
    return [for (final r in rows) r.read<String>('category')];
  }

  // ---- Internals ----

  Future<Account> _account(String id) async {
    final a = await (db.select(db.accounts)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (a == null) throw RuleException('That account no longer exists.');
    return a;
  }

  Future<(String, Undo)> _insert({
    required EntryType type,
    required String day,
    String? title,
    String? merchant,
    String? note,
    required List<PostingDraft> postings,
    bool needsReview = false,
    String? refundOfId,
    String? repeatId,
    String? repeatDay,
  }) async {
    checkBalanced(postings);
    final id = newId();
    await db.transaction(() async {
      await db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              id: id,
              type: type.name,
              day: day,
              title: Value(_blankToNull(title)),
              merchant: Value(_blankToNull(merchant)),
              note: Value(_blankToNull(note)),
              searchText: Value(_searchText(title, merchant, note)),
              needsReview: Value(needsReview),
              refundOfId: Value(refundOfId),
              repeatId: Value(repeatId),
              repeatDay: Value(repeatDay),
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (final p in postings) {
        await db
            .into(db.postings)
            .insert(
              PostingsCompanion.insert(
                id: newId(),
                entryId: id,
                accountId: p.accountId,
                categoryId: Value(p.categoryId),
                amountMinor: p.amountMinor,
                currency: p.currency,
                baseMinor: p.baseMinor,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
    // Undoing a save removes the entry entirely, so a repeat can be paid again for the same date.
    return (id, () => purge(id));
  }

  /// Removes an entry for good. Only used to undo a save that has just happened.
  Future<void> purge(String id) => db.transaction(() async {
    await (db.delete(db.postings)..where((p) => p.entryId.equals(id))).go();
    await (db.delete(db.entries)..where((e) => e.id.equals(id))).go();
  });

  Future<void> _setDeleted(String id, DateTime? when) => db.transaction(() async {
    await (db.update(
      db.entries,
    )..where((e) => e.id.equals(id))).write(EntriesCompanion(deletedAt: Value(when), updatedAt: Value(now)));
    await (db.update(db.postings)..where((p) => p.entryId.equals(id))).write(
      PostingsCompanion(deletedAt: Value(when), updatedAt: Value(now)),
    );
  });

  Future<void> _touch(String id) =>
      (db.update(db.entries)..where((e) => e.id.equals(id))).write(EntriesCompanion(updatedAt: Value(now)));

  /// Puts an entry and its postings back exactly as they were.
  Future<void> _restore(EntryView before) => db.transaction(() async {
    await db.update(db.entries).replace(before.entry.copyWith(updatedAt: now));
    for (final p in before.postings) {
      await db.update(db.postings).replace(p.copyWith(updatedAt: now));
    }
  });

  static String? _blankToNull(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
  static String _searchText(String? title, String? merchant, String? note) =>
      fold([title, merchant, note].whereType<String>().join(' '));
}
