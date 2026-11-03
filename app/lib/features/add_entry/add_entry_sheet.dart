// The Add sheet. A common expense is two taps plus the digits: Add, amount, category chip.
//
// From top to bottom: frequent titles, the amount, the title (with titles used before),
// Expense / Income / Transfer, account and date, category chips, More details, the keypad.
// Tapping a chip saves at once. A Save button appears only when something else needs a
// decision: a remembered title, More details, or a transfer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/repeat_schedule.dart';
import '../../domain/title_memory.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/amount_keypad.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';
import '../categories/category_picker.dart';
import 'chip_order.dart';

enum EntryKind { expense, income, transfer }

/// Opens the Add sheet from anywhere.
Future<void> openAddEntry(BuildContext context, {EntryKind kind = EntryKind.expense}) {
  final ctx = rootNavigatorKey.currentContext ?? context;
  return showLedgerSheet(ctx, (_) => AddEntrySheet(initialKind: kind));
}

enum _Panel { none, account, toAccount, date, allCategories }

class AddEntrySheet extends ConsumerStatefulWidget {
  const AddEntrySheet({super.key, this.initialKind = EntryKind.expense});

  final EntryKind initialKind;

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  late EntryKind _kind = widget.initialKind;
  String _amount = '';
  final _title = TextEditingController();
  final _merchant = TextEditingController();
  final _note = TextEditingController();
  final _share = TextEditingController();
  final _textFocus = [FocusNode(), FocusNode(), FocusNode(), FocusNode()];
  String? _accountId;
  String? _toAccountId;
  late String _day = ref.read(todayProvider);
  String? _categoryId;

  /// A remembered title was chosen, so chips select and a Save button confirms.
  bool _remembered = false;
  bool _more = false;
  bool _keypad = true;

  /// How often it repeats, or null for a one-off.
  Every? _repeat;

  /// The repeat this title already belongs to. Saving pays its next occurrence.
  Repeat? _existingRepeat;
  List<TitleMemory> _suggestions = const [];
  _Panel _panel = _Panel.none;
  bool _saving = false;

  int get _minor => parseAmount(_amount);
  bool get _needsSave => _more || _remembered || _kind == EntryKind.transfer;
  bool get _isTyping => _textFocus.any((f) => f.hasFocus);

  @override
  void initState() {
    super.initState();
    _restoreLastAccounts();
  }

  Future<void> _restoreLastAccounts() async {
    final settings = ref.read(settingsRepositoryProvider);
    final last = await settings.read(SettingKeys.lastAccountId);
    final pair = (await settings.read(SettingKeys.lastTransfer))?.split('|');
    if (!mounted) return;
    setState(() {
      _accountId ??= last;
      if (pair != null && pair.length == 2) {
        _accountId = _kind == EntryKind.transfer ? pair[0] : _accountId;
        _toAccountId = pair[1];
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _merchant, _note, _share]) {
      c.dispose();
    }
    for (final f in _textFocus) {
      f.dispose();
    }
    super.dispose();
  }

  // ---- Reading what is on the sheet ----

  List<AccountWithBalance> get _accounts => ref.read(accountsProvider).value ?? const [];

  AccountWithBalance? _account(String? id) {
    final list = _accounts;
    if (list.isEmpty) return null;
    return list.where((a) => a.id == id).firstOrNull ?? list.first;
  }

  String get _currency => _account(_accountId)?.currency ?? 'EUR';

  /// Where a transfer goes. Never the account it leaves.
  AccountWithBalance? _transferTarget(AccountWithBalance from) =>
      _toAccountId == null || _toAccountId == from.id
      ? null
      : _accounts.where((a) => a.id == _toAccountId).firstOrNull;

  // ---- Actions ----

  void _key(String key) => setState(() => _amount = pressKey(_amount, key));

  KeyEventResult _onHardwareKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _isTyping) return KeyEventResult.ignored;
    final ch = event.character;
    if (ch != null && RegExp(r'^[0-9]$').hasMatch(ch)) {
      _key(ch);
    } else if (ch == '.' || ch == ',') {
      _key('.');
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _key('del');
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _onTitleChanged(String text) {
    final memory = ref.read(titleMemoryProvider).value ?? const [];
    final kind = _kind == EntryKind.income ? 'income' : 'expense';
    final exact = _kind == EntryKind.transfer ? null : exactTitle(memory, text, kind);
    setState(() {
      _existingRepeat = null;
      if (exact != null) {
        _suggestions = const [];
        _remember(exact, setText: false);
      } else {
        _suggestions = _kind == EntryKind.transfer ? const [] : suggestTitles(memory, text, kind);
      }
    });
  }

  /// Brings back a title's usual subcategory and account, and its repeat if it has one.
  void _remember(TitleMemory m, {bool setText = true}) {
    if (setText) _title.text = m.title;
    _categoryId = m.categoryId;
    _accountId = m.accountId;
    _remembered = true;
    _suggestions = const [];
    _panel = _Panel.none;
    final kind = _kind == EntryKind.income ? 'income' : 'expense';
    ref.read(repeatRepositoryProvider).findByTitle(m.title, kind).then((r) {
      if (!mounted || r == null) return;
      setState(() {
        _existingRepeat = r;
        _repeat = Every.parse(r.every);
        _accountId = r.accountId;
      });
    });
  }

  void _pickTitle(TitleMemory m) {
    setState(() => _remember(m));
    // With an amount already typed, a title saves at once, like a chip.
    if (_minor > 0 && !_more) WidgetsBinding.instance.addPostFrameCallback((_) => _save());
  }

  void _pickChip(String categoryId) {
    if (_minor <= 0) return;
    setState(() {
      _categoryId = _categoryId == categoryId && _needsSave ? null : categoryId;
      _panel = _Panel.none;
    });
    if (!_needsSave) _save();
  }

  void _setKind(EntryKind kind) => setState(() {
    _kind = kind;
    _categoryId = null;
    _remembered = false;
    _existingRepeat = null;
    _repeat = null;
    _suggestions = const [];
    _panel = _Panel.none;
  });

  Future<void> _saveLater() async {
    if (_minor <= 0) return;
    final account = _account(_accountId)!;
    final (_, undo) = await ref
        .read(entryRepositoryProvider)
        .addLater(accountId: account.id, amountMinor: _minor, title: _title.text, day: _day);
    _finish('Saved ${formatMoney(_minor, account.currency)} to Needs Review', undo);
  }

  Future<void> _save() async {
    if (_saving || _minor <= 0) return;
    final account = _account(_accountId);
    if (account == null) return;
    setState(() => _saving = true);
    try {
      final entries = ref.read(entryRepositoryProvider);
      final settings = ref.read(settingsRepositoryProvider);
      if (_kind == EntryKind.transfer) {
        final to = _transferTarget(account);
        if (to == null) throw 'Choose an account to move the money to.';
        final (_, undo) = await entries.addTransfer(
          fromAccountId: account.id,
          toAccountId: to.id,
          amountMinor: _minor,
          title: _title.text.trim().isEmpty ? null : _title.text,
          note: _note.text,
          day: _day,
        );
        await settings.write(SettingKeys.lastTransfer, '${account.id}|${to.id}');
        _finish('Transfer saved, ${formatMoney(_minor, account.currency)} to ${to.name}', undo);
        return;
      }
      final categoryId = _categoryId;
      if (categoryId == null) throw 'Choose a category.';
      final book = ref.read(categoryBookProvider);
      final title = _title.text.trim().isEmpty ? book.nameOf(categoryId) : _title.text.trim();
      final isExpense = _kind == EntryKind.expense;
      final share = _kind == EntryKind.expense && _share.text.trim().isNotEmpty
          ? parseAmount(_share.text)
          : null;
      await settings.write(SettingKeys.lastAccountId, account.id);

      // A title that already repeats: this entry pays its next occurrence.
      final existing = _existingRepeat;
      if (existing != null && _repeat != null) {
        final next = advance(existing.nextDay, Every.parse(existing.every), existing.anchorDay);
        final undo = await ref
            .read(repeatRepositoryProvider)
            .markPaid(
              existing.id,
              amountMinor: _minor,
              title: title,
              merchant: _merchant.text,
              note: _note.text,
              accountId: account.id,
            );
        _finish(
          'Saved ${formatMoney(_minor, account.currency)}, $title. Paid, next on ${Day.short(next)}',
          undo,
        );
        return;
      }

      String? repeatId;
      Undo? undoRepeat;
      if (_repeat != null) {
        final repeats = ref.read(repeatRepositoryProvider);
        repeatId = await repeats.create(
          title: title,
          kind: isExpense ? 'expense' : 'income',
          categoryId: categoryId,
          accountId: account.id,
          amountMinor: _minor,
          every: _repeat!,
          nextDay: advance(_day, _repeat!, Day.dayOfMonth(_day)),
        );
        final id = repeatId;
        undoRepeat = () async => repeats.stop(id);
      }
      final (_, undoEntry) = await entries.addEntry(
        isExpense: isExpense,
        accountId: account.id,
        amountMinor: _minor,
        categoryId: categoryId,
        title: title,
        merchant: _merchant.text,
        note: _note.text,
        day: _day,
        shareMinor: share,
        repeatId: repeatId,
        repeatDay: repeatId == null ? null : _day,
      );
      final repeatText = _repeat == null
          ? ''
          : '. Repeats ${_repeat!.label.toLowerCase()}, next on ${Day.short(advance(_day, _repeat!, Day.dayOfMonth(_day)))}';
      _finish('Saved ${formatMoney(_minor, account.currency)}, $title$repeatText', () async {
        await undoEntry();
        await undoRepeat?.call();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showProblem(context, e);
      }
    }
  }

  void _finish(String message, Undo undo) {
    final kind = _kind;
    showUndo(
      context,
      message,
      undo: undo,
      extraLabel: 'Add another',
      onExtra: () => openAddEntry(context, kind: kind),
    );
    Navigator.of(context).pop();
  }

  // ---- Building the sheet ----

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    if (accounts.isEmpty) {
      return const SheetBody(title: 'Add', children: [Text('Add an account first, under More, Accounts.')]);
    }
    final c = context.colors;
    final account = _account(_accountId)!;
    if (_panel == _Panel.allCategories) {
      return SheetBody(
        title: 'Choose a category',
        children: [
          CategoryPicker(
            kind: _kind == EntryKind.income ? 'income' : 'expense',
            accountId: account.id,
            onPicked: (id) {
              final book = ref.read(categoryBookProvider);
              setState(() {
                _panel = _Panel.none;
                // A new category limited to another account switches to that account.
                if (!book.appliesTo(id, account.id)) {
                  _accountId = book.limits[book.topOf(id)]?.firstOrNull ?? _accountId;
                }
              });
              _pickChip(id);
            },
          ),
          TextButton(
            onPressed: () => setState(() => _panel = _Panel.none),
            child: const Text('Back to the entry'),
          ),
        ],
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _onHardwareKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _frequentTitles(),
            _amountLine(c, account),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              focusNode: _textFocus[0],
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _kind == EntryKind.transfer ? 'Title, optional' : 'Title, for example Groceries',
              ),
              onChanged: _onTitleChanged,
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final m in _suggestions) _titleChip(m)]),
            ],
            if (_existingRepeat != null && _repeat != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    LedgerIcon('repeat', size: 16, color: c.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_existingRepeat!.title} repeats. Saving marks the one on ${Day.short(_existingRepeat!.nextDay)} as paid.',
                        style: context.text.caption,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SegmentedButton<EntryKind>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: EntryKind.expense,
                  label: const Text('Expense'),
                  icon: LedgerIcon('down', size: 16, color: c.negative),
                ),
                ButtonSegment(
                  value: EntryKind.income,
                  label: const Text('Income'),
                  icon: LedgerIcon('up', size: 16, color: c.positive),
                ),
                ButtonSegment(
                  value: EntryKind.transfer,
                  label: const Text('Transfer'),
                  icon: LedgerIcon('transfer', size: 16, color: c.neutral),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => _setKind(s.first),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillButton(
                  label: account.name,
                  icon: 'wallet',
                  selected: _panel == _Panel.account,
                  onPressed: () => _togglePanel(_Panel.account),
                ),
                if (_kind == EntryKind.transfer) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LedgerIcon('transfer', size: 16, color: c.neutral),
                  ),
                  PillButton(
                    label: _transferTarget(account)?.name ?? 'Choose account',
                    icon: 'wallet',
                    selected: _panel == _Panel.toAccount,
                    onPressed: () => _togglePanel(_Panel.toAccount),
                  ),
                ],
                PillButton(
                  label: Day.label(_day, ref.read(todayProvider)),
                  icon: 'calendar',
                  selected: _panel == _Panel.date,
                  onPressed: () => _togglePanel(_Panel.date),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _choiceArea(c, account),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => setState(() {
                      _more = !_more;
                      _keypad = !_more || _minor == 0;
                    }),
                    icon: LedgerIcon(_more ? 'up' : 'chevronDown', size: 16),
                    label: const Text('More details'),
                  ),
                ),
                if (_needsSave)
                  FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(_kind == EntryKind.transfer ? 'Save transfer' : 'Save'),
                  ),
              ],
            ),
            if (_more) _moreDetails(),
            if (_keypad) ...[const SizedBox(height: 8), Center(child: AmountKeypad(onKey: _key))],
          ],
        ),
      ),
    );
  }

  bool get _canSave => _minor > 0 && !_saving && (_kind == EntryKind.transfer || _categoryId != null);

  void _togglePanel(_Panel p) => setState(() => _panel = _panel == p ? _Panel.none : p);

  Widget _amountLine(LedgerlyColors c, AccountWithBalance account) {
    final text = formatMoney(_minor, _currency);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _keypad = !_keypad),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              text,
              style: context.text.balance.copyWith(
                fontSize: 32,
                color: _minor == 0 ? c.textTertiary : c.textPrimary,
              ),
              semanticsLabel: 'Amount $text',
            ),
            if (_currency != 'EUR' && _minor > 0)
              Text(formatMoney(toBase(_minor, _currency), 'EUR'), style: context.text.amountSmall),
          ],
        ),
      ),
    );
  }

  Widget _titleChip(TitleMemory m) {
    final book = ref.read(categoryBookProvider);
    final cat = book[m.categoryId];
    return ActionChip(
      avatar: LedgerIcon(cat?.icon ?? 'clock', size: 16, color: context.colors.category(cat?.colorSlot ?? 0)),
      label: Text(m.title),
      onPressed: () => _pickTitle(m),
    );
  }

  /// The titles used most in the last 90 days, so a frequent entry is one tap after the amount.
  Widget _frequentTitles() {
    if (_kind == EntryKind.transfer || _title.text.isNotEmpty) return const SizedBox(height: 4);
    final kind = _kind == EntryKind.income ? 'income' : 'expense';
    final frequent = (ref.watch(titleMemoryProvider).value ?? const <TitleMemory>[])
        .where((m) => m.kind == kind)
        .take(6)
        .toList();
    if (frequent.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: frequent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Center(child: _titleChip(frequent[i])),
      ),
    );
  }

  Widget _choiceArea(LedgerlyColors c, AccountWithBalance account) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    switch (_panel) {
      case _Panel.account:
      case _Panel.toAccount:
        final selected = _panel == _Panel.account ? account.id : _toAccountId;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in accounts)
              PillButton(
                label: '${a.name}  ${a.currency == 'BAM' ? 'KM' : 'EUR'}',
                selected: a.id == selected,
                onPressed: () => setState(() {
                  if (_panel == _Panel.account) {
                    _accountId = a.id;
                    // Chips follow the account. A category that does not apply is cleared.
                    final book = ref.read(categoryBookProvider);
                    if (_categoryId != null && !book.appliesTo(_categoryId!, a.id)) _categoryId = null;
                  } else {
                    _toAccountId = a.id;
                  }
                  _panel = _Panel.none;
                }),
              ),
          ],
        );
      case _Panel.date:
        final today = ref.read(todayProvider);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillButton(
              label: 'Today',
              selected: _day == today,
              onPressed: () => setState(() => (_day = today, _panel = _Panel.none)),
            ),
            PillButton(
              label: 'Yesterday',
              selected: _day == Day.add(today, -1),
              onPressed: () => setState(() => (_day = Day.add(today, -1), _panel = _Panel.none)),
            ),
            PillButton(
              label: 'Pick a date',
              icon: 'calendar',
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: Day.parse(_day),
                  firstDate: DateTime(2000),
                  lastDate: Day.parse(today),
                );
                if (picked != null) setState(() => (_day = Day.of(picked), _panel = _Panel.none));
              },
            ),
          ],
        );
      case _Panel.none:
      case _Panel.allCategories:
        if (_kind == EntryKind.transfer) return _transferNote(c, account);
        return _chips(c, account);
    }
  }

  Widget _transferNote(LedgerlyColors c, AccountWithBalance from) {
    final to = _transferTarget(from);
    if (to == null || to.currency == from.currency) {
      return Text(
        'Moves money between your accounts. Income and spending do not change.',
        style: context.text.bodySmall,
      );
    }
    return Text(
      '${formatMoney(_minor, from.currency)} leaves ${from.name} and ${formatMoney(convert(_minor, from.currency, to.currency), to.currency)} arrives in ${to.name}, '
      'at the fixed rate of 1 EUR = 1.95583 KM. Income and spending do not change.',
      style: context.text.bodySmall,
    );
  }

  Widget _chips(LedgerlyColors c, AccountWithBalance account) {
    final kind = _kind == EntryKind.income ? 'income' : 'expense';
    final book = ref.watch(categoryBookProvider);
    final order = ref.watch(chipOrderProvider((account.id, kind))).value ?? const <String>[];
    final ids = chipsFor(
      book: book,
      mostUsed: order,
      kind: kind,
      accountId: account.id,
      selected: _categoryId,
    );
    final enabled = _minor > 0;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final id in ids)
          _CategoryChip(
            label: book.nameOf(id),
            icon: book[id]?.icon ?? 'dots',
            color: c.category(book[id]?.colorSlot ?? 0),
            selected: id == _categoryId,
            enabled: enabled,
            onTap: () => _pickChip(id),
          ),
        _CategoryChip(
          label: 'All',
          icon: 'search',
          color: c.textSecondary,
          enabled: enabled,
          outlined: true,
          onTap: () => setState(() => _panel = _Panel.allCategories),
        ),
        if (_kind == EntryKind.expense)
          _CategoryChip(
            label: 'Later',
            icon: 'clock',
            color: c.textSecondary,
            enabled: enabled,
            outlined: true,
            onTap: _saveLater,
          ),
      ],
    );
  }

  Widget _moreDetails() {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_kind != EntryKind.transfer) ...[
            Text('Repeat', style: context.text.label),
            const SizedBox(height: 6),
            SegmentedButton<Every?>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: null, label: Text('Never')),
                for (final e in Every.values) ButtonSegment(value: e, label: Text(e.label)),
              ],
              selected: {_repeat},
              onSelectionChanged: (s) => setState(() => _repeat = s.first),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                _existingRepeat != null && _repeat != null
                    ? 'Already repeats. Choose Never to save this as a one-off.'
                    : _repeat == null
                    ? 'Set a repeat to make the next one a single tap.'
                    : 'Next on ${Day.short(advance(_day, _repeat!, Day.dayOfMonth(_day)))}. It waits as Due until you mark it paid.',
                style: context.text.caption,
              ),
            ),
            TextField(
              controller: _merchant,
              focusNode: _textFocus[1],
              decoration: const InputDecoration(
                labelText: 'Merchant, optional',
                hintText: 'For example Konzum',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_kind == EntryKind.expense) ...[
            TextField(
              controller: _share,
              focusNode: _textFocus[2],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'My share, optional',
                helperText: 'When you paid for others too. Only your share counts as spending; the rest is owed to you.',
                helperMaxLines: 2,
                helperStyle: context.text.caption.copyWith(color: c.textTertiary),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _note,
            focusNode: _textFocus[3],
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Note, optional'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.outlined = false,
  });

  final String label;
  final String icon;
  final Color color;
  final bool selected;
  final bool enabled;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final side = selected
        ? BorderSide(color: c.accent, width: 1.5)
        : (outlined ? BorderSide(color: c.borderControl) : BorderSide.none);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: selected ? c.surfaceTint : (outlined ? Colors.transparent : c.surface2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: side),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LedgerIcon(icon, size: 20, color: enabled ? color : c.textDisabled),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: context.text.label.copyWith(color: enabled ? c.textPrimary : c.textDisabled),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
