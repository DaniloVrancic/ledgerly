// The app lock PIN is never stored, only a salted PBKDF2-HMAC-SHA256 hash of it. The count
// of rounds is stored with the hash, so it can be raised later without breaking old PINs.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class PinHash {
  const PinHash({required this.salt, required this.hash, required this.iterations});

  /// Base64.
  final String salt;
  final String hash;
  final int iterations;

  Map<String, Object> toJson() => {'salt': salt, 'hash': hash, 'iterations': iterations};

  static PinHash? fromJson(Object? json) {
    if (json is! Map) return null;
    final salt = json['salt'], hash = json['hash'], iterations = json['iterations'];
    if (salt is! String || hash is! String || iterations is! int) return null;
    return PinHash(salt: salt, hash: hash, iterations: iterations);
  }
}

class PinHasher {
  /// [inBackground] runs the rounds on an isolate, as they take about a second on a phone.
  const PinHasher({this.iterations = 210000, this.inBackground = true});

  final int iterations;
  final bool inBackground;

  Future<PinHash> hash(String pin) async {
    final rng = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => rng.nextInt(256)));
    final rounds = iterations;
    final key = await _run(() => pbkdf2(pin, salt, rounds));
    return PinHash(salt: base64.encode(salt), hash: base64.encode(key), iterations: rounds);
  }

  Future<bool> verify(String pin, PinHash stored) async {
    final salt = base64.decode(stored.salt);
    final rounds = stored.iterations;
    final key = await _run(() => pbkdf2(pin, salt, rounds));
    return _same(key, base64.decode(stored.hash));
  }

  Future<Uint8List> _run(Uint8List Function() work) async => inBackground ? Isolate.run(work) : work();
}

Uint8List pbkdf2(String pin, Uint8List salt, int iterations) {
  final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))..init(Pbkdf2Parameters(salt, iterations, 32));
  return kdf.process(Uint8List.fromList(utf8.encode(pin)));
}

/// Compares in constant time.
bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
