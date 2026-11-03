// Repeats: what is due now, what is coming, and what subscriptions cost per month and year.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/repeat_schedule.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import 'repeat_actions.dart';
import 'repeat_form.dart';

class RepeatsScreen extends ConsumerWidget {
  const RepeatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(repeatsProvider).value ?? const <Repeat>[];
    final today = ref.watch(todayProvider);
    final book = ref.watch(categoryBookProvider);
    final currencies = {for (final a in ref.watch(allAccountsProvider).value ?? const []) a.id: a.currency};
    final due = all.where((r) => isDue(r.nextDay, today)).toList();
    final upcoming = all.where((r) => !isDue(r.nextDay, today)).toList();
    final subscriptions = all.where(
      (r) => r.kind == 'expense' && book.topOf(r.categoryId) == 'subscriptions',
    );
    final perMonth = subscriptions
        .fold<double>(
          0,
          (s, r) =>
              s + toBase(r.amountMinor, currencies[r.accountId] ?? 'EUR') * Every.parse(r.every).perMonth,
        )
        .round();

    String amount(Repeat r) =>
        '${r.varies ? 'about ' : ''}${formatMoney(r.amountMinor, currencies[r.accountId] ?? 'EUR')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Repeats')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRepeatForm(context),
        icon: const LedgerIcon('plus'),
        label: const Text('New repeat'),
        shape: const StadiumBorder(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Text(
            'Nothing is posted by itself. When a repeat is due, mark it paid once you have paid it, or skip it.',
            style: context.text.bodySmall,
          ),
          if (due.isNotEmpty) ...[
            const SectionHeader('Due'),
            Card(
              child: Column(
                children: [
                  for (final r in due)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CategoryAvatar.of(book[r.categoryId]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title, style: context.text.subtitle),
                                    Text(
                                      '${dueText(r.nextDay, today)} · ${amount(r)}',
                                      style: context.text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => skipRepeat(context, ref, r),
                                child: const Text('Skip'),
                              ),
                              const SizedBox(width: 4),
                              FilledButton.icon(
                                onPressed: () => markRepeatPaid(context, ref, r),
                                icon: const LedgerIcon('check', size: 16),
                                label: const Text('Mark paid'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SectionHeader('Coming up'),
          if (upcoming.isEmpty)
            const Card(
              child: EmptyState(
                icon: 'repeat',
                title: 'No repeats yet',
                message: 'Set a repeat here or in More details on the Add sheet, and the next one is a single tap.',
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final r in upcoming)
                    ListTile(
                      leading: CategoryAvatar.of(book[r.categoryId]),
                      title: Text(r.title),
                      subtitle: Text(
                        '${describeEvery(Every.parse(r.every), r.nextDay, r.anchorDay)} · next ${Day.short(r.nextDay)}',
                      ),
                      trailing: MoneyText(
                        r.kind == 'income' ? r.amountMinor : -r.amountMinor,
                        currency: currencies[r.accountId] ?? 'EUR',
                        sign: r.kind == 'income',
                        tone: MoneyTone.auto,
                      ),
                      onTap: () => openRepeatForm(context, existing: r),
                    ),
                ],
              ),
            ),
          const SectionHeader('Subscriptions'),
          LedgerCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Per month', style: context.text.caption),
                      MoneyText(perMonth, style: context.text.amountLarge),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Per year', style: context.text.caption),
                      MoneyText(perMonth * 12, style: context.text.amountLarge),
                    ],
                  ),
                ),
                Text(
                  '${subscriptions.length} active',
                  style: context.text.caption.copyWith(color: context.colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
