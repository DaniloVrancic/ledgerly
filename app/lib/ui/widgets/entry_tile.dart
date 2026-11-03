// One entry in a list: its title, subcategory and account, and the amount with its sign.

import 'package:flutter/material.dart';

import '../../app/category_book.dart';
import '../../core/money.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/entry_view.dart';
import '../icons/ledger_icon.dart';
import '../theme/ledgerly_colors.dart';
import 'category_avatar.dart';
import 'money_text.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.view, required this.book, required this.accounts, this.onTap});

  final EntryView view;
  final CategoryBook book;
  final Map<String, AccountWithBalance> accounts;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final account = accounts[view.accountId]?.name ?? 'Account';
    final isTransfer = view.type == EntryType.transfer;
    final isCheck = view.type == EntryType.adjustment;

    final String meta;
    if (isTransfer) {
      meta = view.toAccountId == null
          ? account
          : '$account to ${accounts[view.toAccountId]?.name ?? 'Owed to me'}';
    } else if (isCheck) {
      meta = 'Balance check, not counted · $account';
    } else if (view.needsReview) {
      meta = 'Needs a category · $account';
    } else if (view.shareMinor != null) {
      meta = 'My share ${formatMoney(view.shareMinor!, view.currency)} · $account';
    } else {
      meta = '${book.nameOf(view.categoryId)} · $account';
    }

    final amount = view.amountMinor;
    final Widget lead = isTransfer || isCheck
        ? Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.neutralTint, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: LedgerIcon(
              isTransfer ? 'transfer' : 'flag',
              color: c.neutral,
              semanticLabel: isTransfer ? 'Transfer' : 'Balance check',
            ),
          )
        : view.needsReview
        ? Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.warningTint, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: LedgerIcon('flag', color: c.warning, semanticLabel: 'Needs a category'),
          )
        : CategoryAvatar.of(book[view.categoryId]);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              lead,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.displayTitle, style: context.text.subtitle),
                    Row(
                      children: [
                        Flexible(child: Text(meta, style: context.text.bodySmall)),
                        if (view.entry.repeatId != null) ...[
                          const SizedBox(width: 6),
                          LedgerIcon('repeat', size: 16, color: c.textTertiary, semanticLabel: 'Repeats'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    amount,
                    currency: view.currency,
                    sign: amount > 0 && !isTransfer,
                    tone: isTransfer || isCheck ? MoneyTone.neutral : MoneyTone.auto,
                  ),
                  if (view.currency != 'EUR')
                    Text(
                      formatMoney(toBase(amount.abs(), view.currency), 'EUR'),
                      style: context.text.amountSmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
