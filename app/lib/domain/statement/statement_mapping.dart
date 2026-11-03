// Which columns of a bank statement hold the date, the amount and the description, and how
// to read them. The guess fills the mapping screen; the person can change any of it.

import '../../core/day.dart';
import '../../core/text.dart';

const dateFormats = ['yyyy-MM-dd', 'dd.MM.yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy'];

class StatementMapping {
  const StatementMapping({
    required this.dateCol,
    required this.descriptionCol,
    this.amountCol,
    this.debitCol,
    this.creditCol,
    this.dateFormat = 'dd.MM.yyyy',
    this.decimalComma = true,
    this.hasHeader = true,
  });

  final int dateCol;
  final int descriptionCol;

  /// One signed amount column, or a debit column (money out) and a credit column (money in).
  final int? amountCol;
  final int? debitCol;
  final int? creditCol;
  final String dateFormat;

  /// "1.234,56" rather than "1,234.56".
  final bool decimalComma;
  final bool hasHeader;

  bool get usesDebitCredit => amountCol == null;

  StatementMapping copyWith({
    int? dateCol,
    int? descriptionCol,
    int? amountCol,
    int? debitCol,
    int? creditCol,
    bool clearAmount = false,
    bool clearDebitCredit = false,
    String? dateFormat,
    bool? decimalComma,
    bool? hasHeader,
  }) => StatementMapping(
    dateCol: dateCol ?? this.dateCol,
    descriptionCol: descriptionCol ?? this.descriptionCol,
    amountCol: clearAmount ? null : amountCol ?? this.amountCol,
    debitCol: clearDebitCredit ? null : debitCol ?? this.debitCol,
    creditCol: clearDebitCredit ? null : creditCol ?? this.creditCol,
    dateFormat: dateFormat ?? this.dateFormat,
    decimalComma: decimalComma ?? this.decimalComma,
    hasHeader: hasHeader ?? this.hasHeader,
  );
}

/// One statement line, read with a mapping.
class StatementRow {
  const StatementRow({required this.line, this.day, this.amountMinor = 0, this.description = '', this.error});

  /// 1-based line in the file, for messages.
  final int line;
  final String? day;

  /// Negative is money out.
  final int amountMinor;
  final String description;

  /// Why the row could not be read, such as "No date".
  final String? error;

  bool get ok => error == null;
}

/// "-1.234,56", "1,234.56", "(12.00)", "12,00-" or "€ 12" in minor units. Null when it is not
/// an amount.
int? parseStatementAmount(String text, {required bool decimalComma}) {
  var s = text.replaceAll(RegExp(r'[\s ]'), '');
  var negative = false;
  if (s.startsWith('(') && s.endsWith(')')) {
    negative = true;
    s = s.substring(1, s.length - 1);
  }
  if (s.endsWith('-')) {
    negative = true;
    s = s.substring(0, s.length - 1);
  }
  s = s.replaceAll(RegExp(r'[A-Za-z€$£]'), '');
  if (s.startsWith('+')) s = s.substring(1);
  if (s.startsWith('-') || s.startsWith('−')) {
    negative = !negative;
    s = s.substring(1);
  }
  s = decimalComma ? s.replaceAll('.', '').replaceAll(',', '.') : s.replaceAll(',', '');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  final minor = int.parse(parts[0]) * 100 + (parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return negative ? -minor : minor;
}

/// The day as "YYYY-MM-DD", or null when [text] is not a valid date in [format]. A time after
/// the date is ignored.
String? parseStatementDate(String text, String format) {
  final s = text.trim().split(RegExp(r'[ T]')).first;
  final m = switch (format) {
    'yyyy-MM-dd' => RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s),
    'dd.MM.yyyy' => RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})\.?$').firstMatch(s),
    _ => RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s),
  };
  if (m == null) return null;
  final (y, mo, d) = switch (format) {
    'yyyy-MM-dd' => (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)),
    'MM/dd/yyyy' => (int.parse(m[3]!), int.parse(m[1]!), int.parse(m[2]!)),
    _ => (int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!)),
  };
  if (mo < 1 || mo > 12 || d < 1 || d > Day.daysInMonth(y, mo)) return null;
  return Day.ymd(y, mo, d);
}

const _dateWords = ['datum', 'date', 'booking', 'knjizenja', 'transaction date'];
const _amountWords = ['iznos', 'amount', 'betrag', 'suma'];
const _descriptionWords = [
  'opis',
  'description',
  'svrha',
  'purpose',
  'details',
  'naziv',
  'primalac',
  'payee',
  'merchant',
  'narrative',
];
const _debitWords = ['duguje', 'debit', 'isplata', 'zaduzenje', 'rashod', 'withdrawal', 'out'];
const _creditWords = ['potrazuje', 'credit', 'uplata', 'odobrenje', 'prihod', 'deposit', 'in'];

int? _columnFor(List<String> header, List<String> words, {Set<int> skip = const {}}) {
  for (final w in words) {
    for (var i = 0; i < header.length; i++) {
      if (skip.contains(i)) continue;
      final h = fold(header[i]);
      if (w.length <= 3 ? h == w || h.split(RegExp(r'\W+')).contains(w) : h.contains(w)) return i;
    }
  }
  return null;
}

/// A first guess at the mapping: header names in English and local languages, otherwise the
/// shape of the values. Dates default to day first, as banks here write them.
StatementMapping guessMapping(List<List<String>> rows) {
  if (rows.isEmpty) return const StatementMapping(dateCol: 0, descriptionCol: 1, amountCol: 2);
  final width = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
  String? formatOf(String v) => dateFormats.where((f) => parseStatementDate(v, f) != null).firstOrNull;
  final hasHeader = !rows.first.any((v) => formatOf(v) != null) && rows.length > 1;
  final data = hasHeader ? rows.skip(1).take(50).toList() : rows.take(50).toList();
  List<String> column(int i) => [for (final r in data) i < r.length ? r[i] : ''];

  int? byShape(bool Function(String) test, {Set<int> skip = const {}}) {
    int? best;
    var bestCount = 0;
    for (var i = 0; i < width; i++) {
      if (skip.contains(i)) continue;
      final n = column(i).where(test).length;
      if (n > bestCount) {
        best = i;
        bestCount = n;
      }
    }
    return bestCount * 2 >= data.length ? best : null;
  }

  final header = hasHeader ? rows.first : const <String>[];
  final dateCol = _columnFor(header, _dateWords) ?? byShape((v) => formatOf(v) != null) ?? 0;

  final samples = column(dateCol).where((v) => v.isNotEmpty).toList();
  var dateFormat = dateFormats.firstWhere(
    (f) => samples.isNotEmpty && samples.every((v) => parseStatementDate(v, f) != null),
    orElse: () => 'dd.MM.yyyy',
  );
  if (dateFormat == 'dd/MM/yyyy' || dateFormat == 'MM/dd/yyyy') {
    final firstAbove12 = samples.any(
      (v) => int.tryParse(v.split('/').first) != null && int.parse(v.split('/').first) > 12,
    );
    final secondAbove12 = samples.any(
      (v) => v.split('/').length > 1 && (int.tryParse(v.split('/')[1]) ?? 0) > 12,
    );
    dateFormat = secondAbove12 && !firstAbove12 ? 'MM/dd/yyyy' : 'dd/MM/yyyy';
  }

  final amountish = [for (var i = 0; i < width; i++) column(i).join(' ')].join(' ');
  final decimalComma =
      RegExp(r'\d,\d{2}(?!\d)').allMatches(amountish).length >=
      RegExp(r'\d\.\d{2}(?!\d)').allMatches(amountish).length;

  final debitCol = _columnFor(header, _debitWords, skip: {dateCol});
  final creditCol = _columnFor(header, _creditWords, skip: {dateCol, ?debitCol});
  int? amountCol = _columnFor(header, _amountWords, skip: {dateCol});
  if (amountCol == null && (debitCol == null || creditCol == null)) {
    amountCol = byShape(
      (v) => formatOf(v) == null && parseStatementAmount(v, decimalComma: decimalComma) != null,
      skip: {dateCol},
    );
  }
  final used = {dateCol, ?amountCol, if (amountCol == null) ?debitCol, if (amountCol == null) ?creditCol};
  var descriptionCol = _columnFor(header, _descriptionWords, skip: used);
  if (descriptionCol == null) {
    var longest = -1.0;
    for (var i = 0; i < width; i++) {
      if (used.contains(i)) continue;
      final values = column(i);
      final textual = values.where((v) => parseStatementAmount(v, decimalComma: decimalComma) == null).length;
      final length = values.fold(0, (s, v) => s + v.length) / (values.isEmpty ? 1 : values.length);
      if (textual * 2 >= values.length && length > longest) {
        longest = length;
        descriptionCol = i;
      }
    }
  }
  return StatementMapping(
    dateCol: dateCol,
    descriptionCol: descriptionCol ?? (dateCol == 0 ? 1 : 0),
    amountCol: amountCol,
    debitCol: amountCol == null ? debitCol : null,
    creditCol: amountCol == null ? creditCol : null,
    dateFormat: dateFormat,
    decimalComma: decimalComma,
    hasHeader: hasHeader,
  );
}

/// Every data row read with [m]. Rows that cannot be read are kept with the reason.
List<StatementRow> applyMapping(List<List<String>> rows, StatementMapping m) {
  final out = <StatementRow>[];
  for (var i = m.hasHeader ? 1 : 0; i < rows.length; i++) {
    final r = rows[i];
    String at(int? c) => c != null && c < r.length ? r[c] : '';
    final day = parseStatementDate(at(m.dateCol), m.dateFormat);
    int? amount;
    if (m.usesDebitCredit) {
      final debit = at(m.debitCol).isEmpty
          ? 0
          : parseStatementAmount(at(m.debitCol), decimalComma: m.decimalComma);
      final credit = at(m.creditCol).isEmpty
          ? 0
          : parseStatementAmount(at(m.creditCol), decimalComma: m.decimalComma);
      amount = debit == null || credit == null ? null : credit.abs() - debit.abs();
    } else {
      amount = parseStatementAmount(at(m.amountCol), decimalComma: m.decimalComma);
    }
    final description = at(m.descriptionCol).replaceAll(RegExp(r'\s+'), ' ').trim();
    final error = day == null
        ? 'No date'
        : amount == null
        ? 'No amount'
        : amount == 0
        ? 'Amount is zero'
        : null;
    out.add(
      StatementRow(line: i + 1, day: day, amountMinor: amount ?? 0, description: description, error: error),
    );
  }
  return out;
}
