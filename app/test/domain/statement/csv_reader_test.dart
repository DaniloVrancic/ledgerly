import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/statement/cp1250.dart';
import 'package:ledgerly/domain/statement/csv_reader.dart';

void main() {
  test('quoted fields keep commas, doubled quotes and newlines', () {
    final rows = readCsv('a,"b, c","say ""hi""","two\nlines"\n1,2,3,4\n');
    expect(rows, [
      ['a', 'b, c', 'say "hi"', 'two\nlines'],
      ['1', '2', '3', '4'],
    ]);
  });

  test('semicolons and tabs are detected', () {
    expect(detectDelimiter('Datum;Opis;Iznos\n01.10.2026;Konzum;-12,50\n'), ';');
    expect(readCsv('a\tb\n1\t2'), [
      ['a', 'b'],
      ['1', '2'],
    ]);
    expect(detectDelimiter('date,description,amount\n2026-10-01,"Shop; Ltd",-1.00\n'), ',');
  });

  test('any line ending, a byte order mark, empty lines and a trailing newline', () {
    expect(readCsv('﻿a,b\r\n1,2\r3,4\n\n5,6\n'), [
      ['a', 'b'],
      ['1', '2'],
      ['3', '4'],
      ['5', '6'],
    ]);
  });

  test('spaces are trimmed outside quotes and kept inside, and empty fields stay', () {
    expect(readCsv(' a , " b ",,d'), [
      ['a', ' b ', '', 'd'],
    ]);
  });

  test('a ragged last line keeps the fields it has', () {
    expect(readCsv('a,b,c\n1,2'), [
      ['a', 'b', 'c'],
      ['1', '2'],
    ]);
  });

  test('Windows-1250 bytes become the right letters, and UTF-8 is preferred', () {
    // "Plaćanje Đ" in Windows-1250.
    expect(decodeCp1250([0x50, 0x6C, 0x61, 0xE6, 0x61, 0x6E, 0x6A, 0x65, 0x20, 0xD0]), 'Plaćanje Đ');
    expect(decodeStatement([0x9A, 0x9E, 0xE8]), 'šžč', reason: 'not valid UTF-8, so Windows-1250');
    expect(decodeStatement([0xEF, 0xBB, 0xBF, 0xC4, 0x8D]), 'č', reason: 'UTF-8 with a byte order mark');
  });
}
