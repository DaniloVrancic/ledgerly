// Savings goals: what you are saving for, how far along you are, and what is left free to use.

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
import 'goal_form.dart';
import 'goal_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value ?? const <GoalWithMoves>[];
    final total = ref.watch(totalBalanceProvider);
    final setAside = ref.watch(setAsideProvider).value ?? 0;
    final today = ref.watch(todayProvider);
    final open = goals.where((g) => g.isOpen).toList();
    final closed = goals.where((g) => !g.isOpen).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Savings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openGoalForm(context),
        icon: const LedgerIcon('plus'),
        label: const Text('New goal'),
        shape: const StadiumBorder(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          LedgerCard(
            child: Column(
              children: [
                _row(context, 'Total balance', MoneyText(total)),
                _row(context, 'Saved for goals', MoneyText(setAside)),
                const Divider(height: 16),
                _row(context, 'Free to use', MoneyText(total - setAside, style: context.text.amount)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Money for a goal stays in your accounts. Setting it aside only stops it counting as free to spend.',
            style: context.text.bodySmall,
          ),
          if (open.isEmpty)
            const EmptyState(
              icon: 'target',
              title: 'Nothing saved for yet',
              message: 'Add a goal, like a laptop or a trip. Ledgerly shows how much to set aside each month to get there.',
            )
          else ...[
            const SectionHeader('Saving for'),
            for (final g in open) _GoalCard(goal: g, today: today),
          ],
          if (closed.isNotEmpty) ...[
            const SectionHeader('Finished'),
            for (final g in closed) _GoalCard(goal: g, today: today),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String term, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: InfoTerm(term)),
        value,
      ],
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.today});

  final GoalWithMoves goal;
  final String today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plan = goal.planOn(today);
    final g = goal.goal;
    final String line;
    if (!goal.isOpen) {
      line = 'Finished. Its money is free to use again.';
    } else if (plan.status == GoalStatus.reached) {
      line = 'Reached. Close it when you buy it.';
    } else if (plan.perMonthNeededMinor != null) {
      line =
          '${formatMoney(plan.perMonthNeededMinor!, 'EUR')} a month to reach it by ${Day.short(g.targetDay!)}';
    } else {
      line = '${formatMoney(plan.leftMinor, 'EUR')} to go';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LedgerCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalScreen(goalId: g.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LedgerIcon(g.icon, color: c.accent),
                const SizedBox(width: 8),
                Expanded(child: Text(g.name, style: context.text.label)),
                Text('${(plan.progress * 100).round()}%', style: context.text.caption),
              ],
            ),
            const SizedBox(height: 4),
            LedgerBar(value: plan.progress, color: goal.isOpen ? c.accent : c.neutralFill),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatMoney(plan.savedMinor, 'EUR')} of ${formatMoney(g.targetMinor, 'EUR')}',
                    style: context.text.bodySmall,
                  ),
                ),
                if (goal.isOpen && plan.status != GoalStatus.noDeadline)
                  Text(
                    plan.status.label,
                    style: context.text.caption.copyWith(
                      color: plan.status == GoalStatus.behind || plan.status == GoalStatus.overdue
                          ? c.warning
                          : c.positive,
                    ),
                  ),
              ],
            ),
            Text(line, style: context.text.caption),
          ],
        ),
      ),
    );
  }
}
