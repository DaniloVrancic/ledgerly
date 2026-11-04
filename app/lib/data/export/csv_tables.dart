// Every synced table as a CSV file, so a data file can be read without Ledgerly: in a
// spreadsheet, or by a script. All columns, money in minor units, dates as stored.

import 'package:sqlite3/sqlite3.dart';

/// The tables a data file carries as CSV, in a sensible reading order.
const exportedTables = [
  'accounts',
  'categories',
  'category_accounts',
  'entries',
  'postings',
  'repeats',
  'goals',
  'goal_moves',
  'budgets',
];

/// One field, quoted when it holds a comma, a quote or a line break (RFC 4180).
String csvField(Object? value) {
  if (value == null) return '';
  final s = value is bool ? (value ? '1' : '0') : value.toString();
  return s.contains(RegExp(r'[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

String toCsv(List<String> columns, Iterable<List<Object?>> rows) {
  final out = StringBuffer()
    ..write(columns.map(csvField).join(','))
    ..write('\r\n');
  for (final r in rows) {
    out
      ..write(r.map(csvField).join(','))
      ..write('\r\n');
  }
  return out.toString();
}

/// Each exported table of [db] as CSV text, by file name such as "entries.csv".
Map<String, String> tableCsvs(Database db) => {
  for (final t in exportedTables)
    '$t.csv': () {
      final rs = db.select('SELECT * FROM "$t" ORDER BY rowid');
      return toCsv(rs.columnNames, rs.rows);
    }(),
};
