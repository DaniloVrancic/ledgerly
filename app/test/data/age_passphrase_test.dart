import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/export/age_passphrase.dart';

Uint8List data(int length) => Uint8List.fromList([for (var i = 0; i < length; i++) (i * 31 + 7) & 255]);

Matcher problem(AgeProblem p) => throwsA(isA<AgeException>().having((e) => e.problem, 'problem', p));

void main() {
  test('round trips at the chunk edges', () {
    for (final size in [0, 1, 65536, 65537, 2 * 65536 + 7]) {
      final sealed = ageEncrypt(data(size), 'correct horse', logN: 10);
      expect(ageDecrypt(sealed, 'correct horse'), data(size), reason: '$size bytes');
    }
  });

  test('the header is plain age v1 with one scrypt stanza', () {
    final sealed = ageEncrypt(data(10), 'pw', logN: 12);
    final text = latin1.decode(sealed.sublist(0, sealed.length < 200 ? sealed.length : 200));
    final lines = text.split('\n');
    expect(lines[0], 'age-encryption.org/v1');
    expect(lines[1], matches(RegExp(r'^-> scrypt [A-Za-z0-9+/]{22} 12$')));
    expect(lines[2], matches(RegExp(r'^[A-Za-z0-9+/]{43}$')));
    expect(lines[3], matches(RegExp(r'^--- [A-Za-z0-9+/]{43}')));
  });

  test('files made by an independent age implementation open', () {
    final hello = File('test/fixtures/age/hello-scrypt-node.age').readAsBytesSync();
    expect(utf8.decode(ageDecrypt(hello, 'ledgerly-test')), 'hello ledgerly\n');
    final big = File('test/fixtures/age/two-chunks-node.age').readAsBytesSync();
    expect(ageDecrypt(big, 'ledgerly-test'), data(2 * 65536 + 7));
  });

  test('a wrong passphrase is told apart from a damaged file', () {
    final sealed = ageEncrypt(data(100), 'right', logN: 10);
    expect(() => ageDecrypt(sealed, 'wrong'), problem(AgeProblem.wrongPassphrase));

    final cut = Uint8List.sublistView(sealed, 0, sealed.length - 1);
    expect(() => ageDecrypt(cut, 'right'), problem(AgeProblem.malformed));

    final flipped = Uint8List.fromList(sealed)..[sealed.length - 20] ^= 1;
    expect(() => ageDecrypt(flipped, 'right'), problem(AgeProblem.malformed));

    final header = Uint8List.fromList(sealed);
    final at = latin1.decode(header).indexOf(' 10\n');
    header[at + 2] = '1'.codeUnitAt(0); // "10" becomes "11": the MAC no longer matches.
    expect(() => ageDecrypt(header, 'right'), throwsA(isA<AgeException>()));

    expect(
      () => ageDecrypt(Uint8List.fromList(utf8.encode('not age at all')), 'x'),
      problem(AgeProblem.malformed),
    );
  });

  test('a file asking for too much work is refused before any work is done', () {
    final text =
        'age-encryption.org/v1\n-> scrypt AAAAAAAAAAAAAAAAAAAAAA 30\n'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n--- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n';
    final watch = Stopwatch()..start();
    expect(
      () => ageDecrypt(Uint8List.fromList(utf8.encode(text)), 'x'),
      problem(AgeProblem.workFactorTooHigh),
    );
    expect(watch.elapsedMilliseconds, lessThan(1000));
  });

  test('the default work factor works on a background isolate', () async {
    final sealed = await ageEncryptInBackground(data(1000), 'pw');
    expect(latin1.decode(sealed.sublist(0, 80)), contains(' 16\n'));
    expect(await ageDecryptInBackground(sealed, 'pw'), data(1000));
  });
}
