// The form for a new or changed savings goal: name, icon, target, optional date, and where the
// money is kept.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';

const goalIcons = [
  'target',
  'plane',
  'laptop',
  'home',
  'car',
  'gift',
  'heart',
  'book',
  'shield',
  'phone',
  'music',
  'sparkle',
];

Future<void> openGoalForm(BuildContext context, {Goal? existing}) =>
    showLedgerSheet(context, (_) => _GoalForm(existing: existing));

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.existing});

  final Goal? existing;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _target = TextEditingController(
    text: widget.existing == null ? '' : amountText(widget.existing!.targetMinor),
  );
  late String _icon = widget.existing?.icon ?? 'target';
  late String? _targetDay = widget.existing?.targetDay;
  late String? _accountId = widget.existing?.accountId;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(goalRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          name: _name.text,
          icon: _icon,
          colorSlot: 3,
          targetMinor: parseAmount(_target.text),
          targetDay: _targetDay,
          accountId: _accountId,
        );
      } else {
        await repo.update(
          widget.existing!.id,
          name: _name.text,
          icon: _icon,
          targetMinor: parseAmount(_target.text),
          targetDay: _targetDay,
          clearTargetDay: _targetDay == null,
          accountId: _accountId,
        );
      }
      if (!mounted) return;
      showUndo(context, widget.existing == null ? '${_name.text.trim()} added' : 'Changes saved');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showProblem(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final today = ref.watch(todayProvider);
    return SheetBody(
      title: widget.existing == null ? 'New savings goal' : 'Edit goal',
      subtitle: 'Money you set aside stays in your account. It is only marked as not free to spend.',
      children: [
        TextField(
          controller: _name,
          autofocus: widget.existing == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'What are you saving for?',
            hintText: 'For example Novi laptop',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _target,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Target, EUR'),
        ),
        const SizedBox(height: 12),
        Text('Icon', style: context.text.label),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final name in goalIcons)
              Material(
                color: _icon == name ? c.surfaceTint : c.surface2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: _icon == name ? BorderSide(color: c.accent, width: 1.5) : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _icon = name),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: LedgerIcon(name, size: 24, color: _icon == name ? c.accent : c.textSecondary),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const LedgerIcon('calendar', size: 16),
                label: Text(_targetDay == null ? 'Add a target date' : 'By ${Day.long(_targetDay!)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDay == null
                        ? Day.parse(today).add(const Duration(days: 180))
                        : Day.parse(_targetDay!),
                    firstDate: Day.parse(today),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _targetDay = Day.of(picked));
                },
              ),
            ),
            if (_targetDay != null)
              IconButton(
                onPressed: () => setState(() => _targetDay = null),
                icon: const LedgerIcon('x'),
                tooltip: 'No target date',
              ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: _accountId,
          decoration: const InputDecoration(labelText: 'Kept in, optional'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Any account')),
            for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
          ],
          onChanged: (v) => setState(() => _accountId = v),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: Text(widget.existing == null ? 'Save goal' : 'Save changes')),
      ],
    );
  }
}
