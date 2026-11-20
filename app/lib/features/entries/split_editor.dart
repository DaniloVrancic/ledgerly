// Dividing one expense across categories: the parts editor on the Add sheet, and the sheet that
// splits or re-splits a recorded entry from its details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/repositories/entry_view.dart';
import '../../domain/postings.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../categories/category_picker.dart';

/// One part while it is being edited.
class SplitDraft {
  SplitDraft({this.categoryId, int amountMinor = 0})
    : amount = TextEditingController(text: amountMinor > 0 ? amountText(amountMinor) : '');

  String? categoryId;
  final TextEditingController amount;

  int get amountMinor => parseAmount(amount.text);

  void dispose() => amount.dispose();
}

/// The parts, when each has a category and an amount and together they make [totalMinor].
List<SplitPart>? splitPartsOf(List<SplitDraft> drafts, int totalMinor) {
  if (drafts.isEmpty || totalMinor <= 0) return null;
  if (drafts.any((d) => d.categoryId == null || d.amountMinor <= 0)) return null;
  if (drafts.map((d) => d.categoryId).toSet().length != drafts.length) return null;
  if (drafts.fold(0, (s, d) => s + d.amountMinor) != totalMinor) return null;
  return [for (final d in drafts) SplitPart(d.categoryId!, d.amountMinor)];
}

/// Part rows with a category and an amount each, what is left to divide, and Add a part.
class SplitEditor extends ConsumerWidget {
  const SplitEditor({
    super.key,
    required this.parts,
    required this.totalMinor,
    required this.currency,
    required this.accountId,
    required this.onChanged,
  });

  final List<SplitDraft> parts;
  final int totalMinor;
  final String currency;
  final String accountId;

  /// Called after any change, so the owner can rebuild and recheck Save.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final book = ref.watch(categoryBookProvider);
    final left = totalMinor - parts.fold<int>(0, (s, d) => s + d.amountMinor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, d) in parts.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
                    onPressed: () async {
                      final id = await pickCategory(context, kind: 'expense', accountId: accountId);
                      if (id == null) return;
                      d.categoryId = id;
                      onChanged();
                    },
                    child: Text(
                      d.categoryId == null ? 'Choose a category' : book.fullName(d.categoryId),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: TextField(
                    key: ValueKey(d),
                    controller: d.amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      labelText: 'Part ${i + 1}',
                      hintText: left > 0 ? amountText(left) : '0.00',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove part ${i + 1}',
                  icon: const LedgerIcon('x', size: 16),
                  onPressed: parts.length == 1
                      ? null
                      : () {
                          parts.removeAt(i).dispose();
                          onChanged();
                        },
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                left == 0
                    ? 'Fully split'
                    : left > 0
                    ? 'Remaining'
                    : 'Over by',
                style: context.text.label.copyWith(color: left == 0 ? c.positive : c.warning),
              ),
            ),
            Text(
              formatMoney(left.abs(), currency),
              style: context.text.label.copyWith(color: left == 0 ? c.positive : c.warning),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const LedgerIcon('plus', size: 16),
            label: const Text('Add a part'),
            onPressed: () {
              parts.add(SplitDraft(amountMinor: left > 0 ? left : 0));
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}

/// Splits a recorded expense, or changes its parts. Returns the new parts, or null.
/// Parts that share a category, as after a category was deleted into another, are merged.
Future<List<SplitPart>?> showSplitSheet(BuildContext context, {required EntryView entry}) =>
    showLedgerSheet<List<SplitPart>>(context, (_) => _SplitSheet(entry: entry));

class _SplitSheet extends StatefulWidget {
  const _SplitSheet({required this.entry});

  final EntryView entry;

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  late final TextEditingController _total = TextEditingController(
    text: amountText(widget.entry.amountMinor.abs()),
  );
  late final List<SplitDraft> _parts = _start(widget.entry);

  static List<SplitDraft> _start(EntryView v) {
    if (!v.hasParts) {
      return [SplitDraft(categoryId: v.categoryId, amountMinor: v.amountMinor.abs()), SplitDraft()];
    }
    final byCategory = <String, int>{};
    for (final p in v.parts) {
      byCategory[p.categoryId!] = (byCategory[p.categoryId!] ?? 0) - p.amountMinor;
    }
    return [
      for (final MapEntry(:key, :value) in byCategory.entries)
        SplitDraft(categoryId: key, amountMinor: value),
    ];
  }

  @override
  void dispose() {
    _total.dispose();
    for (final d in _parts) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.entry;
    final total = parseAmount(_total.text);
    final parts = splitPartsOf(_parts, total);
    return SheetBody(
      title: v.isSplit ? 'Edit split' : 'Split this',
      subtitle: 'Each part counts as spending in its own category. One part makes it a simple entry again.',
      children: [
        TextField(
          controller: _total,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount, ${v.currency == 'BAM' ? 'KM' : 'EUR'}'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SplitEditor(
          parts: _parts,
          totalMinor: total,
          currency: v.currency,
          accountId: v.accountId,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: parts == null ? null : () => Navigator.pop(context, parts),
          child: const Text('Save split'),
        ),
      ],
    );
  }
}
