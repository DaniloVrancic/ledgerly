// The form for a new budget or a changed limit. What a budget covers and how often it resets
// are fixed once it exists; to change those, delete it and make a new one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/budget_repository.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';
import '../categories/category_picker.dart';
import 'budgets_screen.dart';

Future<void> openBudgetForm(BuildContext context, {Budget? existing}) =>
    showLedgerSheet(context, (_) => _BudgetForm(existing: existing));

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({this.existing});

  final Budget? existing;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  late final _limit = TextEditingController(
    text: widget.existing == null ? '' : amountText(widget.existing!.limitMinor),
  );
  bool _allSpending = false;
  String? _categoryId;
  String _every = BudgetEvery.monthly;

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(budgetRepositoryProvider);
    final book = ref.read(categoryBookProvider);
    try {
      final limit = parseAmount(_limit.text);
      final existing = widget.existing;
      if (existing != null) {
        await repo.update(existing.id, limitMinor: limit);
      } else {
        if (!_allSpending && _categoryId == null) throw BudgetException('Choose a category.');
        await repo.create(categoryId: _allSpending ? null : _categoryId, limitMinor: limit, every: _every);
      }
      if (!mounted) return;
      showUndo(
        context,
        existing != null
            ? 'Limit changed'
            : 'Budget for ${_allSpending ? 'all spending' : book.nameOf(_categoryId)} added',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showProblem(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(categoryBookProvider);
    final existing = widget.existing;
    return SheetBody(
      title: existing == null ? 'New budget' : 'Change the limit',
      subtitle: existing == null
          ? 'Spending is counted in EUR. Ledgerly warns you at 80% and shows when it goes over.'
          : budgetName(existing, book),
      children: [
        if (existing == null) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('One category')),
              ButtonSegment(value: true, label: Text('All spending')),
            ],
            selected: {_allSpending},
            onSelectionChanged: (s) => setState(() => _allSpending = s.first),
          ),
          const SizedBox(height: 12),
          if (!_allSpending) ...[
            PillButton(
              label: _categoryId == null ? 'Choose a category' : book.fullName(_categoryId),
              icon: 'tag',
              selected: _categoryId != null,
              onPressed: () async {
                final picked = await pickCategory(context, kind: 'expense');
                if (picked != null) setState(() => _categoryId = picked);
              },
            ),
            const SizedBox(height: 4),
            Text(
              'A category includes its subcategories. You can also choose just a subcategory.',
              style: context.text.caption,
            ),
            const SizedBox(height: 12),
          ],
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: BudgetEvery.monthly, label: Text('Monthly')),
              ButtonSegment(value: BudgetEvery.weekly, label: Text('Weekly')),
            ],
            selected: {_every},
            onSelectionChanged: (s) => setState(() => _every = s.first),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _limit,
          autofocus: existing != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Limit, EUR'),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: Text(existing == null ? 'Save budget' : 'Save limit')),
      ],
    );
  }
}
