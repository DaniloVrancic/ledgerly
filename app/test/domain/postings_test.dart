import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money.dart';
import 'package:ledgerly/domain/postings.dart';
import 'package:ledgerly/domain/system_ids.dart';

int counted(List<PostingDraft> ps) =>
    ps.where((p) => p.categoryId != null).fold(0, (s, p) => s + p.baseMinor);
int onAccount(List<PostingDraft> ps, String id) =>
    ps.where((p) => p.accountId == id).fold(0, (s, p) => s + p.amountMinor);

void main() {
  test('an expense leaves the account and counts on its category', () {
    final ps = entryPostings(
      isExpense: true,
      accountId: 'bank',
      currency: 'EUR',
      amountMinor: 8500,
      categoryId: 'groceries',
    );
    expect(ps, hasLength(1));
    expect(ps.single.amountMinor, -8500);
    expect(counted(ps), -8500);
  });

  test('a BAM expense freezes its EUR value', () {
    final ps = entryPostings(
      isExpense: true,
      accountId: 'cash',
      currency: 'BAM',
      amountMinor: 1200,
      categoryId: 'coffee',
    );
    expect(ps.single.amountMinor, -1200);
    expect(ps.single.baseMinor, -614);
  });

  test('a transfer is never income or spending', () {
    final ps = transferPostings(
      fromAccountId: 'bank',
      fromCurrency: 'BAM',
      toAccountId: 'euro',
      toCurrency: 'EUR',
      amountMinor: 20000,
    );
    expect(counted(ps), 0);
    expect(ps.every((p) => p.categoryId == null), isTrue);
    expect(ps.fold<int>(0, (s, p) => s + p.baseMinor), 0);
    expect(onAccount(ps, 'euro'), 10226);
    checkBalanced(ps);
  });

  test('a transfer needs two accounts', () {
    expect(
      () => transferPostings(
        fromAccountId: 'a',
        fromCurrency: 'EUR',
        toAccountId: 'a',
        toCurrency: 'EUR',
        amountMinor: 1,
      ),
      throwsA(isA<RuleException>()),
    );
  });

  test('my share: only my part counts, the rest is owed to me', () {
    final ps = entryPostings(
      isExpense: true,
      accountId: 'bank',
      currency: 'EUR',
      amountMinor: 4000,
      categoryId: 'dining',
      shareMinor: 2500,
    );
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
    expect(
      () => entryPostings(isExpense: true, accountId: 'a', currency: 'EUR', amountMinor: 0, categoryId: 'c'),
      throwsA(isA<RuleException>()),
    );
    expect(
      () => entryPostings(
        isExpense: true,
        accountId: 'a',
        currency: 'EUR',
        amountMinor: 100,
        categoryId: 'c',
        shareMinor: 200,
      ),
      throwsA(isA<RuleException>()),
    );
  });

  test('unbalanced postings without a category are refused', () {
    const bad = [
      PostingDraft(accountId: 'a', categoryId: null, amountMinor: -100, currency: 'EUR', baseMinor: -100),
    ];
    expect(() => checkBalanced(bad), throwsA(isA<RuleException>()));
  });

  group('split', () {
    test('allocate divides exactly, the largest remainders first', () {
      expect(allocate(1000, [1, 1, 1]), [334, 333, 333]);
      expect(allocate(-1000, [1, 1, 1]), [-334, -333, -333]);
      expect(allocate(511, [3000, 1250]).fold(0, (s, x) => s + x), 511);
      expect(allocate(0, [5, 7]), [0, 0]);
      expect(() => allocate(100, [1, 0]), throwsA(isA<RuleException>()));
    });

    test('a EUR split counts each part on its own category', () {
      final ps = splitPostings(
        accountId: 'bank',
        currency: 'EUR',
        amountMinor: 4250,
        parts: const [SplitPart('groceries', 3000), SplitPart('household', 1250)],
      );
      expect([for (final p in ps) p.categoryId], ['groceries', 'household']);
      expect([for (final p in ps) p.baseMinor], [-3000, -1250]);
      expect(onAccount(ps, 'bank'), -4250);
      checkBalanced(ps);
    });

    test('a BAM split freezes the whole EUR value and divides it without losing a cent', () {
      final ps = splitPostings(
        accountId: 'cash',
        currency: 'BAM',
        amountMinor: 1000,
        parts: const [SplitPart('groceries', 333), SplitPart('household', 333), SplitPart('cosmetics', 334)],
      );
      expect(counted(ps), -toBase(1000, 'BAM'));
      for (final p in ps) {
        expect((p.baseMinor - toBase(p.amountMinor, 'BAM')).abs(), lessThanOrEqualTo(1));
      }
    });

    test('a kept EUR value is divided instead of a new one', () {
      final ps = splitPostings(
        accountId: 'cash',
        currency: 'BAM',
        amountMinor: 1000,
        parts: const [SplitPart('groceries', 500), SplitPart('household', 500)],
        baseMinor: 512,
      );
      expect(counted(ps), -512);
    });

    test('a split that does not add up, has a zero part or repeats a category is refused', () {
      List<PostingDraft> split(List<SplitPart> parts, {int amount = 1000}) =>
          splitPostings(accountId: 'bank', currency: 'EUR', amountMinor: amount, parts: parts);
      expect(() => split(const [SplitPart('a', 600), SplitPart('b', 300)]), throwsA(isA<RuleException>()));
      expect(() => split(const [SplitPart('a', 1000), SplitPart('b', 0)]), throwsA(isA<RuleException>()));
      expect(() => split(const [SplitPart('a', 500), SplitPart('a', 500)]), throwsA(isA<RuleException>()));
      expect(() => split(const []), throwsA(isA<RuleException>()));
    });

    test('a refund of a split lowers each category in proportion', () {
      final ps = splitRefundPostings(
        accountId: 'bank',
        currency: 'EUR',
        amountMinor: 1000,
        parts: const [SplitPart('groceries', 3000), SplitPart('household', 1000)],
      );
      expect(
        [for (final p in ps) (p.categoryId, p.amountMinor, p.baseMinor)],
        [('groceries', 750, 750), ('household', 250, 250)],
      );
    });

    test('a refund too small to divide leaves out the parts that get nothing', () {
      final ps = splitRefundPostings(
        accountId: 'cash',
        currency: 'BAM',
        amountMinor: 1,
        parts: const [SplitPart('groceries', 3000), SplitPart('household', 1000)],
      );
      expect(ps.single.categoryId, 'groceries');
      expect(ps.single.amountMinor, 1);
    });
  });
}
