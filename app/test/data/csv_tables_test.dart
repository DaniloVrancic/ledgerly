import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/export/csv_tables.dart';
import 'package:ledgerly/domain/statement/csv_reader.dart';

void main() {
  test('fields are quoted only when they need it', () {
    expect(csvField(null), '');
    expect(csvField(1250), '1250');
    expect(csvField(true), '1');
    expect(csvField('Konzum'), 'Konzum');
    expect(csvField('Bread, milk'), '"Bread, milk"');
    expect(csvField('say "hi"'), '"say ""hi"""');
    expect(csvField('two\nlines'), '"two\nlines"');
  });

  test('a table written as CSV reads back the same', () {
    final text = toCsv(
      ['id', 'title', 'amount_minor'],
      [
        ['a', 'Ćevapi, extra', -1250],
        ['b', null, 400],
      ],
    );
    expect(readCsv(text), [
      ['id', 'title', 'amount_minor'],
      ['a', 'Ćevapi, extra', '-1250'],
      ['b', '', '400'],
    ]);
  });
}
