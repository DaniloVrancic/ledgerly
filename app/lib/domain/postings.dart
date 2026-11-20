// The money rules, as plain Dart. Each entry becomes one or more postings:
//
//   Expense         Bank −85 on Groceries
//   Income          Bank +2,000 on Salary
//   Transfer        Bank −100, Savings +100, no category
//   Refund          Card +20 on the original category, so spending goes down
//   Split           Bank −30 on Groceries, Bank −12.50 on Household
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
    return [
      PostingDraft(
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: sign * amountMinor,
        currency: currency,
        baseMinor: sign * base,
      ),
    ];
  }
  if (!isExpense) throw RuleException('My share applies to an expense.');
  if (shareMinor <= 0 || shareMinor > amountMinor) {
    throw RuleException('My share must be above zero and no more than the amount.');
  }
  final owed = amountMinor - shareMinor;
  final shareBase = (base * shareMinor / amountMinor).round();
  final owedBase = base - shareBase;
  return [
    PostingDraft(
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: -shareMinor,
      currency: currency,
      baseMinor: -shareBase,
    ),
    PostingDraft(
      accountId: accountId,
      categoryId: null,
      amountMinor: -owed,
      currency: currency,
      baseMinor: -owedBase,
    ),
    PostingDraft(
      accountId: SystemIds.owedToMe,
      categoryId: null,
      amountMinor: owed,
      currency: currency,
      baseMinor: owedBase,
    ),
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
    PostingDraft(
      accountId: fromAccountId,
      categoryId: null,
      amountMinor: -amountMinor,
      currency: fromCurrency,
      baseMinor: -base,
    ),
    PostingDraft(
      accountId: toAccountId,
      categoryId: null,
      amountMinor: convert(amountMinor, fromCurrency, toCurrency),
      currency: toCurrency,
      baseMinor: base,
    ),
  ];
}

/// Money back for an expense. It goes on the expense's category, so it lowers spending there.
List<PostingDraft> refundPostings({
  required String accountId,
  required String currency,
  required int amountMinor,
  required String categoryId,
}) {
  _requirePositive(amountMinor);
  return [
    PostingDraft(
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      currency: currency,
      baseMinor: toBase(amountMinor, currency),
    ),
  ];
}

/// One part of a split expense, in the account's currency.
class SplitPart {
  const SplitPart(this.categoryId, this.amountMinor);

  final String categoryId;
  final int amountMinor;
}

/// Divides [total] in proportion to [weights] so the results add up exactly to [total].
/// The cents left over go to the largest remainders; ties go to the earlier weight.
List<int> allocate(int total, List<int> weights) {
  if (weights.isEmpty || weights.any((w) => w <= 0)) {
    throw RuleException('Each part needs an amount above zero.');
  }
  final sum = weights.fold(0, (s, w) => s + w);
  final sign = total < 0 ? -1 : 1;
  final whole = total.abs();
  final out = [for (final w in weights) whole * w ~/ sum];
  final order = List.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final r = (whole * weights[b] % sum).compareTo(whole * weights[a] % sum);
      return r != 0 ? r : a.compareTo(b);
    });
  var left = whole - out.fold(0, (s, x) => s + x);
  for (final i in order) {
    if (left == 0) break;
    out[i] += 1;
    left -= 1;
  }
  return [for (final x in out) sign * x];
}

void _checkParts(List<SplitPart> parts) {
  if (parts.isEmpty || parts.any((p) => p.amountMinor <= 0)) {
    throw RuleException('Each part needs an amount above zero.');
  }
  if (parts.map((p) => p.categoryId).toSet().length != parts.length) {
    throw RuleException('Each part needs a different category.');
  }
}

/// An expense divided across categories, all on one account. The EUR value of the whole payment
/// is frozen once and divided over the parts, so nothing is lost to rounding. [baseMinor] keeps
/// an earlier frozen value when the parts of a recorded entry change but its total does not.
List<PostingDraft> splitPostings({
  required String accountId,
  required String currency,
  required int amountMinor,
  required List<SplitPart> parts,
  int? baseMinor,
}) {
  _requirePositive(amountMinor);
  _checkParts(parts);
  if (parts.fold(0, (s, p) => s + p.amountMinor) != amountMinor) {
    throw RuleException('The parts must add up to the amount.');
  }
  final bases = allocate(baseMinor ?? toBase(amountMinor, currency), [for (final p in parts) p.amountMinor]);
  return [
    for (final (i, p) in parts.indexed)
      PostingDraft(
        accountId: accountId,
        categoryId: p.categoryId,
        amountMinor: -p.amountMinor,
        currency: currency,
        baseMinor: -bases[i],
      ),
  ];
}

/// Money back for a split expense, divided over its categories in proportion to the parts.
List<PostingDraft> splitRefundPostings({
  required String accountId,
  required String currency,
  required int amountMinor,
  required List<SplitPart> parts,
}) {
  _requirePositive(amountMinor);
  _checkParts(parts);
  final amounts = allocate(amountMinor, [for (final p in parts) p.amountMinor]);
  final weights = [for (final a in amounts) a > 0 ? a : 0];
  final bases = List.filled(parts.length, 0);
  final used = [
    for (var i = 0; i < parts.length; i++)
      if (weights[i] > 0) i,
  ];
  final usedBases = allocate(toBase(amountMinor, currency), [for (final i in used) weights[i]]);
  for (final (k, i) in used.indexed) {
    bases[i] = usedBases[k];
  }
  return [
    for (final i in used)
      PostingDraft(
        accountId: accountId,
        categoryId: parts[i].categoryId,
        amountMinor: amounts[i],
        currency: currency,
        baseMinor: bases[i],
      ),
  ];
}

/// Someone paid back their part of a shared payment. Clears "Owed to me" and is never income.
List<PostingDraft> repaymentPostings({
  required String accountId,
  required String currency,
  required int amountMinor,
}) {
  _requirePositive(amountMinor);
  final base = toBase(amountMinor, currency);
  return [
    PostingDraft(
      accountId: SystemIds.owedToMe,
      categoryId: null,
      amountMinor: -amountMinor,
      currency: currency,
      baseMinor: -base,
    ),
    PostingDraft(
      accountId: accountId,
      categoryId: null,
      amountMinor: amountMinor,
      currency: currency,
      baseMinor: base,
    ),
  ];
}

/// A balance check found [differenceMinor] more (or less, when negative) than the app had.
List<PostingDraft> adjustmentPostings({
  required String accountId,
  required String currency,
  required int differenceMinor,
}) {
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
