// One simple form for a new repeat and for changing one. Changes to an existing repeat save
// themselves; Stop repeating leaves every past entry as it was.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/entry_view.dart';
import '../../domain/repeat_schedule.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';
import '../categories/category_picker.dart';

/// What a new repeat starts with.
class RepeatDraft {
  RepeatDraft({
    this.title = '',
    this.kind = 'expense',
    this.categoryId,
    this.accountId,
    this.amountMinor = 0,
    this.every = Every.monthly,
    required this.nextDay,
  });

  factory RepeatDraft.fromEntry(EntryView v, String title) => RepeatDraft(
    title: title.trim().isEmpty ? v.displayTitle : title.trim(),
    kind: v.type == EntryType.income ? 'income' : 'expense',
    categoryId: v.categoryId,
    accountId: v.accountId,
    amountMinor: v.amountMinor.abs(),
    nextDay: advance(v.day, Every.monthly, Day.dayOfMonth(v.day)),
  );

  String title;
  String kind;
  String? categoryId;
  String? accountId;
  int amountMinor;
  Every every;
  String nextDay;
  bool varies = false;
}

Future<void> openRepeatForm(BuildContext context, {Repeat? existing, RepeatDraft? draft}) =>
    showLedgerSheet(context, (_) => RepeatForm(existing: existing, draft: draft));

class RepeatForm extends ConsumerStatefulWidget {
  const RepeatForm({super.key, this.existing, this.draft});

  final Repeat? existing;
  final RepeatDraft? draft;

  @override
  ConsumerState<RepeatForm> createState() => _RepeatFormState();
}

class _RepeatFormState extends ConsumerState<RepeatForm> {
  late final RepeatDraft _d;
  late final TextEditingController _title;
  late final TextEditingController _amount;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _d = e == null
        ? (widget.draft ?? RepeatDraft(nextDay: Day.add(ref.read(todayProvider), 1)))
        : (RepeatDraft(
            title: e.title,
            kind: e.kind,
            categoryId: e.categoryId,
            accountId: e.accountId,
            amountMinor: e.amountMinor,
            every: Every.parse(e.every),
            nextDay: e.nextDay,
          )..varies = e.varies);
    _title = TextEditingController(text: _d.title);
    _amount = TextEditingController(text: _d.amountMinor == 0 ? '' : amountText(_d.amountMinor));
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Existing repeats save each change at once.
  Future<void> _change({
    String? title,
    int? amountMinor,
    Every? every,
    String? nextDay,
    bool? varies,
    String? categoryId,
    String? accountId,
  }) async {
    setState(() {
      if (title != null) _d.title = title;
      if (amountMinor != null) _d.amountMinor = amountMinor;
      if (every != null) _d.every = every;
      if (nextDay != null) _d.nextDay = nextDay;
      if (varies != null) _d.varies = varies;
      if (categoryId != null) _d.categoryId = categoryId;
      if (accountId != null) _d.accountId = accountId;
    });
    if (_isNew) return;
    if ((title != null && title.trim().isEmpty) || (amountMinor != null && amountMinor <= 0)) return;
    await ref
        .read(repeatRepositoryProvider)
        .update(
          widget.existing!.id,
          title: title,
          amountMinor: amountMinor,
          every: every,
          nextDay: nextDay,
          varies: varies,
          categoryId: categoryId,
          accountId: accountId,
        );
  }

  Future<void> _create() async {
    try {
      final accounts = ref.read(accountsProvider).value ?? const [];
      await ref
          .read(repeatRepositoryProvider)
          .create(
            title: _d.title,
            kind: _d.kind,
            categoryId: _d.categoryId ?? (throw 'Choose a category.'),
            accountId: _d.accountId ?? accounts.first.id,
            amountMinor: _d.amountMinor,
            every: _d.every,
            nextDay: _d.nextDay,
            varies: _d.varies,
          );
      if (!mounted) return;
      showUndo(
        context,
        '${_d.title.trim()} repeats ${_d.every.label.toLowerCase()}, next on ${Day.short(_d.nextDay)}',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showProblem(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final book = ref.watch(categoryBookProvider);
    final accounts = ref.watch(accountsProvider).value ?? const [];
    _d.accountId ??= accounts.isEmpty ? null : accounts.first.id;
    final currency = accounts.where((a) => a.id == _d.accountId).firstOrNull?.currency ?? 'EUR';

    return SheetBody(
      title: _isNew ? 'New repeat' : 'Edit repeat',
      children: [
        if (_isNew) ...[
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income')),
            ],
            selected: {_d.kind},
            onSelectionChanged: (s) => setState(() {
              _d.kind = s.first;
              _d.categoryId = null;
            }),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _title,
          autofocus: _isNew && _d.title.isEmpty,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Title', hintText: 'For example Electricity'),
          onChanged: (v) => _change(title: v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount, ${currency == 'BAM' ? 'KM' : 'EUR'}'),
                onChanged: (v) => _change(amountMinor: parseAmount(v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LedgerCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: Day.parse(_d.nextDay),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) _change(nextDay: Day.of(picked));
                },
                child: Row(
                  children: [
                    const LedgerIcon('calendar', size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Next on ${Day.short(_d.nextDay)}', style: context.text.label)),
                  ],
                ),
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('The amount changes each time'),
          subtitle: const Text('Mark paid will ask for this time\'s amount.'),
          value: _d.varies,
          onChanged: (v) => _change(varies: v),
        ),
        Text('Repeats', style: context.text.label),
        const SizedBox(height: 6),
        SegmentedButton<Every>(
          showSelectedIcon: false,
          segments: [for (final e in Every.values) ButtonSegment(value: e, label: Text(e.label))],
          selected: {_d.every},
          onSelectionChanged: (s) => _change(every: s.first),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            describeEvery(_d.every, _d.nextDay, Day.dayOfMonth(_d.nextDay)),
            style: context.text.caption,
          ),
        ),
        LedgerCard(
          padding: const EdgeInsets.all(12),
          onTap: () async {
            final id = await pickCategory(context, kind: _d.kind, accountId: _d.accountId);
            if (id != null) _change(categoryId: id);
          },
          child: Row(
            children: [
              CategoryAvatar.of(book[_d.categoryId], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _d.categoryId == null ? 'Choose a category' : book.fullName(_d.categoryId),
                  style: context.text.label,
                ),
              ),
              const LedgerIcon('chevron'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _d.accountId,
          decoration: const InputDecoration(labelText: 'Paid from'),
          items: [for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
          onChanged: (id) => _change(accountId: id),
        ),
        const SizedBox(height: 16),
        if (_isNew)
          FilledButton(
            onPressed: _d.title.trim().isNotEmpty && _d.amountMinor > 0 && _d.categoryId != null
                ? _create
                : null,
            child: const Text('Save repeat'),
          )
        else ...[
          Text('Changes save themselves. Past entries stay as they are.', style: context.text.caption),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: c.negative,
              side: BorderSide(color: c.negative),
            ),
            onPressed: () async {
              final undo = await ref.read(repeatRepositoryProvider).stop(widget.existing!.id);
              if (!context.mounted) return;
              showUndo(context, '${_d.title} no longer repeats. Past entries stay.', undo: undo);
              Navigator.pop(context);
            },
            child: const Text('Stop repeating'),
          ),
        ],
      ],
    );
  }
}
