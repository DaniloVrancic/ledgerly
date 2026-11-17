// One budget: where it stands, how much is safe to spend each day, the last six periods, and
// the entries behind the figure.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../domain/budget_plan.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../../ui/widgets/undo.dart';
import '../entries/entries_screen.dart';
import 'budget_form.dart';
import 'budgets_screen.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key, required this.budgetId});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(budgetLinesProvider).where((l) => l.budget.id == budgetId).firstOrNull;
    if (line == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: 'pie',
          title: 'Budget removed',
          message: 'This budget is no longer in Ledgerly.',
        ),
      );
    }
    final c = context.colors;
    final book = ref.watch(categoryBookProvider);
    final b = line.budget;
    final v = line.view;
    final name = budgetName(b, book);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            onPressed: () => openBudgetForm(context, existing: b),
            icon: const LedgerIcon('pen'),
            tooltip: 'Change the limit',
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
                Text(v.period.label, style: context.text.caption),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(v.spentMinor, style: context.text.amountLarge),
                    Flexible(
                      child: Text('  of ${formatMoney(v.limitMinor, 'EUR')}', style: context.text.bodySmall),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BudgetBar(view: v),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(child: BudgetStateLabel(view: v)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${v.period.days - v.daysLeft} of ${v.period.days} days gone',
                        style: context.text.caption,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LedgerCard(
            child: Row(
              children: [
                LedgerIcon(
                  v.state == BudgetState.over ? 'alert' : 'wallet',
                  color: v.state == BudgetState.over ? c.negative : c.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    v.state == BudgetState.over
                        ? 'Over the limit by ${formatMoney(-v.leftMinor, 'EUR')}. Nothing more fits this ${b.every == BudgetEvery.weekly ? 'week' : 'month'}.'
                        : '${formatMoney(v.safePerDayMinor, 'EUR')} a day for ${v.daysLeft} ${v.daysLeft == 1 ? 'day' : 'days'} keeps you within the limit.',
                    style: context.text.body,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Last six'),
          Card(
            child: _History(budget: b, current: v.period),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FilteredEntriesScreen(
                  title: '$name, ${v.period.short}',
                  query: EntryQuery(start: v.period.start, end: v.period.end, categoryId: b.categoryId),
                ),
              ),
            ),
            icon: const LedgerIcon('list'),
            label: const Text('See entries'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: c.negative),
            onPressed: () async {
              final undo = await ref.read(budgetRepositoryProvider).delete(b.id);
              if (!context.mounted) return;
              showUndo(context, 'Budget for $name deleted', undo: undo);
              Navigator.pop(context);
            },
            icon: LedgerIcon('x', color: c.negative),
            label: const Text('Delete budget'),
          ),
        ],
      ),
    );
  }
}

/// The current period and the five before it, newest first.
class _History extends ConsumerWidget {
  const _History({required this.budget, required this.current});

  final Budget budget;
  final Period current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthStart = ref.watch(monthStartProvider);
    final today = ref.watch(todayProvider);
    final periods = <Period>[current];
    while (periods.length < 6) {
      periods.add(
        budget.every == BudgetEvery.weekly
            ? previousWeek(periods.last)
            : previousPeriod(periods.last, startDay: monthStart),
      );
    }
    final key = budget.categoryId ?? BudgetRepository.overall;
    final rows = [
      for (final p in periods)
        (
          period: p,
          view: viewBudget(
            limitMinor: budget.limitMinor,
            spentMinor: ref.watch(budgetSpendingProvider(p)).value?[key] ?? 0,
            period: p,
            today: today,
          ),
        ),
    ];
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                SizedBox(width: 64, child: Text(r.period.short, style: context.text.label)),
                Expanded(child: BudgetBar(view: r.view)),
                const SizedBox(width: 12),
                Text(formatMoney(r.view.spentMinor, 'EUR'), style: context.text.caption),
              ],
            ),
          ),
      ],
    );
  }
}
