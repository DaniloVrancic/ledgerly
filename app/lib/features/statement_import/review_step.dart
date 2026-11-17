// The statement compared with the account: rows already recorded, rows to add, likely
// duplicates and rows that could not be read. Rows to add are ticked unless they need a
// choice; money coming in needs an income category before it can be added.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../domain/statement/statement_mapping.dart';
import '../../domain/statement/statement_match.dart';
import '../../domain/title_memory.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';
import '../categories/category_picker.dart';

class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key, required this.rows, required this.accountId, required this.onDone});

  final List<StatementRow> rows;
  final String accountId;
  final VoidCallback onDone;

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  List<ReviewRow>? _review;
  final _ticked = <int>{};
  final _category = <int, String>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final days = [for (final r in widget.rows) ?r.day]..sort();
    final existing = days.isEmpty
        ? const <ExistingEntry>[]
        : await ref
              .read(entryRepositoryProvider)
              .signedAmountsOnAccount(widget.accountId, Day.add(days.first, -3), Day.add(days.last, 3));
    final review = reviewStatement(widget.rows, existing);
    final memory = ref.read(titleMemoryProvider).value ?? const <TitleMemory>[];
    if (!mounted) return;
    setState(() {
      _review = review;
      for (final (i, r) in review.indexed) {
        if (r.status != RowStatus.toAdd) continue;
        final known = exactTitle(memory, r.row.description, r.row.amountMinor < 0 ? 'expense' : 'income');
        if (known != null) _category[i] = known.categoryId;
        if (r.row.amountMinor < 0 || known != null) _ticked.add(i);
      }
    });
  }

  bool _canAdd(int i) => _review![i].row.amountMinor < 0 || _category[i] != null;

  Future<void> _add() async {
    setState(() => _saving = true);
    try {
      final drafts = [
        for (final i in _ticked.toList()..sort())
          ImportDraft(
            day: _review![i].row.day!,
            amountMinor: _review![i].row.amountMinor,
            title: _review![i].row.description,
            categoryId: _category[i],
          ),
      ];
      final (added, undo) = await ref.read(entryRepositoryProvider).importStatement(widget.accountId, drafts);
      if (!mounted) return;
      showUndo(context, 'Added $added ${added == 1 ? 'entry' : 'entries'}', undo: undo);
      widget.onDone();
    } catch (e) {
      if (mounted) {
        showProblem(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    if (review == null) return const Center(child: CircularProgressIndicator());
    final currency =
        (ref.watch(accountsProvider).value ?? const <AccountWithBalance>[])
            .where((a) => a.id == widget.accountId)
            .firstOrNull
            ?.currency ??
        'EUR';
    final book = ref.watch(categoryBookProvider);
    List<int> by(RowStatus s) => [
      for (final (i, r) in review.indexed)
        if (r.status == s) i,
    ];
    final toAdd = by(RowStatus.toAdd);
    final duplicates = by(RowStatus.duplicate);
    final matched = by(RowStatus.matched);
    final invalid = by(RowStatus.invalid);

    Widget row(int i) {
      final r = review[i].row;
      final income = r.amountMinor > 0;
      final category = _category[i];
      return CheckboxListTile(
        value: _ticked.contains(i),
        onChanged: _canAdd(i) ? (v) => setState(() => v == true ? _ticked.add(i) : _ticked.remove(i)) : null,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.only(left: 4, right: 8),
        title: Text(
          r.description.isEmpty ? 'No description' : r.description,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(Day.short(r.day!), style: context.text.caption),
            ActionChip(
              visualDensity: VisualDensity.compact,
              label: Text(
                category != null
                    ? book.nameOf(category)
                    : income
                    ? 'Income needs a category'
                    : 'Needs Review',
              ),
              onPressed: () async {
                final picked = await pickCategory(context, kind: income ? 'income' : 'expense');
                if (picked != null) {
                  setState(() {
                    _category[i] = picked;
                    _ticked.add(i);
                  });
                }
              },
            ),
          ],
        ),
        secondary: Text(
          formatMoney(r.amountMinor, currency, sign: true),
          style: context.text.label.copyWith(color: income ? context.colors.positive : null),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        TileGrid(
          children: [
            _Count(label: 'To add', count: toAdd.length),
            _Count(label: 'Already recorded', count: matched.length),
            _Count(label: 'Likely duplicates', count: duplicates.length),
            _Count(label: 'Could not read', count: invalid.length),
          ],
        ),
        if (toAdd.isNotEmpty) ...[
          const SectionHeader('To add'),
          Text(
            'Without a category, money out waits in Needs Review. Tap a row\'s chip to choose one now.',
            style: context.text.caption,
          ),
          Card(child: Column(children: [for (final i in toAdd) row(i)])),
        ],
        if (duplicates.isNotEmpty) ...[
          const SectionHeader('Likely duplicates'),
          Text(
            'The same date, amount and description appear earlier in the file.',
            style: context.text.caption,
          ),
          Card(child: Column(children: [for (final i in duplicates) row(i)])),
        ],
        if (matched.isNotEmpty) ...[
          const SectionHeader('Already recorded'),
          Card(
            child: Column(
              children: [
                for (final i in matched)
                  ListTile(
                    dense: true,
                    leading: LedgerIcon('check', color: context.colors.positive),
                    title: Text(review[i].row.description, overflow: TextOverflow.ellipsis),
                    subtitle: Text(Day.short(review[i].row.day!)),
                    trailing: Text(formatMoney(review[i].row.amountMinor, currency, sign: true)),
                  ),
              ],
            ),
          ),
        ],
        if (invalid.isNotEmpty) ...[
          const SectionHeader('Could not read'),
          Card(
            child: Column(
              children: [
                for (final i in invalid)
                  ListTile(
                    dense: true,
                    leading: LedgerIcon('alert', color: context.colors.warning),
                    title: Text('Line ${review[i].row.line}: ${review[i].row.error}'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _ticked.isEmpty || _saving ? null : _add,
          child: Text(
            _ticked.isEmpty
                ? 'Nothing to add'
                : 'Add ${_ticked.length} ${_ticked.length == 1 ? 'entry' : 'entries'}',
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => LedgerCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.caption),
        const SizedBox(height: 4),
        Text('$count', style: context.text.amount),
      ],
    ),
  );
}
