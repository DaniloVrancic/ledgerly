// Which column holds what, pre-filled with Ledgerly's guess, and a preview of the first rows
// read that way. Also the account the statement belongs to.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/repositories/account_repository.dart';
import '../../domain/statement/statement_mapping.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';

class MappingStep extends ConsumerWidget {
  const MappingStep({
    super.key,
    required this.fileName,
    required this.rows,
    required this.mapping,
    required this.accountId,
    required this.onMapping,
    required this.onAccount,
    required this.onNext,
  });

  final String fileName;
  final List<List<String>> rows;
  final StatementMapping mapping;
  final String? accountId;
  final ValueChanged<StatementMapping> onMapping;
  final ValueChanged<String> onAccount;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider).value ?? const <AccountWithBalance>[];
    final currency = accounts.where((a) => a.id == accountId).firstOrNull?.currency ?? 'EUR';
    final width = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final names = [
      for (var i = 0; i < width; i++)
        mapping.hasHeader && i < rows.first.length && rows.first[i].isNotEmpty
            ? rows.first[i]
            : 'Column ${i + 1}',
    ];
    final preview = applyMapping(rows, mapping).take(5).toList();

    Widget column(String label, int? value, ValueChanged<int> onChanged) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [for (var i = 0; i < width; i++) DropdownMenuItem(value: i, child: Text(names[i]))],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text('$fileName · ${rows.length - (mapping.hasHeader ? 1 : 0)} rows', style: context.text.bodySmall),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: accountId,
          decoration: const InputDecoration(labelText: 'This statement is for'),
          items: [
            for (final a in accounts) DropdownMenuItem(value: a.id, child: Text('${a.name} · ${a.currency}')),
          ],
          onChanged: (v) {
            if (v != null) onAccount(v);
          },
        ),
        const SectionHeader('Columns'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('The first row is a header'),
          value: mapping.hasHeader,
          onChanged: (v) => onMapping(mapping.copyWith(hasHeader: v)),
        ),
        column('Date', mapping.dateCol, (v) => onMapping(mapping.copyWith(dateCol: v))),
        column('Description', mapping.descriptionCol, (v) => onMapping(mapping.copyWith(descriptionCol: v))),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('One amount')),
            ButtonSegment(value: true, label: Text('Debit and credit')),
          ],
          selected: {mapping.usesDebitCredit},
          onSelectionChanged: (s) => onMapping(
            s.first
                ? mapping.copyWith(
                    clearAmount: true,
                    debitCol: mapping.debitCol ?? 0,
                    creditCol: mapping.creditCol ?? 0,
                  )
                : mapping.copyWith(clearDebitCredit: true, amountCol: mapping.amountCol ?? 0),
          ),
        ),
        const SizedBox(height: 12),
        if (mapping.usesDebitCredit) ...[
          column('Money out (debit)', mapping.debitCol, (v) => onMapping(mapping.copyWith(debitCol: v))),
          column('Money in (credit)', mapping.creditCol, (v) => onMapping(mapping.copyWith(creditCol: v))),
        ] else
          column(
            'Amount, minus for money out',
            mapping.amountCol,
            (v) => onMapping(mapping.copyWith(amountCol: v)),
          ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: mapping.dateFormat,
          decoration: const InputDecoration(labelText: 'Dates are written as'),
          items: [
            for (final f in dateFormats)
              DropdownMenuItem(value: f, child: Text(f.replaceAll('yyyy', 'YYYY').replaceAll('dd', 'DD'))),
          ],
          onChanged: (v) {
            if (v != null) onMapping(mapping.copyWith(dateFormat: v));
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Decimal comma'),
          subtitle: Text(mapping.decimalComma ? '1.234,56' : '1,234.56'),
          value: mapping.decimalComma,
          onChanged: (v) => onMapping(mapping.copyWith(decimalComma: v)),
        ),
        const SectionHeader('Preview'),
        Card(
          child: Column(
            children: [
              for (final r in preview)
                ListTile(
                  dense: true,
                  title: Text(
                    r.ok ? r.description : 'Line ${r.line}: ${r.error}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: r.ok ? Text(Day.long(r.day!)) : null,
                  trailing: r.ok
                      ? Text(
                          formatMoney(r.amountMinor, currency, sign: true),
                          style: context.text.label.copyWith(
                            color: r.amountMinor > 0 ? c.positive : c.textPrimary,
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: accountId == null ? null : onNext,
          child: const Text('Compare with my entries'),
        ),
      ],
    );
  }
}
