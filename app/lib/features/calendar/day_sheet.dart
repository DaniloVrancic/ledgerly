// One calendar day: what was spent and earned, the top category, repeats due or planned,
// the day's entries, and adding an entry dated that day.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/entry_view.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../add_entry/add_entry_sheet.dart';
import '../entries/entries_screen.dart';
import 'month_calendar.dart';

Future<void> showDaySheet(BuildContext context, String day) =>
    showLedgerSheet(context, (_) => DaySheet(day: day));

class DaySheet extends ConsumerWidget {
  const DaySheet({super.key, required this.day});

  final String day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final book = ref.watch(categoryBookProvider);
    final t = ref.watch(dayTotalsProvider((day, day))).value?[day] ?? const DayTotals();
    final repeats = ref.watch(repeatsProvider).value ?? const <Repeat>[];
    final currencyOf = <String, String>{
      for (final a in ref.watch(allAccountsProvider).value ?? const <AccountWithBalance>[]) a.id: a.currency,
    };
    final planned = plannedRepeats(repeats, currencyOf, today, day, day)[day]?.repeats ?? const <Repeat>[];
    final due = ref.watch(dueRepeatsProvider).where((r) => r.nextDay == day).toList();

    return SheetBody(
      title: Day.label(day, today),
      subtitle: Day.long(day),
      children: [
        TileGrid(
          children: [
            MetricTile(
              label: 'Spending',
              value: MoneyText(t.spentMinor, style: context.text.amount),
            ),
            MetricTile(
              label: 'Income',
              value: MoneyText(t.incomeMinor, style: context.text.amount),
            ),
            MetricTile(
              label: 'Net',
              value: MoneyText(t.netMinor, sign: true, tone: MoneyTone.auto, style: context.text.amount),
            ),
          ],
        ),
        if (t.topCategoryId != null) ...[
          const SizedBox(height: 8),
          Text('Most went to ${book.nameOf(t.topCategoryId)}.', style: context.text.bodySmall),
        ],
        for (final (r, state) in [for (final r in due) (r, 'Due'), for (final r in planned) (r, 'Planned')])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: LedgerIcon(
              state == 'Due' ? 'clock' : 'calendar',
              color: state == 'Due' ? c.warning : c.textTertiary,
            ),
            title: Text(r.title),
            subtitle: Text(state),
            trailing: Text(
              formatMoney(r.amountMinor, currencyOf[r.accountId] ?? 'EUR'),
              style: context.text.label,
            ),
          ),
        const SizedBox(height: 8),
        if (t.count == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Nothing recorded on this day.', style: context.text.bodySmall),
          )
        else
          EntryList(
            query: EntryQuery(start: day, end: day),
            embedded: true,
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            openAddEntry(context, day: day);
          },
          icon: const LedgerIcon('plus'),
          label: const Text('Add on this day'),
        ),
      ],
    );
  }
}
