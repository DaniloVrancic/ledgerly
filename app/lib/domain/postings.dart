// The money rules, as plain Dart. Each entry becomes one or more postings:
//
//   Expense         Bank −85 on Groceries
//   Income          Bank +2,000 on Salary
//   Transfer        Bank −100, Savings +100, no category
//   Refund          Card +20 on the original category, so spending goes down
//   My share        Bank −25 on Dining, Bank −15 and Owed to me +15 with no category
//   Repayment       Owed to me −15, Bank +15, no category
//   Balance check   Cash −12 on Untracked, which reports leave out
//
// Income and spending only come from postings with a category, so transfers can never count.
// Postings without a category always add up to zero in EUR.

import '../core/money.dart';
import 'system_ids.dart';

class PostingDraft {
  const PostingDraft({
    required this.accountId,
    required this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.baseMinor,
  });

  final String accountId;
  final String? categoryId;

  /// In the account's currency. Negative leaves the account.
  final int amountMinor;
  final String currency;

  /// The EUR value, frozen now.
  final int baseMinor;
}

class RuleException implements Exception {
  RuleException(this.message);
  final String message;

  @override
  String toString() => message;
}

void _requirePositive(int minor) {
  if (minor <= 0) throw RuleException('Enter an amount above zero.');
}

/// An expense or income on one category. An expense can carry [shareMinor], the part that is
/// really the person's own; the rest is owed back and never counts as spending.
List<PostingDraft> entryPostings({
  required bool isExpense,
  required String accountId,
  required String currency,
  required int amountMinor,
  required String categoryId,
  int? shareMinor,
}) {
  _requirePositive(amountMinor);
  final base = toBase(amountMinor, currency);
  if (shareMinor == null || shareMinor == amountMinor) {
    final sign = isExpense ? -1 : 1;
    return [PostingDraft(accountId: accountId, categoryId: categoryId, amountMinor: sign * amountMinor, currency: currency, baseMinor: sign * base)];
  }
  if (!isExpense) throw RuleException('My share applies to an expense.');
  if (shareMinor <= 0 || shareMinor > amountMinor) {
    throw RuleException('My share must be above zero and no more than the amount.');
  }
  final owed = amountMinor - shareMinor;
  final shareBase = (base * shareMinor / amountMinor).round();
  final owedBase = base - shareBase;
  return [
    PostingDraft(accountId: accountId, categoryId: categoryId, amountMinor: -shareMinor, currency: currency, baseMinor: -shareBase),
    PostingDraft(accountId: accountId, categoryId: null, amountMinor: -owed, currency: currency, baseMinor: -owedBase),
    PostingDraft(accountId: SystemIds.owedToMe, categoryId: null, amountMinor: owed, currency: currency, baseMinor: owedBase),
  ];
}

/// Money moving between two of the person's accounts. Never income or spending.
List<PostingDraft> transferPostings({
  required String fromAccountId,
  required String fromCurrency,
  required String toAccountId,
  required String toCurrency,
  required int amountMinor,
}) {
  _requirePositive(amountMinor);
  if (fromAccountId == toAccountId) throw RuleException('Choose two different accounts.');
  final base = toBase(amountMinor, fromCurrency);
  return [
    PostingDraft(accountId: fromAccountId, categoryId: null, amountMinor: -amountMinor, currency: fromCurrency, baseMinor: -base),
    PostingDraft(accountId: toAccountId, categoryId: null, amountMinor: convert(amountMinor, fromCurrency, toCurrency), currency: toCurrency, baseMinor: base),
  ];
}

/// Money back for an expense. It goes on the expense's category, so it lowers spending there.
List<PostingDraft> refundPostings({required String accountId, required String currency, required int amountMinor, required String categoryId}) {
  _requirePositive(amountMinor);
  return [PostingDraft(accountId: accountId, categoryId: categoryId, amountMinor: amountMinor, currency: currency, baseMinor: toBase(amountMinor, currency))];
}

/// Someone paid back their part of a shared payment. Clears "Owed to me" and is never income.
List<PostingDraft> repaymentPostings({required String accountId, required String currency, required int amountMinor}) {
  _requirePositive(amountMinor);
  final base = toBase(amountMinor, currency);
  return [
    PostingDraft(accountId: SystemIds.owedToMe, categoryId: null, amountMinor: -amountMinor, currency: currency, baseMinor: -base),
    PostingDraft(accountId: accountId, categoryId: null, amountMinor: amountMinor, currency: currency, baseMinor: base),
  ];
}

/// A balance check found [differenceMinor] more (or less, when negative) than the app had.
List<PostingDraft> adjustmentPostings({required String accountId, required String currency, required int differenceMinor}) {
  if (differenceMinor == 0) return const [];
  return [
    PostingDraft(
      accountId: accountId,
      categoryId: SystemIds.untracked,
      amountMinor: differenceMinor,
      currency: currency,
      baseMinor: toBase(differenceMinor, currency),
    ),
  ];
}

/// Postings without a category must add up to zero in EUR, or money would appear from nowhere.
void checkBalanced(List<PostingDraft> postings) {
  final loose = postings.where((p) => p.categoryId == null).fold<int>(0, (s, p) => s + p.baseMinor);
  if (loose != 0) throw RuleException('Postings without a category are off by $loose.');
}
