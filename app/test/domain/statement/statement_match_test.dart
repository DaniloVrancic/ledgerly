import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/statement/statement_mapping.dart';
import 'package:ledgerly/domain/statement/statement_match.dart';

StatementRow row(int line, String day, int amount, [String description = 'Shop']) =>
    StatementRow(line: line, day: day, amountMinor: amount, description: description);

void main() {
  test('a row matches the same amount within three days, closest day first', () {
    final rows = [row(1, '2026-10-10', -1200), row(2, '2026-10-20', -1200)];
    const existing = [
      ExistingEntry(id: 'far', day: '2026-10-13', amountMinor: -1200),
      ExistingEntry(id: 'near', day: '2026-10-11', amountMinor: -1200),
    ];
    final review = reviewStatement(rows, existing);
    expect(review[0].status, RowStatus.matched);
    expect(review[0].matchedEntryId, 'near');
    expect(review[1].status, RowStatus.toAdd, reason: 'the 13th is seven days from the 20th');
  });

  test('each entry matches one row at most', () {
    final rows = [row(1, '2026-10-10', -400, 'Coffee'), row(2, '2026-10-10', -400, 'Coffee')];
    const existing = [ExistingEntry(id: 'a', day: '2026-10-10', amountMinor: -400)];
    final review = reviewStatement(rows, existing);
    expect(review.map((r) => r.status), [RowStatus.matched, RowStatus.toAdd]);
  });

  test('two recorded coffees match both lines of the statement', () {
    final rows = [row(1, '2026-10-10', -400, 'Coffee'), row(2, '2026-10-10', -400, 'Coffee')];
    const existing = [
      ExistingEntry(id: 'a', day: '2026-10-10', amountMinor: -400),
      ExistingEntry(id: 'b', day: '2026-10-10', amountMinor: -400),
    ];
    expect(reviewStatement(rows, existing).map((r) => r.status), everyElement(RowStatus.matched));
  });

  test('a line repeated in the file is a likely duplicate', () {
    final rows = [
      row(1, '2026-10-10', -999, 'Bingo'),
      row(2, '2026-10-10', -999, 'BINGO'),
      row(3, '2026-10-11', -999),
    ];
    expect(reviewStatement(rows, const []).map((r) => r.status), [
      RowStatus.toAdd,
      RowStatus.duplicate,
      RowStatus.toAdd,
    ]);
  });

  test('a transfer already recorded on the account matches its statement line', () {
    final rows = [row(1, '2026-10-05', -20000, 'ATM withdrawal')];
    const existing = [ExistingEntry(id: 'atm', day: '2026-10-05', amountMinor: -20000)];
    expect(reviewStatement(rows, existing).single.status, RowStatus.matched);
  });

  test('rows that could not be read are invalid, and money in must match money in', () {
    final rows = [const StatementRow(line: 1, error: 'No date'), row(2, '2026-10-10', 1200)];
    const existing = [ExistingEntry(id: 'out', day: '2026-10-10', amountMinor: -1200)];
    expect(reviewStatement(rows, existing).map((r) => r.status), [RowStatus.invalid, RowStatus.toAdd]);
  });

  test('importing the same statement again finds nothing to add', () {
    final rows = [row(1, '2026-10-01', -4520), row(2, '2026-10-03', 200000), row(3, '2026-10-04', -160)];
    final firstTime = reviewStatement(rows, const []);
    expect(firstTime.where((r) => r.status == RowStatus.toAdd), hasLength(3));
    final recorded = [
      for (final (i, r) in rows.indexed) ExistingEntry(id: 'e$i', day: r.day!, amountMinor: r.amountMinor),
    ];
    expect(reviewStatement(rows, recorded).where((r) => r.status == RowStatus.toAdd), isEmpty);
  });
}
