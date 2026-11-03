// Categories and subcategories, including the person's own. A category in use is never
// destroyed: deleting it first moves its entries and repeats to another category.

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/system_ids.dart';
import '../database/app_database.dart';
import 'repository.dart';

enum CategoryKind { expense, income }

class CategoryException implements Exception {
  CategoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CategoryRepository extends Repository {
  CategoryRepository(super.db, super.clock);

  /// Every category that is not deleted, archived ones included, in their order.
  Stream<List<LedgerCategory>> watchAll() => (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder), (c) => OrderingTerm(expression: c.name)]))
      .watch();

  Future<List<LedgerCategory>> all() => (db.select(db.categories)..where((c) => c.deletedAt.isNull())).get();

  /// Which accounts each limited category applies to. Categories that are not listed apply to all.
  Stream<Map<String, Set<String>>> watchAccountLimits() =>
      (db.select(db.categoryAccounts)..where((l) => l.deletedAt.isNull())).watch().map((rows) {
        final out = <String, Set<String>>{};
        for (final r in rows) {
          out.putIfAbsent(r.categoryId, () => {}).add(r.accountId);
        }
        return out;
      });

  Future<String> create({
    required String name,
    required CategoryKind kind,
    String? parentId,
    required String icon,
    String? imagePath,
    required int colorSlot,
    Set<String> accountIds = const {},
  }) async {
    final clean = _cleanName(name);
    final id = newId();
    final order = await db.categories.count().getSingle();
    await db.transaction(() async {
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id,
            name: clean,
            kind: kind.name,
            parentId: Value(parentId),
            icon: icon,
            imagePath: Value(imagePath),
            colorSlot: Value(colorSlot),
            isCustom: const Value(true),
            sortOrder: Value(order),
            createdAt: now,
            updatedAt: now,
          ));
      if (parentId == null) await _writeAccounts(id, accountIds);
    });
    return id;
  }

  Future<void> update(String id, {String? name, String? icon, String? imagePath, bool clearImage = false, int? colorSlot}) =>
      (db.update(db.categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(
        name: name == null ? const Value.absent() : Value(_cleanName(name)),
        icon: icon == null ? const Value.absent() : Value(icon),
        imagePath: clearImage ? const Value(null) : (imagePath == null ? const Value.absent() : Value(imagePath)),
        colorSlot: colorSlot == null ? const Value.absent() : Value(colorSlot),
        updatedAt: Value(now),
      ));

  /// Limits a category to some accounts on the Add sheet. An empty set means every account.
  Future<void> setAccounts(String id, Set<String> accountIds) => db.transaction(() => _writeAccounts(id, accountIds));

  Future<void> _writeAccounts(String id, Set<String> accountIds) async {
    await (db.update(db.categoryAccounts)..where((l) => l.categoryId.equals(id) & l.deletedAt.isNull()))
        .write(CategoryAccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    for (final accountId in accountIds) {
      await db.into(db.categoryAccounts).insert(CategoryAccountsCompanion.insert(
            id: newId(),
            categoryId: id,
            accountId: accountId,
            createdAt: now,
            updatedAt: now,
          ));
    }
  }

  /// Archived categories leave the Add sheet but stay in history and reports.
  Future<Undo> setArchived(String id, bool archived) async {
    await (db.update(db.categories)..where((c) => c.id.equals(id) | c.parentId.equals(id)))
        .write(CategoriesCompanion(archived: Value(archived), updatedAt: Value(now)));
    return () => setArchived(id, !archived);
  }

  /// How many entries and repeats use a category or its subcategories.
  Future<int> usageCount(String id) async {
    final row = await db.customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM postings p JOIN entries e ON e.id = p.entry_id WHERE e.deleted_at IS NULL AND p.deleted_at IS NULL '
      '  AND p.category_id IN (SELECT id FROM categories WHERE id = ?1 OR parent_id = ?1)) + '
      '(SELECT COUNT(*) FROM repeats r WHERE r.deleted_at IS NULL AND r.category_id IN (SELECT id FROM categories WHERE id = ?1 OR parent_id = ?1)) AS n',
      variables: [Variable.withString(id)],
    ).getSingle();
    return row.read<int>('n');
  }

  /// Deletes a category and its subcategories, moving everything that used them to [moveTo].
  Future<void> deleteAndMove(String id, {String? moveTo}) async {
    if (SystemIds.hiddenCategories.contains(id)) throw CategoryException('This category belongs to the app.');
    final ids = [id, ...(await (db.select(db.categories)..where((c) => c.parentId.equals(id))).get()).map((c) => c.id)];
    if (moveTo != null && ids.contains(moveTo)) throw CategoryException('Choose a category outside the one being deleted.');
    final used = await usageCount(id);
    if (used > 0 && moveTo == null) throw CategoryException('Choose where its $used entries go first, or archive it instead.');
    await db.transaction(() async {
      if (moveTo != null) {
        await (db.update(db.postings)..where((p) => p.categoryId.isIn(ids))).write(PostingsCompanion(categoryId: Value(moveTo), updatedAt: Value(now)));
        await (db.update(db.repeats)..where((r) => r.categoryId.isIn(ids))).write(RepeatsCompanion(categoryId: Value(moveTo), updatedAt: Value(now)));
      }
      await (db.update(db.categories)..where((c) => c.id.isIn(ids))).write(CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (db.update(db.categoryAccounts)..where((l) => l.categoryId.isIn(ids))).write(CategoryAccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    });
  }

  String _cleanName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw CategoryException('Enter a name for this category.');
    if (clean.length > 32) throw CategoryException('Keep the name to 32 characters.');
    return clean;
  }
}
