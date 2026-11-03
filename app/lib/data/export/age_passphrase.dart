// Password protection for data files, in the open age format (age-encryption.org/v1), so a
// protected .ledgerly file can also be opened with the standard `age -d` tool.
//
// Only the passphrase (scrypt) recipient is implemented. Following the age v1 spec:
//   header   "age-encryption.org/v1", one "-> scrypt <salt> <log2 N>" stanza whose body is the
//            16-byte file key sealed with ChaCha20-Poly1305 under
//            scrypt(passphrase, "age-encryption.org/v1/scrypt" + salt, N, r = 8, p = 1),
//            then "--- " and HMAC-SHA256 of the header, keyed with HKDF(file key, "header").
//   payload  a 16-byte nonce, then 64 KiB chunks sealed with ChaCha20-Poly1305 under
//            HKDF(file key, salt = nonce, "payload"). Each chunk's nonce is an 11-byte counter
//            and a last-chunk flag.
// Base64 is the standard alphabet without padding, wrapped at 64 columns.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

enum AgeProblem { wrongPassphrase, malformed, workFactorTooHigh }

class AgeException implements Exception {
  const AgeException(this.problem);

  final AgeProblem problem;

  @override
  String toString() => switch (problem) {
    AgeProblem.wrongPassphrase => 'That password does not open this file.',
    AgeProblem.malformed => 'This protected file is damaged.',
    AgeProblem.workFactorTooHigh => 'This file asks for more work than Ledgerly allows to open it.',
  };
}

const _intro = 'age-encryption.org/v1';
const _scryptLabel = 'age-encryption.org/v1/scrypt';
const _chunk = 64 * 1024;
const _tag = 16;

/// The highest scrypt work factor Ledgerly opens. Each step doubles the time and memory.
const maxLogN = 20;

/// Encrypts [plain] with [passphrase]. [logN] 16 takes a few seconds and 64 MB on a phone.
Uint8List ageEncrypt(Uint8List plain, String passphrase, {int logN = 16, Random? random}) {
  final rng = random ?? Random.secure();
  Uint8List bytes(int n) => Uint8List.fromList(List.generate(n, (_) => rng.nextInt(256)));

  final fileKey = bytes(16);
  final salt = bytes(16);
  final wrapKey = _scrypt(passphrase, salt, logN);
  final body = _seal(wrapKey, Uint8List(12), fileKey);

  final header = StringBuffer()
    ..write('$_intro\n')
    ..write('-> scrypt ${_b64(salt)} $logN\n')
    ..write('${_wrap(_b64(body))}\n')
    ..write('---');
  final mac = _hmac(_hkdf(fileKey, Uint8List(0), 'header'), utf8.encode(header.toString()));
  header.write(' ${_b64(mac)}\n');

  final nonce = bytes(16);
  final out = BytesBuilder(copy: false)
    ..add(utf8.encode(header.toString()))
    ..add(nonce)
    ..add(_streamSeal(_hkdf(fileKey, nonce, 'payload'), plain));
  return out.takeBytes();
}

/// Decrypts an age file protected with a passphrase.
Uint8List ageDecrypt(Uint8List file, String passphrase) {
  final (lines, payloadStart) = _headerLines(file);
  if (lines.length < 4 || lines.first != _intro) throw const AgeException(AgeProblem.malformed);

  final stanza = lines[1].split(' ');
  if (stanza.length != 4 || stanza[0] != '->' || stanza[1] != 'scrypt' || !lines.last.startsWith('--- ')) {
    throw const AgeException(AgeProblem.malformed);
  }
  // A passphrase file has exactly one stanza: its body lines, then the footer.
  final bodyLines = lines.sublist(2, lines.length - 1);
  if (bodyLines.any((l) => l.startsWith('->'))) throw const AgeException(AgeProblem.malformed);
  final logN = int.tryParse(stanza[3]);
  if (logN == null || logN < 1 || stanza[3] != '$logN') throw const AgeException(AgeProblem.malformed);
  if (logN > maxLogN) throw const AgeException(AgeProblem.workFactorTooHigh);

  final salt = _unb64(stanza[2]);
  final body = _unb64(bodyLines.join());
  if (salt.length != 16 || body.length != 16 + _tag) throw const AgeException(AgeProblem.malformed);

  final Uint8List fileKey;
  try {
    fileKey = _open(_scrypt(passphrase, salt, logN), Uint8List(12), body);
  } on InvalidCipherTextException {
    throw const AgeException(AgeProblem.wrongPassphrase);
  }

  final headerText = '${lines.sublist(0, lines.length - 1).join('\n')}\n---';
  final expected = _hmac(_hkdf(fileKey, Uint8List(0), 'header'), utf8.encode(headerText));
  if (!_same(expected, _unb64(lines.last.substring(4)))) throw const AgeException(AgeProblem.malformed);

  if (file.length < payloadStart + 16) throw const AgeException(AgeProblem.malformed);
  final nonce = Uint8List.sublistView(file, payloadStart, payloadStart + 16);
  try {
    return _streamOpen(_hkdf(fileKey, nonce, 'payload'), Uint8List.sublistView(file, payloadStart + 16));
  } on InvalidCipherTextException {
    throw const AgeException(AgeProblem.malformed);
  }
}

/// [ageEncrypt] on a background isolate, so the screen keeps moving during scrypt.
Future<Uint8List> ageEncryptInBackground(Uint8List plain, String passphrase, {int logN = 16}) =>
    Isolate.run(() => ageEncrypt(plain, passphrase, logN: logN));

/// [ageDecrypt] on a background isolate.
Future<Uint8List> ageDecryptInBackground(Uint8List file, String passphrase) =>
    Isolate.run(() => ageDecrypt(file, passphrase));

// ---- The parts ----

/// The header's lines and where the binary payload starts.
(List<String>, int) _headerLines(Uint8List file) {
  final lines = <String>[];
  var start = 0;
  for (var i = 0; i < file.length && i < 16 * 1024; i++) {
    if (file[i] != 0x0A) continue;
    final String line;
    try {
      line = ascii.decode(Uint8List.sublistView(file, start, i));
    } on FormatException {
      throw const AgeException(AgeProblem.malformed);
    }
    lines.add(line);
    start = i + 1;
    if (line.startsWith('---')) return (lines, start);
  }
  throw const AgeException(AgeProblem.malformed);
}

Uint8List _scrypt(String passphrase, Uint8List salt, int logN) {
  final s = Scrypt()
    ..init(
      ScryptParameters(1 << logN, 8, 1, 32, Uint8List.fromList([...utf8.encode(_scryptLabel), ...salt])),
    );
  return s.process(Uint8List.fromList(utf8.encode(passphrase)));
}

Uint8List _hkdf(Uint8List key, Uint8List salt, String info) {
  final h = HKDFKeyDerivator(SHA256Digest())
    ..init(HkdfParameters(key, 32, salt, Uint8List.fromList(utf8.encode(info))));
  final out = Uint8List(32);
  h.deriveKey(null, 0, out, 0);
  return out;
}

Uint8List _hmac(Uint8List key, List<int> data) {
  final m = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
  return m.process(Uint8List.fromList(data));
}

Uint8List _seal(Uint8List key, Uint8List nonce, Uint8List plain) => _aead(true, key, nonce, plain);

/// Throws InvalidCipherTextException when the tag does not match.
Uint8List _open(Uint8List key, Uint8List nonce, Uint8List sealed) {
  if (sealed.length < _tag) throw InvalidCipherTextException('Too short');
  return _aead(false, key, nonce, sealed);
}

// pointycastle's AEAD process() skips doFinal, which writes and checks the tag, so the
// steps are done here one by one.
Uint8List _aead(bool encrypt, Uint8List key, Uint8List nonce, Uint8List input) {
  final c = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305())
    ..init(encrypt, AEADParameters(KeyParameter(key), _tag * 8, nonce, Uint8List(0)));
  final out = Uint8List(c.getOutputSize(input.length));
  var length = c.processBytes(input, 0, input.length, out, 0);
  try {
    length += c.doFinal(out, length);
  } on ArgumentError {
    // How pointycastle reports a tag that does not match.
    throw InvalidCipherTextException('The tag does not match.');
  }
  return Uint8List.sublistView(out, 0, length);
}

Uint8List _chunkNonce(int counter, bool last) {
  final n = Uint8List(12);
  var c = counter;
  for (var i = 10; i >= 0 && c > 0; i--) {
    n[i] = c & 0xFF;
    c >>= 8;
  }
  n[11] = last ? 1 : 0;
  return n;
}

Uint8List _streamSeal(Uint8List key, Uint8List plain) {
  final out = BytesBuilder(copy: false);
  var counter = 0;
  var offset = 0;
  do {
    final end = min(offset + _chunk, plain.length);
    final last = end == plain.length;
    out.add(_seal(key, _chunkNonce(counter, last), Uint8List.sublistView(plain, offset, end)));
    counter += 1;
    offset = end;
  } while (offset < plain.length);
  return out.takeBytes();
}

Uint8List _streamOpen(Uint8List key, Uint8List sealed) {
  if (sealed.isEmpty) throw const AgeException(AgeProblem.malformed);
  final out = BytesBuilder(copy: false);
  var counter = 0;
  var offset = 0;
  while (offset < sealed.length) {
    final end = min(offset + _chunk + _tag, sealed.length);
    final last = end == sealed.length;
    final plain = _open(key, _chunkNonce(counter, last), Uint8List.sublistView(sealed, offset, end));
    // Only an empty file may end with an empty chunk.
    if (last && plain.isEmpty && counter > 0) throw const AgeException(AgeProblem.malformed);
    out.add(plain);
    counter += 1;
    offset = end;
  }
  return out.takeBytes();
}

String _b64(List<int> bytes) => base64.encode(bytes).replaceAll('=', '');

Uint8List _unb64(String text) {
  if (text.contains('=') || !RegExp(r'^[A-Za-z0-9+/]*$').hasMatch(text)) {
    throw const AgeException(AgeProblem.malformed);
  }
  try {
    return base64.decode(text.padRight((text.length + 3) ~/ 4 * 4, '='));
  } on FormatException {
    throw const AgeException(AgeProblem.malformed);
  }
}

/// Base64 lines of 64 columns, as the spec wraps stanza bodies. The last line is shorter,
/// and is empty when the text fills whole lines.
String _wrap(String text) {
  final lines = [for (var i = 0; i < text.length; i += 64) text.substring(i, min(i + 64, text.length))];
  if (text.length % 64 == 0) lines.add('');
  return lines.join('\n');
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
