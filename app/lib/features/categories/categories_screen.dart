// Categories: the place to add your own categories and subcategories, change them, limit them
// to accounts, archive them, or delete them by moving their entries elsewhere.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/category_book.dart';
import '../../app/providers.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/category_repository.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';
import 'category_form.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.expense;
  String? _accountFilter;

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(categoryBookProvider);
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final names = {for (final a in accounts) a.id: a.name};
    final tops = book
        .topLevel(_kind.name, includeArchived: true)
        .where((c) => _accountFilter == null || book.appliesTo(c.id, _accountFilter!))
        .toList();
    final active = tops.where((c) => !c.archived).toList();
    final archived = tops.where((c) => c.archived).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCategoryForm(context, kind: _kind),
        icon: const LedgerIcon('plus'),
        label: const Text('New category'),
        shape: const StadiumBorder(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          SegmentedButton<CategoryKind>(
            segments: const [
              ButtonSegment(value: CategoryKind.expense, label: Text('Expense')),
              ButtonSegment(value: CategoryKind.income, label: Text('Income')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All accounts'),
                selected: _accountFilter == null,
                onSelected: (_) => setState(() => _accountFilter = null),
              ),
              for (final a in accounts)
                ChoiceChip(
                  label: Text(a.name),
                  selected: _accountFilter == a.id,
                  onSelected: (_) => setState(() => _accountFilter = a.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap a category to change it. Your own categories are marked Yours.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final c in active) _CategoryGroup(category: c, book: book, accountNames: names),
              ],
            ),
          ),
          if (archived.isNotEmpty) ...[
            const SectionHeader('Archived'),
            Text(
              'Archived categories are not offered for new entries, but stay in history and reports.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final c in archived) _CategoryGroup(category: c, book: book, accountNames: names),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({required this.category, required this.book, required this.accountNames});

  final LedgerCategory category;
  final CategoryBook book;
  final Map<String, String> accountNames;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final children = book.childrenOf(category.id, includeArchived: true);
    final limit = book.limits[category.id];
    final where = limit == null || limit.isEmpty
        ? 'All accounts'
        : limit.map((id) => accountNames[id] ?? '').where((n) => n.isNotEmpty).join(', ');
    return Column(
      children: [
        ListTile(
          leading: CategoryAvatar.of(category),
          title: Text(category.name),
          subtitle: Row(
            children: [
              if (category.isCustom) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: c.neutralTint, borderRadius: BorderRadius.circular(6)),
                  child: Text('Yours', style: context.text.caption.copyWith(color: c.neutral)),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(child: Text(category.archived ? 'Archived, kept in history' : where)),
            ],
          ),
          trailing: const LedgerIcon('chevron'),
          onTap: () => openCategoryForm(context, existing: category),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(68, 0, 12, 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final sub in children)
                ActionChip(
                  avatar: LedgerIcon(sub.icon, size: 16, color: c.category(sub.colorSlot)),
                  label: Text(sub.name),
                  onPressed: () => openCategoryForm(context, existing: sub),
                ),
              if (category.kind == 'expense' && !category.archived)
                ActionChip(
                  avatar: LedgerIcon('plus', size: 16, color: c.accent),
                  label: const Text('Subcategory'),
                  onPressed: () =>
                      openCategoryForm(context, kind: CategoryKind.expense, parentId: category.id),
                ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// Opens the category form in a sheet, with archive and delete for an existing category.
Future<void> openCategoryForm(
  BuildContext context, {
  LedgerCategory? existing,
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
}) {
  return showLedgerSheet(context, (sheetContext) {
    return Consumer(
      builder: (context, ref, _) {
        final title = existing != null
            ? 'Edit ${existing.parentId == null ? 'category' : 'subcategory'}'
            : (parentId != null ? 'New subcategory' : 'New category');
        return SheetBody(
          title: title,
          children: [
            CategoryForm(
              existing: existing,
              kind: kind,
              parentId: parentId,
              onDone: (_) {
                Navigator.of(sheetContext).pop();
                showUndo(context, existing == null ? 'Category added' : 'Changes saved');
              },
            ),
            if (existing != null && !existing.isCustom && existing.parentId == null)
              const SizedBox(height: 8),
            if (existing != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const LedgerIcon('archive'),
                label: Text(existing.archived ? 'Bring back from the archive' : 'Archive'),
                onPressed: () async {
                  final undo = await ref
                      .read(categoryRepositoryProvider)
                      .setArchived(existing.id, !existing.archived);
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  showUndo(
                    context,
                    existing.archived ? '${existing.name} is back' : '${existing.name} archived',
                    undo: undo,
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.negative,
                  side: BorderSide(color: context.colors.negative),
                ),
                onPressed: () async {
                  final deleted = await confirmCategoryDelete(context, ref, existing);
                  if (deleted && sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ],
        );
      },
    );
  });
}

/// Deleting a category in use means moving its entries first. This is one of the few dialogs.
Future<bool> confirmCategoryDelete(BuildContext context, WidgetRef ref, LedgerCategory category) async {
  final repo = ref.read(categoryRepositoryProvider);
  final book = ref.read(categoryBookProvider);
  final used = await repo.usageCount(category.id);
  final options = book
      .choosable(category.kind)
      .where((c) => c.id != category.id && c.parentId != category.id)
      .toList();
  String? moveTo = used > 0 && options.isNotEmpty ? options.first.id : null;
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              used == 0
                  ? 'No entries use it.'
                  : '$used ${used == 1 ? 'entry uses' : 'entries use'} it, with its subcategories. They move to the category you choose. To keep them where they are, archive it instead.',
            ),
            if (used > 0) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: moveTo,
                decoration: const InputDecoration(labelText: 'Move entries to'),
                items: [
                  for (final c in options)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(book.fullName(c.id), overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => moveTo = v),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.negative),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(used == 0 ? 'Delete' : 'Move and delete'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  try {
    await repo.deleteAndMove(category.id, moveTo: moveTo);
    if (context.mounted) showUndo(context, '${category.name} deleted');
    return true;
  } catch (e) {
    if (context.mounted) showProblem(context, e);
    return false;
  }
}
