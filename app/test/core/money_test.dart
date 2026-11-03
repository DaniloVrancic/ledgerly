import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money.dart';

void main() {
  group('formatMoney', () {
    test('writes euros and marks with the system format', () {
      expect(formatMoney(123456, 'EUR'), '€1,234.56');
      expect(formatMoney(123456, 'BAM'), '1,234.56 KM');
    });

    test('uses a real minus and an optional plus', () {
      expect(formatMoney(-2000, 'EUR'), '−€20.00');
      expect(formatMoney(2000, 'EUR', sign: true), '+€20.00');
      expect(formatMoney(0, 'EUR', sign: true), '€0.00');
    });
  });

  group('conversion', () {
    test('BAM is pegged at 1.95583', () {
      expect(toBase(195583, 'BAM'), 100000);
      expect(fromBase(100000, 'BAM'), 195583);
      expect(toBase(1200, 'BAM'), 614);
    });

    test('EUR is the reporting currency', () {
      expect(toBase(1234, 'EUR'), 1234);
      expect(convert(1000, 'EUR', 'EUR'), 1000);
    });
  });

  group('typing an amount', () {
    test('12 means 12.00 and a comma is a decimal point', () {
      expect(parseAmount('12'), 1200);
      expect(parseAmount('12,5'), 1250);
      expect(parseAmount('0.07'), 7);
    });

    test('anything that is not an amount is zero', () {
      expect(parseAmount(''), 0);
      expect(parseAmount('.'), 0);
      expect(parseAmount('12.345'), 0);
      expect(parseAmount('abc'), 0);
    });

    test('the keypad allows one point and two decimals', () {
      var s = '';
      for (final k in ['1', '2', '.', '5', '.', '0', '9']) {
        s = pressKey(s, k);
      }
      expect(s, '12.50');
      expect(pressKey('12.50', 'del'), '12.5');
      expect(pressKey('', '.'), '0.');
      expect(pressKey('0', '7'), '7');
    });
  });
}
