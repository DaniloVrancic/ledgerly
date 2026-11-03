// One spending category: this month against the six before it, its subcategories, and the
// entries behind the figure.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/repositories/entry_repository.dart';
import '../../domain/insights.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../entries/entries_screen.dart';

class CategoryInsightScreen extends ConsumerWidget {
  const CategoryInsightScreen({super.key, required this.categoryId, required this.period});

  final String categoryId;
  final Period period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final book = ref.watch(categoryBookProvider);
    final months = lastPeriods(period.start, 6, startDay: ref.watch(monthStartProvider));
    final values = [
      for (final p in months)
        (ref.watch(totalsProvider(p)).value ?? PeriodTotals.empty).spendingFor(categoryId),
    ];
    final now = values.last;
    final earlier = values.sublist(0, values.length - 1);
    final average = earlier.isEmpty ? 0 : (earlier.reduce((a, b) => a + b) / earlier.length).round();
    final top = values.fold<int>(1, (m, v) => v > m ? v : m);
    final subs = ref.watch(subcategoryTotalsProvider((categoryId, period))).value ?? const <CategoryAmount>[];
    final name = book.nameOf(categoryId);
    final diff = now - average;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period.label, style: context.text.caption),
                MoneyText(now, style: context.text.amountLarge),
                const SizedBox(height: 4),
                Text(
                  average == 0
                      ? 'Nothing in the five months before.'
                      : '${formatMoney(diff.abs(), 'EUR')} ${diff >= 0 ? 'above' : 'below'} the usual ${formatMoney(average, 'EUR')} a month.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SectionHeader('Month by month'),
          LedgerCard(
            child: Column(
              children: [
                for (var i = months.length - 1; i >= 0; i--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 44, child: Text(months[i].short, style: context.text.bodySmall)),
                        Expanded(
                          child: LedgerBar(
                            value: values[i] / top,
                            color: i == months.length - 1 ? c.chart[0] : c.neutralFill,
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: MoneyText(values[i], style: context.text.label, textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (subs.isNotEmpty) ...[
            const SectionHeader('Inside it'),
            Card(
              child: Column(
                children: [
                  for (final s in subs)
                    ListTile(
                      leading: CategoryAvatar.of(book[s.categoryId], size: 32),
                      title: Text(
                        s.categoryId == categoryId ? '$name, no subcategory' : book.nameOf(s.categoryId),
                      ),
                      trailing: MoneyText(s.amountMinor, style: context.text.label),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FilteredEntriesScreen(
                            title: book.nameOf(s.categoryId),
                            query: EntryQuery(start: period.start, end: period.end, categoryId: s.categoryId),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SectionHeader('Entries'),
          EntryList(
            embedded: true,
            query: EntryQuery(start: period.start, end: period.end, categoryId: categoryId),
          ),
        ],
      ),
    );
  }
}
