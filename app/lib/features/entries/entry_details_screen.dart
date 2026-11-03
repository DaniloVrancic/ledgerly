// One entry, directly editable. Every field saves itself; there is no separate edit mode.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/repositories/entry_view.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../../ui/widgets/undo.dart';
import '../categories/category_picker.dart';
import '../repeats/repeat_form.dart';

class EntryDetailsScreen extends ConsumerStatefulWidget {
  const EntryDetailsScreen({super.key, required this.entryId});

  final String entryId;

  @override
  ConsumerState<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends ConsumerState<EntryDetailsScreen> {
  final _title = TextEditingController();
  final _merchant = TextEditingController();
  final _note = TextEditingController();
  final _amount = TextEditingController();
  bool _loaded = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_title, _merchant, _note, _amount]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(EntryView v) {
    if (_loaded) return;
    _loaded = true;
    _title.text = v.entry.title ?? '';
    _merchant.text = v.entry.merchant ?? '';
    _note.text = v.entry.note ?? '';
    _amount.text = amountText(v.amountMinor.abs());
  }

  /// Text fields save a moment after typing stops.
  void _saveText() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(entryRepositoryProvider)
          .updateDetails(
            widget.entryId,
            title: _title.text,
            merchant: _merchant.text,
            note: _note.text,
            clearMerchant: _merchant.text.trim().isEmpty,
          );
    });
  }

  Future<void> _run(Future<dynamic> Function() change, String message) async {
    try {
      final result = await change();
      if (!mounted) return;
      showUndo(context, message, undo: result is Function ? result as Future<void> Function() : null);
    } catch (e) {
      if (mounted) showProblem(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(entryProvider(widget.entryId));
    final v = async.value;
    if (v == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.isLoading
            ? const SizedBox.shrink()
            : const EmptyState(
                icon: 'search',
                title: 'Entry deleted',
                message: 'This entry is no longer in Ledgerly.',
              ),
      );
    }
    _fill(v);
    final c = context.colors;
    final book = ref.watch(categoryBookProvider);
    final accounts = ref.watch(allAccountsProvider).value ?? const [];
    final accountName = {for (final a in accounts) a.id: a.name};
    final repo = ref.read(entryRepositoryProvider);
    final repeat = (ref.watch(repeatsProvider).value ?? const [])
        .where((r) => r.id == v.entry.repeatId)
        .firstOrNull;
    final isTransfer = v.type == EntryType.transfer;
    final canCategorise =
        v.type == EntryType.expense || v.type == EntryType.income || v.type == EntryType.refund;
    final kindLabel = switch (v.type) {
      EntryType.expense => 'Expense',
      EntryType.income => 'Income',
      EntryType.transfer => 'Transfer',
      EntryType.refund => 'Refund',
      EntryType.adjustment => 'Balance check',
    };

    return Scaffold(
      appBar: AppBar(title: Text(kindLabel)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Center(
            child: MoneyText(
              v.amountMinor,
              currency: v.currency,
              sign: v.amountMinor > 0 && !isTransfer,
              tone: isTransfer || v.type == EntryType.adjustment ? MoneyTone.neutral : MoneyTone.auto,
              style: context.text.balance,
            ),
          ),
          if (v.currency != 'EUR')
            Center(
              child: Text(
                '${formatMoney(toBase(v.amountMinor.abs(), v.currency), 'EUR')} at the fixed rate',
                style: context.text.amountSmall,
              ),
            ),
          if (isTransfer)
            Center(
              child: Text(
                '${accountName[v.accountId] ?? ''} to ${accountName[v.toAccountId] ?? 'Owed to me'}. Never income or spending.',
                style: context.text.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _saveText(),
          ),
          const SizedBox(height: 12),
          if (canCategorise) ...[
            Text('Category', style: context.text.label.copyWith(color: c.textSecondary)),
            const SizedBox(height: 4),
            LedgerCard(
              padding: const EdgeInsets.all(12),
              onTap: () async {
                final id = await pickCategory(
                  context,
                  kind: v.type == EntryType.income ? 'income' : 'expense',
                  accountId: v.accountId,
                );
                if (id != null) _run(() => repo.changeCategory(v.id, id), 'Moved to ${book.nameOf(id)}');
              },
              child: Row(
                children: [
                  CategoryAvatar.of(book[v.categoryId], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      v.needsReview ? 'Choose a category' : book.fullName(v.categoryId),
                      style: context.text.label,
                    ),
                  ),
                  const LedgerIcon('chevron'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (v.isSimple) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Amount, ${v.currency == 'BAM' ? 'KM' : 'EUR'}'),
                    onSubmitted: (t) => _run(
                      () => repo.changeAmountOrAccount(v.id, amountMinor: parseAmount(t)),
                      'Amount changed',
                    ),
                    onTapOutside: (_) {
                      final m = parseAmount(_amount.text);
                      if (m > 0 && m != v.amountMinor.abs()) repo.changeAmountOrAccount(v.id, amountMinor: m);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: v.accountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null && id != v.accountId) {
                        _run(
                          () => repo.changeAmountOrAccount(v.id, accountId: id),
                          'Moved to ${accountName[id]}',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (v.shareMinor != null) ...[
            LedgerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InfoTerm('Owed to me'),
                  const SizedBox(height: 8),
                  _line(context, 'Paid', formatMoney(-v.amountMinor, v.currency)),
                  _line(context, 'My share, counted as spending', formatMoney(v.shareMinor!, v.currency)),
                  _line(context, 'Owed to me', formatMoney(-v.amountMinor - v.shareMinor!, v.currency)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _recordRepayment(v, -v.amountMinor - v.shareMinor!),
                    child: const Text('Record a repayment'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          LedgerCard(
            padding: const EdgeInsets.all(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: Day.parse(v.day),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 366)),
              );
              if (picked != null) _run(() => repo.updateDetails(v.id, day: Day.of(picked)), 'Date changed');
            },
            child: Row(
              children: [
                const LedgerIcon('calendar'),
                const SizedBox(width: 12),
                Expanded(child: Text(Day.long(v.day), style: context.text.label)),
                Text(
                  'Saved ${TimeOfDay.fromDateTime(v.entry.createdAt.toLocal()).format(context)}',
                  style: context.text.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!isTransfer) ...[
            TextField(
              controller: _merchant,
              decoration: const InputDecoration(labelText: 'Merchant, optional'),
              onChanged: (_) => _saveText(),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Note'),
            onChanged: (_) => _saveText(),
          ),
          const SizedBox(height: 8),
          Text('Changes save themselves.', style: context.text.caption),
          if (repeat != null) ...[
            const SizedBox(height: 12),
            LedgerCard(
              padding: const EdgeInsets.all(12),
              onTap: () => openRepeatForm(context, existing: repeat),
              child: Row(
                children: [
                  const LedgerIcon('repeat'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Repeats: ${repeat.title}, next on ${Day.short(repeat.nextDay)}',
                      style: context.text.label,
                    ),
                  ),
                  const LedgerIcon('chevron'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const LedgerIcon('plus'),
                label: const Text('Duplicate'),
                onPressed: () async {
                  final (id, undo) = await repo.duplicate(v.id);
                  if (!context.mounted) return;
                  showUndo(context, 'Copied to today', undo: undo);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => EntryDetailsScreen(entryId: id)),
                  );
                },
              ),
              if (v.type == EntryType.expense && !v.needsReview && repeat == null && v.categoryId != null)
                OutlinedButton.icon(
                  icon: const LedgerIcon('repeat'),
                  label: const Text('Repeat this'),
                  onPressed: () => openRepeatForm(context, draft: RepeatDraft.fromEntry(v, _title.text)),
                ),
              if (v.type == EntryType.expense && !v.needsReview)
                OutlinedButton.icon(
                  icon: const LedgerIcon('undo'),
                  label: const Text('Record a refund'),
                  onPressed: () => _recordRefund(v),
                ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.negative,
                  side: BorderSide(color: c.negative),
                ),
                onPressed: () async {
                  final undo = await repo.delete(v.id);
                  if (!context.mounted) return;
                  showUndo(context, '${v.displayTitle} deleted', undo: undo);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.text.bodySmall)),
        Text(value, style: context.text.label),
      ],
    ),
  );

  Future<void> _recordRefund(EntryView v) async {
    final amount = await _askAmount(
      'Record a refund',
      'It lowers ${ref.read(categoryBookProvider).nameOf(v.categoryId)} spending and is never income.',
      v.amountMinor.abs(),
      v.currency,
    );
    if (amount == null) return;
    _run(() async {
      final (_, undo) = await ref
          .read(entryRepositoryProvider)
          .addRefund(ofEntryId: v.id, amountMinor: amount);
      return undo;
    }, 'Refund saved, ${formatMoney(amount, v.currency)}');
  }

  Future<void> _recordRepayment(EntryView v, int owed) async {
    final amount = await _askAmount(
      'Record a repayment',
      'Money paid back to you. It is not income.',
      owed,
      v.currency,
    );
    if (amount == null) return;
    _run(() async {
      final (_, undo) = await ref
          .read(entryRepositoryProvider)
          .addRepayment(
            accountId: v.accountId,
            amountMinor: amount,
            title: 'Paid back for ${v.displayTitle}',
          );
      return undo;
    }, 'Repayment saved. Income did not change.');
  }

  Future<int?> _askAmount(String title, String subtitle, int initial, String currency) {
    final controller = TextEditingController(text: amountText(initial));
    return showLedgerSheet<int>(
      context,
      (sheetContext) => SheetBody(
        title: title,
        subtitle: subtitle,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount, ${currency == 'BAM' ? 'KM' : 'EUR'}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final m = parseAmount(controller.text);
              if (m > 0) Navigator.pop(sheetContext, m);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
