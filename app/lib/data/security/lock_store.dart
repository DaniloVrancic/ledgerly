// The app lock's settings live in their own small file next to the database, never in it,
// so restoring a backup or importing a data file can never add or remove a lock.

import 'dart:convert';
import 'dart:io';

import 'pin_hasher.dart';

class LockSettings {
  const LockSettings({
    this.enabled = false,
    this.pin,
    this.delaySeconds = 300,
    this.biometrics = false,
    this.failedCount = 0,
    this.waitUntil,
  });

  final bool enabled;
  final PinHash? pin;

  /// How long the app may be in the background before it locks. 0 locks at once.
  final int delaySeconds;

  /// Unlock with the fingerprint or face unlock as well as the PIN.
  final bool biometrics;

  /// Wrong PINs in a row, kept across restarts so waiting cannot be skipped.
  final int failedCount;
  final DateTime? waitUntil;

  LockSettings copyWith({
    bool? enabled,
    PinHash? pin,
    bool clearPin = false,
    int? delaySeconds,
    bool? biometrics,
    int? failedCount,
    DateTime? waitUntil,
    bool clearWait = false,
  }) => LockSettings(
    enabled: enabled ?? this.enabled,
    pin: clearPin ? null : pin ?? this.pin,
    delaySeconds: delaySeconds ?? this.delaySeconds,
    biometrics: biometrics ?? this.biometrics,
    failedCount: failedCount ?? this.failedCount,
    waitUntil: clearWait ? null : waitUntil ?? this.waitUntil,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'pin': pin?.toJson(),
    'delaySeconds': delaySeconds,
    'biometrics': biometrics,
    'failedCount': failedCount,
    'waitUntil': waitUntil?.toUtc().toIso8601String(),
  };

  static LockSettings fromJson(Map<String, dynamic> json) {
    final pin = PinHash.fromJson(json['pin']);
    return LockSettings(
      // A lock without a PIN could never be opened, so it counts as off.
      enabled: json['enabled'] == true && pin != null,
      pin: pin,
      delaySeconds: json['delaySeconds'] is int ? json['delaySeconds'] as int : 300,
      biometrics: json['biometrics'] == true,
      failedCount: json['failedCount'] is int ? json['failedCount'] as int : 0,
      waitUntil: DateTime.tryParse(json['waitUntil'] as String? ?? '')?.toLocal(),
    );
  }
}

abstract interface class LockStore {
  Future<LockSettings> read();
  Future<void> write(LockSettings settings);
}

/// In memory only, for tests and until main.dart sets up the file.
class MemoryLockStore implements LockStore {
  LockSettings _settings = const LockSettings();

  @override
  Future<LockSettings> read() async => _settings;

  @override
  Future<void> write(LockSettings settings) async => _settings = settings;
}

/// A JSON file, written to a temporary file first and then renamed, so it is never half written.
class FileLockStore implements LockStore {
  FileLockStore(this.file);

  final File file;

  @override
  Future<LockSettings> read() async {
    try {
      if (!file.existsSync()) return const LockSettings();
      return LockSettings.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
    } on Object {
      // An unreadable file must not lock the person out: the lock is off.
      return const LockSettings();
    }
  }

  @override
  Future<void> write(LockSettings settings) async {
    file.parent.createSync(recursive: true);
    final temp = File('${file.path}.tmp')..writeAsStringSync(jsonEncode(settings.toJson()), flush: true);
    temp.renameSync(file.path);
  }
}
