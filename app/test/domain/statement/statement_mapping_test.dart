import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/statement/csv_reader.dart';
import 'package:ledgerly/domain/statement/statement_mapping.dart';

void main() {
  test('amounts in either decimal style, with signs, brackets and currency', () {
    expect(parseStatementAmount('-1.234,56', decimalComma: true), -123456);
    expect(parseStatementAmount('12,00-', decimalComma: true), -1200);
    expect(parseStatementAmount('1,234.56', decimalComma: false), 123456);
    expect(parseStatementAmount('(12.00)', decimalComma: false), -1200);
    expect(parseStatementAmount('€ 12', decimalComma: true), 1200);
    expect(parseStatementAmount('45,5 KM', decimalComma: true), 4550);
    expect(parseStatementAmount('abc', decimalComma: true), isNull);
    expect(
      parseStatementAmount('12.345', decimalComma: false),
      isNull,
      reason: 'three decimals is not money',
    );
  });

  test('dates in each format, with invalid days refused', () {
    expect(parseStatementDate('01.10.2026', 'dd.MM.yyyy'), '2026-10-01');
    expect(parseStatementDate('1.10.2026.', 'dd.MM.yyyy'), '2026-10-01');
    expect(parseStatementDate('2026-10-01 14:22', 'yyyy-MM-dd'), '2026-10-01');
    expect(parseStatementDate('10/31/2026', 'MM/dd/yyyy'), '2026-10-31');
    expect(parseStatementDate('31/10/2026', 'dd/MM/yyyy'), '2026-10-31');
    expect(parseStatementDate('31.02.2026', 'dd.MM.yyyy'), isNull);
  });

  test('a Bosnian export with a signed amount column and a decimal comma', () {
    final rows = readCsv(
      'Datum knjiženja;Opis plaćanja;Iznos;Stanje\n'
      '01.10.2026;KONZUM 123 SARAJEVO;-45,20;1.954,80\n'
      '03.10.2026;Plata oktobar;2.000,00;3.954,80\n'
      'x;broken;;0\n',
    );
    final m = guessMapping(rows);
    expect(m.hasHeader, isTrue);
    expect(m.dateCol, 0);
    expect(m.descriptionCol, 1);
    expect(m.amountCol, 2);
    expect(m.dateFormat, 'dd.MM.yyyy');
    expect(m.decimalComma, isTrue);

    final read = applyMapping(rows, m);
    expect(read[0].day, '2026-10-01');
    expect(read[0].amountMinor, -4520);
    expect(read[0].description, 'KONZUM 123 SARAJEVO');
    expect(read[1].amountMinor, 200000);
    expect(read[2].ok, isFalse);
    expect(read[2].error, 'No date');
    expect(read[2].line, 4);
  });

  test('an English export with debit and credit columns', () {
    final rows = readCsv(
      'Date,Description,Debit,Credit\n'
      '10/31/2026,Coffee shop,3.50,\n'
      '10/30/2026,Refund,,12.00\n',
    );
    final m = guessMapping(rows);
    expect(m.usesDebitCredit, isTrue);
    expect(m.debitCol, 2);
    expect(m.creditCol, 3);
    expect(m.dateFormat, 'MM/dd/yyyy', reason: '31 can only be a day');
    expect(m.decimalComma, isFalse);
    final read = applyMapping(rows, m);
    expect(read.map((r) => r.amountMinor), [-350, 1200]);
    expect(read.map((r) => r.day), ['2026-10-31', '2026-10-30']);
  });

  test('without a header the columns are found by their values', () {
    final rows = readCsv('2026-10-01,Groceries at Bingo,-12.50\n2026-10-02,Bus,-1.60\n');
    final m = guessMapping(rows);
    expect(m.hasHeader, isFalse);
    expect(m.dateCol, 0);
    expect(m.amountCol, 2);
    expect(m.descriptionCol, 1);
    expect(applyMapping(rows, m).first.amountMinor, -1250);
  });
}
