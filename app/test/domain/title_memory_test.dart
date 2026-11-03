import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/title_memory.dart';

TitleUse use(String title, String cat, String acc, int n, int recent) =>
    TitleUse(title: title, kind: 'expense', categoryId: cat, accountId: acc, count: n, recentCount: recent, lastAmountMinor: 100);

void main() {
  final memory = rememberTitles([
    use('Groceries', 'groceries', 'bank', 30, 12),
    use('groceries', 'groceries', 'cash', 4, 1),
    use('Electricity', 'electricity', 'bank', 12, 3),
    use('Ćevapi', 'dining', 'cash', 5, 5),
  ]);

  test('one memory per title, with its most used category and account', () {
    final g = memory.firstWhere((m) => m.title == 'Groceries');
    expect(memory.where((m) => m.title.toLowerCase() == 'groceries'), hasLength(1));
    expect(g.accountId, 'bank');
    expect(g.count, 34);
  });

  test('most used lately comes first', () {
    expect(memory.first.title, 'Groceries');
  });

  test('suggestions match parts of a title and ignore diacritics', () {
    expect(suggestTitles(memory, 'elec', 'expense').map((m) => m.title), ['Electricity']);
    expect(suggestTitles(memory, 'cev', 'expense').map((m) => m.title), ['Ćevapi']);
    expect(suggestTitles(memory, '', 'expense'), isEmpty);
    expect(suggestTitles(memory, 'elec', 'income'), isEmpty);
  });

  test('an exact title is recognised', () {
    expect(exactTitle(memory, 'cevapi', 'expense')?.categoryId, 'dining');
    expect(exactTitle(memory, 'cev', 'expense'), isNull);
  });
}
