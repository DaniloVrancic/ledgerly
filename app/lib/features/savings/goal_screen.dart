// One savings goal: progress, the plan to reach it, adding or taking out money, and history.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/goal_plan.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../../ui/widgets/undo.dart';
import 'goal_form.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = (ref.watch(goalsProvider).value ?? const <GoalWithMoves>[])
        .where((g) => g.id == goalId)
        .firstOrNull;
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: 'target',
          title: 'Goal removed',
          message: 'This goal is no longer in Ledgerly.',
        ),
      );
    }
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final plan = goal.planOn(today);
    final g = goal.goal;
    final repo = ref.read(goalRepositoryProvider);
    final accountName = g.accountId == null
        ? null
        : (ref.watch(accountsProvider).value ?? const []).where((a) => a.id == g.accountId).firstOrNull?.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          IconButton(
            onPressed: () => openGoalForm(context, existing: g),
            icon: const LedgerIcon('pen'),
            tooltip: 'Edit goal',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MoneyText(plan.savedMinor, style: context.text.amountLarge),
                    Text('  of ${formatMoney(g.targetMinor, 'EUR')}', style: context.text.bodySmall),
                    const Spacer(),
                    Text('${(plan.progress * 100).round()}%', style: context.text.label),
                  ],
                ),
                const SizedBox(height: 8),
                LedgerBar(value: plan.progress, color: c.accent),
                const SizedBox(height: 8),
                Text(
                  accountName == null ? 'Set aside in your accounts.' : 'Kept in $accountName.',
                  style: context.text.caption,
                ),
              ],
            ),
          ),
          const SectionHeader('The plan'),
          LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(context, 'Still to save', formatMoney(plan.leftMinor, 'EUR')),
                if (g.targetDay != null) _line(context, 'Target date', Day.long(g.targetDay!)),
                if (plan.perMonthNeededMinor != null && plan.leftMinor > 0)
                  _line(context, 'Needed each month', formatMoney(plan.perMonthNeededMinor!, 'EUR')),
                _line(
                  context,
                  'You set aside, on average',
                  '${formatMoney(plan.averagePerMonthMinor, 'EUR')} a month',
                ),
                if (plan.projectedDay != null)
                  _line(context, 'At that pace, reached', Day.long(plan.projectedDay!)),
                const SizedBox(height: 8),
                Text(_advice(plan, g.targetDay), style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (goal.isOpen)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _move(context, ref, goal, add: true),
                    icon: const LedgerIcon('plus', size: 16),
                    label: const Text('Add money'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: plan.savedMinor > 0 ? () => _move(context, ref, goal, add: false) : null,
                    child: const Text('Take out'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final undo = goal.isOpen ? await repo.close(g.id) : await repo.reopen(g.id);
              if (context.mounted) {
                showUndo(
                  context,
                  goal.isOpen ? '${g.name} finished. Its money is free to use.' : '${g.name} is open again',
                  undo: undo,
                );
              }
            },
            child: Text(goal.isOpen ? 'Finish goal, I bought it' : 'Open again'),
          ),
          if (goal.moves.isNotEmpty) ...[
            const SectionHeader('History'),
            Card(
              child: Column(
                children: [
                  for (final m in goal.moves.reversed)
                    ListTile(
                      title: Text(m.amountMinor >= 0 ? 'Set aside' : 'Taken out'),
                      subtitle: Text(m.note == null ? Day.long(m.day) : '${Day.long(m.day)} · ${m.note}'),
                      trailing: MoneyText(
                        m.amountMinor,
                        sign: true,
                        tone: m.amountMinor >= 0 ? MoneyTone.positive : MoneyTone.neutral,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: c.negative),
            onPressed: () async {
              final undo = await repo.delete(g.id);
              if (!context.mounted) return;
              showUndo(context, '${g.name} deleted. Its money is free to use.', undo: undo);
              Navigator.pop(context);
            },
            child: const Text('Delete goal'),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.text.bodySmall)),
        Text(value, style: context.text.label),
      ],
    ),
  );

  String _advice(GoalPlan plan, String? targetDay) => switch (plan.status) {
    GoalStatus.reached =>
      'You have it. Finish the goal when you buy it, and its money becomes free to use for the purchase.',
    GoalStatus.onTrack => 'You are on track to make it in time.',
    GoalStatus.behind =>
      plan.averagePerMonthMinor == 0
          ? 'Set aside ${formatMoney(plan.perMonthNeededMinor ?? 0, 'EUR')} a month to make it in time.'
          : 'At your recent pace you will be late. Setting aside ${formatMoney(plan.perMonthNeededMinor ?? 0, 'EUR')} a month gets you there in time.',
    GoalStatus.overdue => 'The target date has passed. Choose a new date, or finish the goal.',
    GoalStatus.noDeadline => 'Add a target date to see how much to set aside each month.',
  };

  Future<void> _move(BuildContext context, WidgetRef ref, GoalWithMoves goal, {required bool add}) async {
    final free = ref.read(freeToUseProvider);
    final plan = goal.planOn(ref.read(todayProvider));
    final suggestion = add ? (plan.perMonthNeededMinor ?? 0).clamp(0, free > 0 ? free : 0) : 0;
    final controller = TextEditingController(text: suggestion > 0 ? amountText(suggestion) : '');
    final note = TextEditingController();
    final amount = await showLedgerSheet<int>(
      context,
      (sheetContext) => SheetBody(
        title: add ? 'Add money to ${goal.goal.name}' : 'Take money out',
        subtitle: add
            ? '${formatMoney(free, 'EUR')} is free to use. The money stays in your account.'
            : '${formatMoney(plan.savedMinor, 'EUR')} is set aside. Taking it out makes it free to use again.',
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount, EUR'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Note, optional'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final m = parseAmount(controller.text);
              if (m > 0) Navigator.pop(sheetContext, m);
            },
            child: Text(add ? 'Set aside' : 'Take out'),
          ),
        ],
      ),
    );
    if (amount == null || !context.mounted) return;
    final repo = ref.read(goalRepositoryProvider);
    try {
      final undo = add
          ? await repo.addMoney(
              goal.id,
              amount,
              freeMinor: free,
              note: note.text.trim().isEmpty ? null : note.text.trim(),
            )
          : await repo.takeOut(goal.id, amount, note: note.text.trim().isEmpty ? null : note.text.trim());
      if (context.mounted) {
        showUndo(
          context,
          add
              ? '${formatMoney(amount, 'EUR')} set aside. No money moved.'
              : '${formatMoney(amount, 'EUR')} is free to use again',
          undo: undo,
        );
      }
    } catch (e) {
      if (context.mounted) showProblem(context, e);
    }
  }
}
