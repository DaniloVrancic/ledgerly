// A searchable list of categories and subcategories, with New category at the end.
// Used inside the Add sheet and on its own when an entry changes category.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/text.dart';
import '../../data/repositories/category_repository.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import 'category_form.dart';

class CategoryPicker extends ConsumerStatefulWidget {
  const CategoryPicker({
    super.key,
    required this.kind,
    this.accountId,
    required this.onPicked,
    this.showAllAccounts = false,
  });

  final String kind;

  /// Shows only the categories offered for this account, unless [showAllAccounts].
  final String? accountId;
  final bool showAllAccounts;
  final ValueChanged<String> onPicked;

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  String _query = '';
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(categoryBookProvider);
    if (_creating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _creating = false),
                icon: const LedgerIcon('chevron'),
                tooltip: 'Back to the list',
              ),
              Text('New category', style: context.text.title),
            ],
          ),
          const SizedBox(height: 8),
          CategoryForm(
            kind: CategoryKind.values.byName(widget.kind),
            forAccountId: widget.accountId,
            onDone: widget.onPicked,
          ),
        ],
      );
    }
    final q = fold(_query);
    final list = book
        .choosable(widget.kind, accountId: widget.showAllAccounts ? null : widget.accountId)
        .where((c) => q.isEmpty || fold(c.name).contains(q))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search categories',
            prefixIcon: Padding(padding: EdgeInsets.all(12), child: LedgerIcon('search')),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No category with that name for this account.', style: context.text.bodySmall),
          ),
        for (final c in list)
          ListTile(
            contentPadding: EdgeInsets.only(left: c.parentId == null ? 0 : 24),
            leading: CategoryAvatar.of(c, size: c.parentId == null ? 40 : 32),
            title: Text(c.name),
            onTap: () => widget.onPicked(c.id),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(() => _creating = true),
          icon: const LedgerIcon('plus'),
          label: const Text('New category'),
        ),
      ],
    );
  }
}

/// Opens the picker in its own sheet and returns the chosen category.
Future<String?> pickCategory(BuildContext context, {required String kind, String? accountId}) =>
    showLedgerSheet<String>(
      context,
      (sheetContext) => SheetBody(
        title: 'Choose a category',
        children: [
          CategoryPicker(
            kind: kind,
            accountId: accountId,
            showAllAccounts: true,
            onPicked: (id) => Navigator.pop(sheetContext, id),
          ),
        ],
      ),
    );
