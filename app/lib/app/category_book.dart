// Fast lookups over the category list: names, colours, parents, children, and which
// categories an account offers on the Add sheet.

import '../data/database/app_database.dart';
import '../domain/system_ids.dart';

class CategoryBook {
  CategoryBook(List<LedgerCategory> all, this.limits) : _byId = {for (final c in all) c.id: c}, _all = all;

  final List<LedgerCategory> _all;
  final Map<String, LedgerCategory> _byId;

  /// Category id to the accounts it is limited to. Missing means every account.
  final Map<String, Set<String>> limits;

  static final empty = CategoryBook(const [], const {});

  LedgerCategory? operator [](String? id) => id == null ? null : _byId[id];

  String nameOf(String? id) => this[id]?.name ?? 'No category';

  /// "Food · Groceries" for a subcategory, "Food" for a category.
  String fullName(String? id) {
    final c = this[id];
    if (c == null) return 'No category';
    final parent = this[c.parentId];
    return parent == null ? c.name : '${parent.name} · ${c.name}';
  }

  /// The top-level category: itself, or its parent.
  String topOf(String id) => this[id]?.parentId ?? id;

  bool isHidden(String id) => SystemIds.hiddenCategories.contains(id);

  /// Top-level categories of a kind, in order. Archived ones only when asked.
  List<LedgerCategory> topLevel(String kind, {bool includeArchived = false}) => _all
      .where(
        (c) => c.kind == kind && c.parentId == null && !isHidden(c.id) && (includeArchived || !c.archived),
      )
      .toList();

  List<LedgerCategory> childrenOf(String parentId, {bool includeArchived = false}) =>
      _all.where((c) => c.parentId == parentId && (includeArchived || !c.archived)).toList();

  /// Whether a category is offered for an account. Subcategories follow their parent.
  bool appliesTo(String id, String accountId) {
    final accounts = limits[topOf(id)];
    return accounts == null || accounts.isEmpty || accounts.contains(accountId);
  }

  /// Every category and subcategory that can be chosen for an account, in order.
  List<LedgerCategory> choosable(String kind, {String? accountId}) => [
    for (final top in topLevel(kind))
      if (accountId == null || appliesTo(top.id, accountId)) ...[top, ...childrenOf(top.id)],
  ];
}
