// Insights: where income comes from, where spending goes, and how it affects you, for any
// month, compared with the month before and the usual level. Every figure opens its entries.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/category_book.dart';
import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/entry_view.dart';
import '../../domain/insights.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../entries/entries_screen.dart';
import 'category_insight_screen.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  /// How many months back from the current one.
  int _back = 0;

  @override
  Widget build(BuildContext context) {
    final startDay = ref.watch(monthStartProvider);
    final months = lastPeriods(ref.watch(todayProvider), 6 + _back + 3, startDay: startDay);
    final period = months[months.length - 1 - _back];
    final earlier = months.sublist(0, months.length - 1 - _back);
    final totals = ref.watch(totalsProvider(period)).value ?? PeriodTotals.empty;
    final previous = [
      for (final p in earlier.sublist(earlier.length - 3))
        ref.watch(totalsProvider(p)).value ?? PeriodTotals.empty,
    ];
    final book = ref.watch(categoryBookProvider);
    final insights = insightsFor(current: totals, previous: previous, nameOf: book.nameOf);
    final chartMonths = months.sublist(months.length - 6 - _back, months.length - _back);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _back += 1),
                icon: const RotatedBox(quarterTurns: 2, child: LedgerIcon('chevron')),
                tooltip: 'Earlier month',
              ),
              Expanded(
                child: Text(period.label, style: context.text.title, textAlign: TextAlign.center),
              ),
              IconButton(
                onPressed: _back == 0 ? null : () => setState(() => _back -= 1),
                icon: const LedgerIcon('chevron'),
                tooltip: 'Later month',
              ),
            ],
          ),
          Text(
            'Compared with ${earlier.last.label}',
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _Tiles(period: period, totals: totals, before: previous.last, previousLabel: earlier.last.short),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 12),
            LedgerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final i in insights)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: LedgerIcon('trend', size: 16, color: context.colors.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(i.text, style: context.text.bodySmall)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SectionHeader('Where did my money go?'),
          _CategoryList(
            items: totals.spendingByCategory,
            before: previous.last,
            incomeMinor: totals.incomeMinor,
            book: book,
            period: period,
            spending: true,
          ),
          const SectionHeader('Where did my income come from?'),
          _CategoryList(
            items: totals.incomeByCategory,
            before: previous.last,
            incomeMinor: totals.incomeMinor,
            book: book,
            period: period,
            spending: false,
          ),
          const SectionHeader('How are the months going?'),
          LedgerCard(child: _MonthsChart(months: chartMonths)),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({
    required this.period,
    required this.totals,
    required this.before,
    required this.previousLabel,
  });

  final Period period;
  final PeriodTotals totals;
  final PeriodTotals before;
  final String previousLabel;

  @override
  Widget build(BuildContext context) {
    String change(int now, int then) {
      final pct = percentChange(now, then);
      return pct == null
          ? 'Nothing in $previousLabel'
          : '${pct >= 0 ? '+' : '−'}${pct.abs()}% vs $previousLabel';
    }

    void open(EntryType? type, String title) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilteredEntriesScreen(
          title: title,
          query: EntryQuery(start: period.start, end: period.end, type: type),
        ),
      ),
    );
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
          caption: change(totals.incomeMinor, before.incomeMinor),
          onTap: () => open(EntryType.income, 'Income, ${period.label}'),
        ),
        MetricTile(
          label: 'Spending',
          value: MoneyText(-totals.spendingMinor, tone: MoneyTone.negative, style: context.text.amountLarge),
          caption: change(totals.spendingMinor, before.spendingMinor),
          onTap: () => open(EntryType.expense, 'Spending, ${period.label}'),
        ),
        MetricTile(
          label: 'Net',
          value: MoneyText(
            totals.netMinor,
            sign: true,
            tone: MoneyTone.auto,
            style: context.text.amountLarge,
          ),
          caption: 'Income minus spending',
          onTap: () => open(null, period.label),
        ),
        MetricTile(
          label: 'Savings rate',
          value: Text(rate == null ? '–' : '${(rate * 100).round()}%', style: context.text.amountLarge),
          caption: before.savingsRate == null
              ? 'No income in $previousLabel'
              : '${(before.savingsRate! * 100).round()}% in $previousLabel',
        ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.items,
    required this.before,
    required this.incomeMinor,
    required this.book,
    required this.period,
    required this.spending,
  });

  final List<CategoryAmount> items;
  final PeriodTotals before;
  final int incomeMinor;
  final CategoryBook book;
  final Period period;
  final bool spending;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (items.isEmpty) {
      return LedgerCard(
        child: Text(
          spending ? 'Nothing spent in this month.' : 'No income in this month.',
          style: context.text.bodySmall,
        ),
      );
    }
    final total = items.fold<int>(0, (s, i) => s + i.amountMinor);
    final then = spending ? before.spendingByCategory : before.incomeByCategory;
    return Card(
      child: Column(
        children: [
          for (final (rank, item) in items.indexed)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => spending
                      ? CategoryInsightScreen(categoryId: item.categoryId, period: period)
                      : FilteredEntriesScreen(
                          title: '${book.nameOf(item.categoryId)}, ${period.label}',
                          query: EntryQuery(
                            start: period.start,
                            end: period.end,
                            categoryId: item.categoryId,
                          ),
                        ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CategoryAvatar.of(book[item.categoryId], size: 32),
                        const SizedBox(width: 12),
                        Expanded(child: Text(book.nameOf(item.categoryId), style: context.text.label)),
                        _ChangeBadge(
                          now: item.amountMinor,
                          before: then
                              .where((x) => x.categoryId == item.categoryId)
                              .fold(0, (s, x) => s + x.amountMinor),
                          spending: spending,
                        ),
                        const SizedBox(width: 8),
                        MoneyText(item.amountMinor, style: context.text.label),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 44, top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: LedgerBar(
                              value: item.amountMinor / total,
                              color: c.chart[rank.clamp(0, 6)],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 92,
                            child: Text(
                              spending && incomeMinor > 0
                                  ? '${(item.amountMinor * 100 / incomeMinor).round()}% of income'
                                  : '${(item.amountMinor * 100 / total).round()}% of total',
                              style: context.text.caption,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
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

/// "+12%" or "−8%" against the month before. For spending, up is shown in the spending colour.
class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.now, required this.before, required this.spending});

  final int now;
  final int before;
  final bool spending;

  @override
  Widget build(BuildContext context) {
    final pct = percentChange(now, before);
    if (pct == null || pct == 0) return const SizedBox.shrink();
    final c = context.colors;
    final worse = spending ? pct > 0 : pct < 0;
    return Text(
      '${pct > 0 ? '+' : '−'}${pct.abs()}%',
      style: context.text.caption.copyWith(color: worse ? c.negative : c.positive),
    );
  }
}

/// Income and spending for six months, side by side. Tapping a month opens its entries.
class _MonthsChart extends ConsumerWidget {
  const _MonthsChart({required this.months});

  final List<Period> months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final totals = [for (final p in months) ref.watch(totalsProvider(p)).value ?? PeriodTotals.empty];
    final top = totals.fold<int>(
      1,
      (m, t) => [m, t.incomeMinor, t.spendingMinor].reduce((a, b) => a > b ? a : b),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: top / 100 * 1.1,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: top / 100 / 2,
                getDrawingHorizontalLine: (_) => FlLine(color: c.chartGrid, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(months[value.toInt()].short, style: context.text.caption),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => c.surfaceInverse,
                  getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                    '${rodIndex == 0 ? 'Income' : 'Spending'} ${formatMoney((rod.toY * 100).round(), 'EUR')}',
                    TextStyle(color: c.onInverse, fontSize: 12),
                  ),
                ),
                touchCallback: (event, response) {
                  final spot = response?.spot;
                  if (event is FlTapUpEvent && spot != null) {
                    final p = months[spot.touchedBarGroupIndex];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FilteredEntriesScreen(
                          title: p.label,
                          query: EntryQuery(start: p.start, end: p.end),
                        ),
                      ),
                    );
                  }
                },
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: totals[i].incomeMinor / 100,
                        color: c.positiveFill,
                        width: 12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: totals[i].spendingMinor / 100,
                        color: c.negativeFill,
                        width: 12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            _Key(color: c.positiveFill, label: 'Income'),
            _Key(color: c.negativeFill, label: 'Spending'),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = months.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text(months[i].short, style: context.text.bodySmall)),
                Expanded(child: Text('Net', style: context.text.caption)),
                MoneyText(totals[i].netMinor, sign: true, tone: MoneyTone.auto, style: context.text.label),
                SizedBox(
                  width: 56,
                  child: Text(
                    totals[i].savingsRate == null ? '' : '${(totals[i].savingsRate! * 100).round()}%',
                    style: context.text.caption,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(label, style: context.text.caption),
    ],
  );
}
