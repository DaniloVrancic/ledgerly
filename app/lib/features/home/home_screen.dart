// Home answers, in order: how much do I have, what is due, how is this month going, where is
// my money going, and what happened lately.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../app/shell_tabs.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/entry_view.dart';
import '../../domain/budget_plan.dart';
import '../../domain/insights.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/entry_tile.dart';
import '../../ui/widgets/money_text.dart';
import '../budgets/budget_screen.dart';
import '../budgets/budgets_screen.dart';
import '../entries/entries_screen.dart';
import '../entries/entry_details_screen.dart';
import '../entries/needs_review_screen.dart';
import '../insights/category_insight_screen.dart';
import '../repeats/repeat_actions.dart';
import '../settings/backup_status.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(currentPeriodProvider);
    final previous = previousPeriod(period, startDay: ref.watch(monthStartProvider));
    final totals = ref.watch(totalsProvider(period)).value ?? PeriodTotals.empty;
    final before = ref.watch(totalsProvider(previous)).value ?? PeriodTotals.empty;
    final review =
        ref.watch(entriesProvider(const EntryQuery(needsReview: true, limit: 50))).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledgerly'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(period.label, style: context.text.bodySmall),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          const _BalanceCard(),
          const _DueSection(),
          SectionHeader(
            'This month',
            action: 'Insights',
            onAction: () => ref.read(selectedTabProvider.notifier).show(AppTab.insights),
          ),
          _MonthTiles(period: period, totals: totals, before: before, previous: previous),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 12),
            LedgerCard(
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NeedsReviewScreen())),
              child: Row(
                children: [
                  LedgerIcon('flag', color: context.colors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${review.length} ${review.length == 1 ? 'entry needs' : 'entries need'} a category',
                      style: context.text.label,
                    ),
                  ),
                  const LedgerIcon('chevron'),
                ],
              ),
            ),
          ],
          const _BudgetWarning(),
          const SectionHeader('Where it went'),
          _TopCategories(period: period, totals: totals),
          const SectionHeader('Recent'),
          const _Recent(),
          const SizedBox(height: 12),
          const BackupStatusLine(),
        ],
      ),
    );
  }
}

class _BalanceCard extends ConsumerStatefulWidget {
  const _BalanceCard();

  @override
  ConsumerState<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<_BalanceCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final total = ref.watch(totalBalanceProvider);
    final setAside = ref.watch(setAsideProvider).value ?? 0;
    final owed = ref.watch(owedToMeProvider).value ?? 0;
    final onInverse = TextStyle(color: c.onInverse);
    Widget row(String label, Widget value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: onInverse.copyWith(fontWeight: strong ? FontWeight.w600 : FontWeight.w400),
            ),
          ),
          DefaultTextStyle.merge(style: onInverse, child: value),
        ],
      ),
    );

    return Material(
      color: c.surfaceInverse,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total balance',
                      style: onInverse.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  LedgerIcon(
                    _open ? 'up' : 'chevronDown',
                    color: c.onInverse,
                    semanticLabel: _open ? 'Hide accounts' : 'Show accounts',
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: MoneyText(total, style: context.text.balance.copyWith(color: c.onInverse)),
              ),
              Text(
                'Free to use ${formatMoney(total - setAside, 'EUR')}',
                style: onInverse.copyWith(fontSize: 14),
              ),
              if (_open) ...[
                Divider(color: c.onInverse.withValues(alpha: 0.25), height: 24),
                for (final a in accounts)
                  row(
                    a.name,
                    MoneyText(
                      a.balanceMinor,
                      currency: a.currency,
                      style: context.text.label.copyWith(color: c.onInverse),
                    ),
                  ),
                const SizedBox(height: 8),
                row(
                  'Saved for goals',
                  MoneyText(setAside, style: context.text.label.copyWith(color: c.onInverse)),
                  strong: true,
                ),
                row(
                  'Free to use',
                  MoneyText(total - setAside, style: context.text.label.copyWith(color: c.onInverse)),
                  strong: true,
                ),
                if (owed > 0)
                  row(
                    'Owed to me',
                    MoneyText(owed, style: context.text.label.copyWith(color: c.onInverse)),
                    strong: true,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DueSection extends ConsumerWidget {
  const _DueSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueRepeatsProvider);
    if (due.isEmpty) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    final accounts = {for (final a in ref.watch(accountsProvider).value ?? const []) a.id: a};
    final book = ref.watch(categoryBookProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Due'),
        Card(
          child: Column(
            children: [
              for (final r in due.take(3))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      CategoryAvatar.of(book[r.categoryId]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, style: context.text.subtitle),
                            Text(
                              '${dueText(r.nextDay, today)}, ${r.varies ? 'about ' : ''}${formatMoney(r.amountMinor, accounts[r.accountId]?.currency ?? 'EUR')}',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => markRepeatPaid(context, ref, r),
                        child: const Text('Mark paid'),
                      ),
                    ],
                  ),
                ),
              if (due.length > 3)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${due.length - 3} more in Repeats', style: context.text.bodySmall),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthTiles extends StatelessWidget {
  const _MonthTiles({
    required this.period,
    required this.totals,
    required this.before,
    required this.previous,
  });

  final Period period;
  final PeriodTotals totals;
  final PeriodTotals before;
  final Period previous;

  @override
  Widget build(BuildContext context) {
    String vs(int now, int then) =>
        '${now >= then ? '+' : '−'}${formatMoney((now - then).abs(), 'EUR')} vs ${previous.short}';
    void open(EntryQuery q, String title) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilteredEntriesScreen(title: title, query: q),
      ),
    );
    final q = EntryQuery(start: period.start, end: period.end);
    final rate = totals.savingsRate;
    return TileGrid(
      children: [
        MetricTile(
          label: 'Income',
          value: MoneyText(
            totals.incomeMinor,
            sign: true,
            tone: MoneyTone.positive,
            style: context.text.amountLarge,
          ),
          caption: vs(totals.incomeMinor, before.incomeMinor),
          onTap: () => open(q.copyWith(type: EntryType.income), 'Income, ${period.label}'),
        ),
        MetricTile(
          label: 'Spending',
          value: MoneyText(-totals.spendingMinor, tone: MoneyTone.negative, style: context.text.amountLarge),
          caption: vs(totals.spendingMinor, before.spendingMinor),
          onTap: () => open(q.copyWith(type: EntryType.expense), 'Spending, ${period.label}'),
        ),
        MetricTile(
          label: 'Net',
          value: MoneyText(
            totals.netMinor,
            sign: true,
            tone: MoneyTone.auto,
            style: context.text.amountLarge,
          ),
          caption: vs(totals.netMinor, before.netMinor),
          onTap: () => open(q, period.label),
        ),
        MetricTile(
          label: 'Savings rate',
          value: Text(rate == null ? '–' : '${(rate * 100).round()}%', style: context.text.amountLarge),
          caption: before.savingsRate == null
              ? 'No income in ${previous.short}'
              : '${(before.savingsRate! * 100).round()}% in ${previous.short}',
          onTap: () => open(q, period.label),
        ),
      ],
    );
  }
}

/// The one budget that most needs attention, from 80% of its limit. Hidden otherwise.
class _BudgetWarning extends ConsumerWidget {
  const _BudgetWarning();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worst = ref
        .watch(budgetLinesProvider)
        .where((l) => l.view.state != BudgetState.normal)
        .fold<BudgetLine?>(null, (w, l) => w == null || l.view.ratio > w.view.ratio ? l : w);
    if (worst == null) return const SizedBox();
    final c = context.colors;
    final v = worst.view;
    final name = budgetName(worst.budget, ref.watch(categoryBookProvider));
    final over = v.state == BudgetState.over;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LedgerCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BudgetScreen(budgetId: worst.budget.id)),
        ),
        child: Row(
          children: [
            LedgerIcon('alert', color: over ? c.negative : c.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    over
                        ? '$name is ${formatMoney(-v.leftMinor, 'EUR')} over its limit'
                        : '$name is at ${(v.ratio * 100).floor()}%',
                    style: context.text.label,
                  ),
                  Text(
                    over
                        ? '${formatMoney(v.spentMinor, 'EUR')} of ${formatMoney(v.limitMinor, 'EUR')}'
                        : '${formatMoney(v.leftMinor, 'EUR')} left for ${v.daysLeft} ${v.daysLeft == 1 ? 'day' : 'days'}',
                    style: context.text.caption,
                  ),
                ],
              ),
            ),
            const LedgerIcon('chevron'),
          ],
        ),
      ),
    );
  }
}

class _TopCategories extends ConsumerWidget {
  const _TopCategories({required this.period, required this.totals});

  final Period period;
  final PeriodTotals totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final book = ref.watch(categoryBookProvider);
    final top = totals.spendingByCategory.take(5).toList();
    // A category with a monthly budget shows that budget's bar instead of the comparison bar.
    final budgets = {
      for (final l in ref.watch(budgetLinesProvider))
        if (l.budget.categoryId != null && l.budget.every == BudgetEvery.monthly) l.budget.categoryId!: l,
    };
    if (top.isEmpty) return const LedgerCard(child: Text('Nothing spent this month yet.'));
    final largest = top.first.amountMinor;
    return Card(
      child: Column(
        children: [
          for (final item in top)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryInsightScreen(categoryId: item.categoryId, period: period),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CategoryAvatar.of(book[item.categoryId], size: 32),
                        const SizedBox(width: 12),
                        Expanded(child: Text(book.nameOf(item.categoryId), style: context.text.label)),
                        Text(
                          totals.incomeMinor > 0
                              ? '${(item.amountMinor * 100 / totals.incomeMinor).round()}% of income  '
                              : '',
                          style: context.text.caption,
                        ),
                        MoneyText(item.amountMinor, style: context.text.label),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 44, top: 4),
                      child: budgets[item.categoryId] == null
                          ? LedgerBar(
                              value: item.amountMinor / largest,
                              color: c.category(book[item.categoryId]?.colorSlot ?? 0),
                            )
                          : BudgetRow(line: budgets[item.categoryId]!, showName: false),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Recent extends ConsumerWidget {
  const _Recent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(entriesProvider(const EntryQuery(limit: 5))).value ?? const [];
    final book = ref.watch(categoryBookProvider);
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <AccountWithBalance>[]) a.id: a,
    };
    if (recent.isEmpty) {
      return const Card(
        child: EmptyState(
          icon: 'plus',
          title: 'Nothing here yet',
          message: 'Entries you add will appear here. Tap the plus button to add one.',
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final v in recent)
            EntryTile(
              view: v,
              book: book,
              accounts: accounts,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EntryDetailsScreen(entryId: v.id)),
              ),
            ),
        ],
      ),
    );
  }
}
