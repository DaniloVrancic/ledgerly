// Will I make it to payday: the lowest spendable balance before the next salary, on Home under
// Total balance, with how it is worked out one tap away.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../domain/payday_forecast.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';

class PaydayForecastCard extends ConsumerWidget {
  const PaydayForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(paydayForecastProvider);
    final card = switch (outcome) {
      null || NoPayday() => null,
      PaydayDue(:final title) => LedgerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lowest before payday', style: context.text.label),
            const SizedBox(height: 4),
            Text('$title is due. Mark it paid to see the forecast.', style: context.text.bodySmall),
          ],
        ),
      ),
      final PaydayForecast f => LedgerCard(
        onTap: () => showLedgerSheet<void>(context, (_) => _ForecastSheet(f)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Lowest before payday', style: context.text.label)),
                const _EstimateTag(),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyText(
                f.lowestMinor,
                tone: f.lowestMinor < 0 ? MoneyTone.negative : MoneyTone.plain,
                style: context.text.amountLarge,
              ),
            ),
            const SizedBox(height: 4),
            Text(_caption(f), style: context.text.bodySmall),
          ],
        ),
      ),
    };
    if (card == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 12), child: card);
  }

  static String _caption(PaydayForecast f) {
    final next = '${f.paydayTitle} on ${Day.short(f.payday)}.';
    if (f.days == 0 && f.bills.isEmpty) return next;
    return 'Around ${Day.short(f.lowestDay)}, after ${formatMoney(f.billsMinor, 'EUR')} of bills. $next';
  }
}

class _EstimateTag extends StatelessWidget {
  const _EstimateTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: context.colors.borderSubtle),
    ),
    child: Text('Estimate', style: context.text.caption.copyWith(color: context.colors.textSecondary)),
  );
}

class _ForecastSheet extends StatelessWidget {
  const _ForecastSheet(this.f);

  final PaydayForecast f;

  @override
  Widget build(BuildContext context) {
    final history = f.historyDays == 0
        ? 'There is no spending history yet, so daily spending counts as zero.'
        : 'Normal daily spending is your average over '
              '${f.historyDays == 1 ? 'the last day' : 'the last ${f.historyDays} days'}, '
              'without monthly and yearly repeats.';
    return SheetBody(
      title: 'How this estimate works',
      subtitle:
          'An estimate from your spendable balance, the bills before payday and your normal daily spending.',
      children: [
        _Line('Spendable today', f.spendableMinor),
        Text('Your accounts without Savings, less any goal money they hold.', style: context.text.bodySmall),
        _Line('Bills before ${Day.short(f.payday)}', -f.billsMinor),
        _Line(
          'Normal daily spending, ${formatMoney(f.perDayMinor, 'EUR')} × ${f.days} ${f.days == 1 ? 'day' : 'days'}',
          -f.dailyTotalMinor,
        ),
        const Divider(),
        _Line(
          f.days > 0 ? 'Lowest, around ${Day.short(f.lowestDay)}' : 'Lowest, today',
          f.lowestMinor,
          strong: true,
        ),
        const SizedBox(height: 8),
        Text(history, style: context.text.bodySmall),
        if (f.bills.isNotEmpty) ...[
          SectionHeader('${f.bills.length} ${f.bills.length == 1 ? 'bill' : 'bills'}'),
          for (final b in f.bills) _Line('${b.due ? 'Due' : Day.short(b.day)} · ${b.title}', -b.baseMinor),
        ],
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.minor, {this.strong = false});

  final String label;
  final int minor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final weight = strong ? FontWeight.w600 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: context.text.body.copyWith(fontWeight: weight)),
          ),
          const SizedBox(width: 12),
          MoneyText(
            minor,
            tone: minor < 0 ? MoneyTone.negative : MoneyTone.plain,
            style: context.text.amount.copyWith(fontWeight: weight),
          ),
        ],
      ),
    );
  }
}
