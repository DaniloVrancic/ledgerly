// Reads CSV the way RFC 4180 describes it, plus what bank exports do in practice: a
// semicolon or tab instead of a comma, any line ending, and a byte order mark.

const delimiters = [',', ';', '\t'];

/// Rows of fields. Quoted fields keep their spaces and may hold the delimiter, newlines and
/// doubled quotes. Unquoted fields are trimmed. Empty lines are skipped.
List<List<String>> readCsv(String text, {String? delimiter}) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final sep = delimiter ?? detectDelimiter(text);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var wasQuoted = false;

  void endField() {
    row.add(wasQuoted ? field.toString() : field.toString().trim());
    field.clear();
    wasQuoted = false;
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"' && field.toString().trim().isEmpty) {
      field.clear();
      quoted = true;
      wasQuoted = true;
    } else if (ch == sep) {
      endField();
    } else if (ch == '\r' || ch == '\n') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else if (!wasQuoted) {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty || wasQuoted) endRow();
  return rows;
}

/// The delimiter that splits the first lines into the same number of columns, more than one.
/// Comma when nothing fits better.
String detectDelimiter(String text) {
  final sample = text.split(RegExp(r'\r\n|\r|\n')).where((l) => l.trim().isNotEmpty).take(10).join('\n');
  var best = ',';
  var bestScore = -1.0;
  for (final d in delimiters) {
    final rows = readCsv(sample, delimiter: d);
    if (rows.isEmpty) continue;
    final counts = <int, int>{};
    for (final r in rows) {
      counts[r.length] = (counts[r.length] ?? 0) + 1;
    }
    final common = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    if (common.key < 2) continue;
    final score = common.value / rows.length + common.key / 1000;
    if (score > bestScore) {
      bestScore = score;
      best = d;
    }
  }
  return best;
}
