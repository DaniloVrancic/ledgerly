// Budgets: a spending limit per month or week, for all spending, a category or a subcategory.
// Spending is read from the same postings as Home and Insights, so the figures always agree.

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../database/app_database.dart';
import 'repository.dart';

abstract final class BudgetEvery {
  static const monthly = 'monthly';
  static const weekly = 'weekly';
  static const all = [monthly, weekly];
}

class BudgetException implements Exception {
  BudgetException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BudgetRepository extends Repository {
  BudgetRepository(super.db, super.clock);

  /// The key for all spending in [watchSpending].
  static const overall = '';

  /// Every budget, oldest first.
  Stream<List<Budget>> watchBudgets() =>
      (db.select(db.budgets)
            ..where((b) => b.deletedAt.isNull())
            ..orderBy([(b) => OrderingTerm(expression: b.createdAt)]))
          .watch();

  /// A new budget. Only one per category and cadence: a second "Food, monthly" is refused.
  Future<String> create({String? categoryId, required int limitMinor, required String every}) async {
    _check(limitMinor, every);
    if (categoryId != null) {
      final category = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(categoryId) & c.deletedAt.isNull())).getSingleOrNull();
      if (category == null || category.kind != 'expense') {
        throw BudgetException('Budgets are for expense categories.');
      }
    }
    final existing =
        await (db.select(db.budgets)..where(
              (b) =>
                  b.deletedAt.isNull() &
                  b.every.equals(every) &
                  (categoryId == null ? b.categoryId.isNull() : b.categoryId.equals(categoryId)),
            ))
            .getSingleOrNull();
    if (existing != null) {
      throw BudgetException(
        every == BudgetEvery.weekly
            ? 'There is already a weekly budget for this.'
            : 'There is already a monthly budget for this.',
      );
    }
    final id = newId();
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: id,
            categoryId: Value(categoryId),
            limitMinor: limitMinor,
            every: every,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> update(String id, {required int limitMinor}) {
    if (limitMinor <= 0) throw BudgetException('Enter a limit above zero.');
    return (db.update(db.budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(limitMinor: Value(limitMinor), updatedAt: Value(now)),
    );
  }

  Future<Undo> delete(String id) async {
    await _setDeleted(id, now);
    return () => _setDeleted(id, null);
  }

  /// Spending from [start] to [end] in EUR: per category and subcategory, each category
  /// including its subcategories, and all spending under [overall]. Refunds lower it.
  Stream<Map<String, int>> watchSpending(String start, String end) => db
      .customSelect(
        '''
        SELECT c.id AS category, c.parent_id AS parent, -SUM(p.base_minor) AS total
        FROM postings p
        JOIN entries e ON e.id = p.entry_id
        JOIN categories c ON c.id = p.category_id
        WHERE e.deleted_at IS NULL AND p.deleted_at IS NULL AND e.day BETWEEN ? AND ? AND c.kind = 'expense'
        GROUP BY c.id, c.parent_id
        ''',
        variables: [Variable.withString(start), Variable.withString(end)],
        readsFrom: {db.postings, db.entries, db.categories},
      )
      .watch()
      .map((rows) {
        final out = <String, int>{overall: 0};
        void add(String key, int amount) => out[key] = (out[key] ?? 0) + amount;
        for (final r in rows) {
          final total = r.read<int>('total');
          add(r.read<String>('category'), total);
          final parent = r.readNullable<String>('parent');
          if (parent != null) add(parent, total);
          add(overall, total);
        }
        return out;
      });

  Future<Map<String, int>> spending(String start, String end) => watchSpending(start, end).first;

  static void _check(int limitMinor, String every) {
    if (limitMinor <= 0) throw BudgetException('Enter a limit above zero.');
    if (!BudgetEvery.all.contains(every)) throw BudgetException('A budget is monthly or weekly.');
  }

  Future<void> _setDeleted(String id, DateTime? when) => (db.update(
    db.budgets,
  )..where((b) => b.id.equals(id))).write(BudgetsCompanion(deletedAt: Value(when), updatedAt: Value(now)));
}
