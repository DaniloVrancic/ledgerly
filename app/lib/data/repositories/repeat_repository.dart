// Repeats such as rent, Netflix or electricity. A repeat turns Due on its date and waits:
// nothing is posted until the person marks it paid, so nothing is ever posted twice.

import 'package:drift/drift.dart';

import '../../core/day.dart';
import '../../core/ids.dart';
import '../../core/text.dart';
import '../../domain/postings.dart';
import '../../domain/repeat_schedule.dart';
import '../database/app_database.dart';
import 'entry_repository.dart';
import 'repository.dart';

class RepeatRepository extends Repository {
  RepeatRepository(super.db, super.clock, this.entries);

  final EntryRepository entries;

  /// Every active repeat, the next one first.
  Stream<List<Repeat>> watchAll() =>
      (db.select(db.repeats)
            ..where((r) => r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm(expression: r.nextDay), (r) => OrderingTerm(expression: r.title)]))
          .watch();

  Future<Repeat?> find(String id) => (db.select(db.repeats)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// The active repeat with this title, ignoring case and diacritics.
  Future<Repeat?> findByTitle(String title, String kind) async {
    final all = await (db.select(db.repeats)..where((r) => r.deletedAt.isNull() & r.kind.equals(kind))).get();
    for (final r in all) {
      if (fold(r.title) == fold(title)) return r;
    }
    return null;
  }

  Future<String> create({
    required String title,
    required String kind,
    required String categoryId,
    required String accountId,
    required int amountMinor,
    required Every every,
    required String nextDay,
    bool varies = false,
  }) async {
    if (title.trim().isEmpty) throw RuleException('Give the repeat a title.');
    if (amountMinor <= 0) throw RuleException('Enter an amount above zero.');
    final id = newId();
    await db
        .into(db.repeats)
        .insert(
          RepeatsCompanion.insert(
            id: id,
            title: title.trim(),
            kind: kind,
            categoryId: categoryId,
            accountId: accountId,
            amountMinor: amountMinor,
            every: every.name,
            nextDay: nextDay,
            anchorDay: Day.dayOfMonth(nextDay),
            varies: Value(varies),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Changes saved straight away from the edit form.
  Future<void> update(
    String id, {
    String? title,
    String? categoryId,
    String? accountId,
    int? amountMinor,
    Every? every,
    String? nextDay,
    bool? varies,
  }) {
    if (title != null && title.trim().isEmpty) throw RuleException('Give the repeat a title.');
    if (amountMinor != null && amountMinor <= 0) throw RuleException('Enter an amount above zero.');
    return (db.update(db.repeats)..where((r) => r.id.equals(id))).write(
      RepeatsCompanion(
        title: title == null ? const Value.absent() : Value(title.trim()),
        categoryId: categoryId == null ? const Value.absent() : Value(categoryId),
        accountId: accountId == null ? const Value.absent() : Value(accountId),
        amountMinor: amountMinor == null ? const Value.absent() : Value(amountMinor),
        every: every == null ? const Value.absent() : Value(every.name),
        nextDay: nextDay == null ? const Value.absent() : Value(nextDay),
        anchorDay: nextDay == null ? const Value.absent() : Value(Day.dayOfMonth(nextDay)),
        varies: varies == null ? const Value.absent() : Value(varies),
        updatedAt: Value(now),
      ),
    );
  }

  /// Stops a repeat. Entries already paid stay as they are.
  Future<Undo> stop(String id) async {
    await (db.update(
      db.repeats,
    )..where((r) => r.id.equals(id))).write(RepeatsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    return () => (db.update(db.repeats)..where((r) => r.id.equals(id))).write(
      RepeatsCompanion(deletedAt: const Value(null), updatedAt: Value(now)),
    );
  }

  /// Records this occurrence as paid and moves the repeat to its next date.
  /// [amountMinor] is this time's amount, for repeats whose amount varies.
  Future<Undo> markPaid(
    String id, {
    int? amountMinor,
    String? title,
    String? merchant,
    String? note,
    String? accountId,
  }) async {
    final r = (await find(id))!;
    final amount = amountMinor ?? r.amountMinor;
    late final Undo undoEntry;
    await db.transaction(() async {
      final (_, undo) = await entries.addEntry(
        isExpense: r.kind == 'expense',
        accountId: accountId ?? r.accountId,
        amountMinor: amount,
        categoryId: r.categoryId,
        title: title ?? r.title,
        merchant: merchant,
        note: note,
        // A daily repeat is dated the day it was for; others are dated when they were paid.
        day: Every.parse(r.every) == Every.daily ? r.nextDay : today,
        repeatId: r.id,
        repeatDay: r.nextDay,
      );
      undoEntry = undo;
      await _moveOn(r, newAmount: r.varies ? amount : null);
    });
    return () async {
      await undoEntry();
      await db.update(db.repeats).replace(r.copyWith(updatedAt: now));
    };
  }

  /// Leaves this occurrence unpaid and moves to the next date.
  Future<Undo> skip(String id) async {
    final r = (await find(id))!;
    await _moveOn(r);
    return () => db.update(db.repeats).replace(r.copyWith(updatedAt: now));
  }

  Future<void> _moveOn(Repeat r, {int? newAmount}) =>
      (db.update(db.repeats)..where((x) => x.id.equals(r.id))).write(
        RepeatsCompanion(
          nextDay: Value(advance(r.nextDay, Every.parse(r.every), r.anchorDay)),
          amountMinor: newAmount == null ? const Value.absent() : Value(newAmount),
          updatedAt: Value(now),
        ),
      );
}
