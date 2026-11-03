// Mark paid and Skip, shared by Home and the Repeats screen. Mark paid is one tap with Undo;
// a repeat whose amount changes asks for this time's amount first.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/repeat_schedule.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';

Future<void> markRepeatPaid(BuildContext context, WidgetRef ref, Repeat r) async {
  final currency =
      (ref.read(accountsProvider).value ?? const [])
          .where((a) => a.id == r.accountId)
          .firstOrNull
          ?.currency ??
      'EUR';
  int? amount = r.amountMinor;
  if (r.varies) {
    amount = await _askAmount(context, r, currency);
    if (amount == null) return;
  }
  final undo = await ref.read(repeatRepositoryProvider).markPaid(r.id, amountMinor: amount);
  if (context.mounted) showUndo(context, '${r.title} paid, ${formatMoney(amount, currency)}', undo: undo);
}

Future<void> skipRepeat(BuildContext context, WidgetRef ref, Repeat r) async {
  final next = advance(r.nextDay, Every.parse(r.every), r.anchorDay);
  final undo = await ref.read(repeatRepositoryProvider).skip(r.id);
  if (context.mounted) showUndo(context, '${r.title} skipped. Next on ${Day.short(next)}', undo: undo);
}

Future<int?> _askAmount(BuildContext context, Repeat r, String currency) {
  final controller = TextEditingController(text: amountText(r.amountMinor));
  return showLedgerSheet<int>(
    context,
    (sheetContext) => SheetBody(
      title: 'How much was ${r.title}?',
      subtitle: 'Last time it was ${formatMoney(r.amountMinor, currency)}.',
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount, ${currency == 'BAM' ? 'KM' : 'EUR'}'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final v = parseAmount(controller.text);
            if (v > 0) Navigator.pop(sheetContext, v);
          },
          child: const Text('Mark paid'),
        ),
      ],
    ),
  );
}

/// "Due today" or "Due since 25 Oct".
String dueText(String nextDay, String today) =>
    nextDay == today ? 'Due today' : 'Due since ${Day.short(nextDay)}';
