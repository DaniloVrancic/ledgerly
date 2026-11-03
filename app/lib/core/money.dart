// Money is always stored as integer minor units (cents), never as doubles.
// EUR is the reporting currency. BAM is pegged to it at a fixed rate.

import 'package:intl/intl.dart';

abstract final class Currencies {
  static const eur = 'EUR';
  static const bam = 'BAM';
  static const all = [eur, bam];

  /// The fixed rate: 1 EUR = 1.95583 BAM.
  static const bamPerEur = 1.95583;
}

/// The EUR value of an amount, frozen when an entry is recorded.
int toBase(int minor, String currency) {
  if (currency == Currencies.eur) return minor;
  if (currency == Currencies.bam) return (minor / Currencies.bamPerEur).round();
  throw ArgumentError('Unsupported currency $currency');
}

/// Converts a EUR amount into an account currency.
int fromBase(int eurMinor, String currency) {
  if (currency == Currencies.eur) return eurMinor;
  if (currency == Currencies.bam) return (eurMinor * Currencies.bamPerEur).round();
  throw ArgumentError('Unsupported currency $currency');
}

/// Converts between the two account currencies at the fixed rate.
int convert(int minor, String from, String to) =>
    from == to ? minor : fromBase(toBase(minor, from), to);

final _digits = NumberFormat('#,##0.00', 'en_US');
const _minus = '−';

/// €1,234.56 and 1,234.56 KM, with a real minus sign and an optional plus.
String formatMoney(int minor, String currency, {bool sign = false}) {
  final n = _digits.format(minor.abs() / 100);
  final body = currency == Currencies.bam ? '$n KM' : '€$n';
  if (minor < 0) return '$_minus$body';
  return sign && minor > 0 ? '+$body' : body;
}

/// "12" is 12.00 and "12,5" is 12.50. Anything that is not an amount is 0.
int parseAmount(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty || t == '.' || !RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(t)) return 0;
  return (double.parse(t) * 100).round();
}

/// One key press on the amount keypad: digits, one point, two decimals, nine digits at most.
String pressKey(String current, String key) {
  if (key == 'del') return current.isEmpty ? current : current.substring(0, current.length - 1);
  if (key == '.') return current.contains('.') ? current : '${current.isEmpty ? '0' : current}.';
  if (!RegExp(r'^\d$').hasMatch(key)) return current;
  if (RegExp(r'\.\d\d$').hasMatch(current) || current.replaceAll('.', '').length >= 9) return current;
  return current == '0' ? key : current + key;
}

/// Shows minor units as the text a person would type, such as 1250 as "12.50".
String amountText(int minor) => (minor / 100).toStringAsFixed(2);
