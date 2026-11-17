// Compares a bank statement with what is already recorded on that account. A statement row
// matches an entry with the same amount within a few days. Each entry matches one row at
// most, closest day first. What is left is either to add or a likely duplicate in the file.

import '../../core/day.dart';
import '../../core/text.dart';
import 'statement_mapping.dart';

enum RowStatus { matched, toAdd, duplicate, invalid }

/// A recorded amount on the account: an entry's posting, in the account's currency.
class ExistingEntry {
  const ExistingEntry({required this.id, required this.day, required this.amountMinor});

  final String id;
  final String day;

  /// Negative is money out.
  final int amountMinor;
}

class ReviewRow {
  const ReviewRow(this.row, this.status, {this.matchedEntryId});

  final StatementRow row;
  final RowStatus status;
  final String? matchedEntryId;
}

/// Every row of the statement with its status, in file order.
List<ReviewRow> reviewStatement(List<StatementRow> rows, List<ExistingEntry> existing, {int dayWindow = 3}) {
  final pairs = <(int, int, int)>[]; // (days apart, row index, entry index)
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    if (!row.ok) continue;
    for (var e = 0; e < existing.length; e++) {
      final entry = existing[e];
      if (entry.amountMinor != row.amountMinor) continue;
      final apart = Day.between(row.day!, entry.day).abs();
      if (apart <= dayWindow) pairs.add((apart, r, e));
    }
  }
  pairs.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  final matchOfRow = <int, int>{};
  final usedEntries = <int>{};
  for (final (_, r, e) in pairs) {
    if (matchOfRow.containsKey(r) || usedEntries.contains(e)) continue;
    matchOfRow[r] = e;
    usedEntries.add(e);
  }

  final seen = <String>{};
  return [
    for (var r = 0; r < rows.length; r++)
      if (!rows[r].ok)
        ReviewRow(rows[r], RowStatus.invalid)
      else if (matchOfRow[r] != null)
        ReviewRow(rows[r], RowStatus.matched, matchedEntryId: existing[matchOfRow[r]!].id)
      else if (!seen.add('${rows[r].day}|${rows[r].amountMinor}|${fold(rows[r].description)}'))
        ReviewRow(rows[r], RowStatus.duplicate)
      else
        ReviewRow(rows[r], RowStatus.toAdd),
  ];
}
