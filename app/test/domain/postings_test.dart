import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/postings.dart';
import 'package:ledgerly/domain/system_ids.dart';

int counted(List<PostingDraft> ps) => ps.where((p) => p.categoryId != null).fold(0, (s, p) => s + p.baseMinor);
int onAccount(List<PostingDraft> ps, String id) => ps.where((p) => p.accountId == id).fold(0, (s, p) => s + p.amountMinor);

void main() {
  test('an expense leaves the account and counts on its category', () {
    final ps = entryPostings(isExpense: true, accountId: 'bank', currency: 'EUR', amountMinor: 8500, categoryId: 'groceries');
    expect(ps, hasLength(1));
    expect(ps.single.amountMinor, -8500);
    expect(counted(ps), -8500);
  });

  test('a BAM expense freezes its EUR value', () {
    final ps = entryPostings(isExpense: true, accountId: 'cash', currency: 'BAM', amountMinor: 1200, categoryId: 'coffee');
    expect(ps.single.amountMinor, -1200);
    expect(ps.single.baseMinor, -614);
  });

  test('a transfer is never income or spending', () {
    final ps = transferPostings(fromAccountId: 'bank', fromCurrency: 'BAM', toAccountId: 'euro', toCurrency: 'EUR', amountMinor: 20000);
    expect(counted(ps), 0);
    expect(ps.every((p) => p.categoryId == null), isTrue);
    expect(ps.fold<int>(0, (s, p) => s + p.baseMinor), 0);
    expect(onAccount(ps, 'euro'), 10226);
    checkBalanced(ps);
  });

  test('a transfer needs two accounts', () {
    expect(() => transferPostings(fromAccountId: 'a', fromCurrency: 'EUR', toAccountId: 'a', toCurrency: 'EUR', amountMinor: 1), throwsA(isA<RuleException>()));
  });

  test('my share: only my part counts, the rest is owed to me', () {
    final ps = entryPostings(isExpense: true, accountId: 'bank', currency: 'EUR', amountMinor: 4000, categoryId: 'dining', shareMinor: 2500);
    expect(counted(ps), -2500);
    expect(onAccount(ps, 'bank'), -4000);
    expect(onAccount(ps, SystemIds.owedToMe), 1500);
    checkBalanced(ps);
  });

  test('a repayment clears what is owed and is not income', () {
    final ps = repaymentPostings(accountId: 'bank', currency: 'EUR', amountMinor: 1500);
    expect(counted(ps), 0);
    expect(onAccount(ps, SystemIds.owedToMe), -1500);
    expect(onAccount(ps, 'bank'), 1500);
    checkBalanced(ps);
  });

  test('a refund lowers spending on the original category', () {
    final ps = refundPostings(accountId: 'card', currency: 'EUR', amountMinor: 2990, categoryId: 'clothes');
    expect(counted(ps), 2990);
  });

  test('a balance check goes on Untracked', () {
    final ps = adjustmentPostings(accountId: 'cash', currency: 'BAM', differenceMinor: -1200);
    expect(ps.single.categoryId, SystemIds.untracked);
    expect(adjustmentPostings(accountId: 'cash', currency: 'BAM', differenceMinor: 0), isEmpty);
  });

  test('amounts must be above zero', () {
    expect(() => entryPostings(isExpense: true, accountId: 'a', currency: 'EUR', amountMinor: 0, categoryId: 'c'), throwsA(isA<RuleException>()));
    expect(() => entryPostings(isExpense: true, accountId: 'a', currency: 'EUR', amountMinor: 100, categoryId: 'c', shareMinor: 200), throwsA(isA<RuleException>()));
  });

  test('unbalanced postings without a category are refused', () {
    const bad = [PostingDraft(accountId: 'a', categoryId: null, amountMinor: -100, currency: 'EUR', baseMinor: -100)];
    expect(() => checkBalanced(bad), throwsA(isA<RuleException>()));
  });
}
