// Accounts and their balances, with a regular nudge to check them, especially Cash.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../../ui/widgets/undo.dart';
import '../entries/entries_screen.dart';

/// Days after which an account asks for a balance check. Cash drifts fastest.
int checkEveryDays(AccountKind kind) => kind == AccountKind.cash ? 14 : 35;

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(allAccountsProvider).value ?? const <AccountWithBalance>[];
    final total = ref.watch(totalBalanceProvider);
    final owed = ref.watch(owedToMeProvider).value ?? 0;
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openAccountForm(context),
        icon: const LedgerIcon('plus'),
        label: const Text('New account'),
        shape: const StadiumBorder(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          LedgerCard(
            child: Row(
              children: [
                const Expanded(child: InfoTerm('Total balance')),
                MoneyText(total, style: context.text.amountLarge),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final a in accounts)
                  ListTile(
                    leading: LedgerIcon(_iconFor(a.account.kind)),
                    title: Text(a.archived ? '${a.name} (archived)' : a.name),
                    subtitle: Text(_checkedText(a, today)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(
                          a.balanceMinor,
                          currency: a.currency,
                          tone: a.balanceMinor < 0 ? MoneyTone.negative : MoneyTone.plain,
                        ),
                        if (a.currency != 'EUR')
                          Text(formatMoney(a.baseMinor, 'EUR'), style: context.text.amountSmall),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AccountScreen(accountId: a.id)),
                    ),
                  ),
              ],
            ),
          ),
          if (owed > 0) ...[
            const SizedBox(height: 12),
            LedgerCard(
              child: Row(
                children: [
                  const Expanded(child: InfoTerm('Owed to me')),
                  MoneyText(owed),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('1 EUR = 1.95583 KM, a fixed rate.', style: context.text.caption),
        ],
      ),
    );
  }
}

extension on AccountWithBalance {
  bool get archived => account.archived;
}

String _iconFor(String kind) => switch (kind) {
  'cash' => 'dollar',
  'card' => 'receipt',
  'savings' => 'shield',
  _ => 'wallet',
};

String _checkedText(AccountWithBalance a, String today) {
  final kind = AccountKind.values.byName(a.account.kind).label;
  final on = a.account.checkedOn;
  if (on == null) return '$kind · never checked';
  final days = Day.between(on, today);
  return '$kind · ${days == 0 ? 'checked today' : 'checked $days ${days == 1 ? 'day' : 'days'} ago'}';
}

/// One account: its balance, a balance check, and its entries.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = (ref.watch(allAccountsProvider).value ?? const <AccountWithBalance>[])
        .where((x) => x.id == accountId)
        .firstOrNull;
    if (a == null) return Scaffold(appBar: AppBar());
    final today = ref.watch(todayProvider);
    final kind = AccountKind.values.byName(a.account.kind);
    final stale =
        a.account.checkedOn == null || Day.between(a.account.checkedOn!, today) >= checkEveryDays(kind);
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(a.name),
        actions: [
          IconButton(
            onPressed: () => openAccountForm(context, existing: a),
            icon: const LedgerIcon('pen'),
            tooltip: 'Edit account',
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
                Text('Balance', style: context.text.caption),
                MoneyText(
                  a.balanceMinor,
                  currency: a.currency,
                  style: context.text.balance.copyWith(fontSize: 30),
                ),
                if (a.currency != 'EUR')
                  Text(formatMoney(a.baseMinor, 'EUR'), style: context.text.amountSmall),
                if (kind == AccountKind.card)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('What you owe on the card counts as negative.', style: context.text.caption),
                  ),
                const SizedBox(height: 8),
                Text(
                  _checkedText(a, today),
                  style: context.text.bodySmall.copyWith(color: stale ? c.warning : null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => openBalanceCheck(context, a),
            icon: const LedgerIcon('check', size: 16),
            label: const Text('Check balance'),
          ),
          const SectionHeader('Entries'),
          EntryList(embedded: true, query: EntryQuery(accountId: a.id, limit: 50)),
        ],
      ),
    );
  }
}

/// Compare with the real balance and save any difference as Untracked.
Future<void> openBalanceCheck(BuildContext context, AccountWithBalance a) =>
    showLedgerSheet(context, (_) => _BalanceCheck(account: a));

class _BalanceCheck extends ConsumerStatefulWidget {
  const _BalanceCheck({required this.account});

  final AccountWithBalance account;

  @override
  ConsumerState<_BalanceCheck> createState() => _BalanceCheckState();
}

class _BalanceCheckState extends ConsumerState<_BalanceCheck> {
  final _real = TextEditingController();

  @override
  void dispose() {
    _real.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final negative = a.balanceMinor < 0;
    final entered = _real.text.trim().isNotEmpty;
    final real = parseAmount(_real.text) * (negative ? -1 : 1);
    final diff = real - a.balanceMinor;
    return SheetBody(
      title: 'Check ${a.name}',
      subtitle:
          'Enter the real balance${a.account.kind == 'cash' ? ' in your wallet' : ' from your bank'}. Ledgerly shows ${formatMoney(a.balanceMinor, a.currency)}.',
      children: [
        TextField(
          controller: _real,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Real balance, ${a.currency == 'BAM' ? 'KM' : 'EUR'}${negative ? ', owed' : ''}',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (entered)
          Text(
            diff == 0
                ? 'It matches. Nothing to fix.'
                : 'The difference of ${formatMoney(diff, a.currency, sign: true)} is saved as Untracked. It is left out of income and spending.',
            style: context.text.bodySmall,
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: entered
              ? () async {
                  final (_, undo) = await ref
                      .read(entryRepositoryProvider)
                      .reconcile(
                        accountId: a.id,
                        realBalanceMinor: real,
                        currentBalanceMinor: a.balanceMinor,
                      );
                  if (!context.mounted) return;
                  showUndo(
                    context,
                    diff == 0
                        ? '${a.name} checked. It matches.'
                        : '${a.name} checked. ${formatMoney(diff, a.currency, sign: true)} saved as Untracked.',
                    undo: undo,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: Text(!entered || diff == 0 ? 'Mark as checked' : 'Save the difference'),
        ),
      ],
    );
  }
}

/// A new account, or a changed name or kind. The currency is fixed once entries exist.
Future<void> openAccountForm(BuildContext context, {AccountWithBalance? existing}) =>
    showLedgerSheet(context, (_) => AccountForm(existing: existing));

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.existing, this.onCreated});

  final AccountWithBalance? existing;
  final ValueChanged<String>? onCreated;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  final _opening = TextEditingController();
  late AccountKind _kind = widget.existing == null
      ? AccountKind.bank
      : AccountKind.values.byName(widget.existing!.account.kind);
  late String _currency = widget.existing?.currency ?? 'BAM';

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(accountRepositoryProvider);
    if (_name.text.trim().isEmpty) return showProblem(context, 'Give the account a name.');
    if (widget.existing == null) {
      final opening = parseAmount(_opening.text) * (_kind == AccountKind.card ? -1 : 1);
      final id = await repo.create(name: _name.text, kind: _kind, currency: _currency, openingMinor: opening);
      widget.onCreated?.call(id);
    } else {
      await repo.update(widget.existing!.id, name: _name.text, kind: _kind);
    }
    if (mounted && widget.onCreated == null) {
      showUndo(context, widget.existing == null ? '${_name.text.trim()} added' : 'Changes saved');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          autofocus: isNew,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'For example Main bank'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AccountKind>(
          isExpanded: true,
          initialValue: _kind,
          decoration: const InputDecoration(labelText: 'Kind'),
          items: [for (final k in AccountKind.values) DropdownMenuItem(value: k, child: Text(k.label))],
          onChanged: (k) => setState(() => _kind = k ?? _kind),
        ),
        if (isNew) ...[
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'BAM', label: Text('KM, BAM')),
              ButtonSegment(value: 'EUR', label: Text('Euro, EUR')),
            ],
            selected: {_currency},
            onSelectionChanged: (s) => setState(() => _currency = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _opening,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _kind == AccountKind.card ? 'Owed on the card today' : 'Balance today',
              helperText: 'What the account holds right now.',
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Archived'),
            subtitle: const Text('Hidden from new entries. Its history stays.'),
            value: widget.existing!.account.archived,
            onChanged: (v) async {
              await ref.read(accountRepositoryProvider).update(widget.existing!.id, archived: v);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: Text(isNew ? 'Save account' : 'Save changes')),
      ],
    );
    if (widget.onCreated != null) return body;
    return SheetBody(title: isNew ? 'New account' : 'Edit account', children: [body]);
  }
}
