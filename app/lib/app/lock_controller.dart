// The app lock: off by default. When on, Ledgerly is locked when it opens and after it has
// been in the background longer than the chosen delay. After 5 wrong PINs it waits 30 seconds,
// then twice as long after each further wrong PIN, up to 5 minutes.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/security/lock_store.dart';
import '../data/security/pin_hasher.dart';
import 'providers.dart';

/// The fingerprint or face unlock. Only phones have one; elsewhere it is not available.
abstract interface class Biometrics {
  Future<bool> available();

  /// Shows the system prompt. True when the person was recognised.
  Future<bool> authenticate();
}

class NoBiometrics implements Biometrics {
  const NoBiometrics();

  @override
  Future<bool> available() async => false;

  @override
  Future<bool> authenticate() async => false;
}

/// Set up in main.dart with the file next to the database.
final lockStoreProvider = Provider<LockStore>((ref) => MemoryLockStore());
final pinHasherProvider = Provider<PinHasher>((ref) => const PinHasher());
final biometricsProvider = Provider<Biometrics>((ref) => const NoBiometrics());

/// Hides the app in the recent-apps screen while the lock is on. Does nothing by default.
final secureWindowProvider = Provider<Future<void> Function(bool on)>((ref) => (_) async {});

const lockDelays = [Duration.zero, Duration(minutes: 1), Duration(minutes: 5), Duration(minutes: 15)];
const minPinLength = 4;
const maxPinLength = 8;

enum UnlockResult { unlocked, wrongPin, waiting }

class LockState {
  const LockState({
    this.loaded = false,
    this.enabled = false,
    this.locked = false,
    this.delay = const Duration(minutes: 5),
    this.biometrics = false,
    this.biometricsAvailable = false,
    this.waitUntil,
  });

  /// False until the settings are read. Until then the app stays covered.
  final bool loaded;
  final bool enabled;
  final bool locked;
  final Duration delay;
  final bool biometrics;
  final bool biometricsAvailable;

  /// After too many wrong PINs, no PIN is checked before this time.
  final DateTime? waitUntil;

  /// The app is hidden behind the lock screen.
  bool get covered => !loaded || locked;
}

class LockController extends Notifier<LockState> {
  LockSettings _settings = const LockSettings();
  DateTime? _pausedAt;

  LockStore get _store => ref.read(lockStoreProvider);
  PinHasher get _hasher => ref.read(pinHasherProvider);
  DateTime get _now => ref.read(clockProvider).now();

  @override
  LockState build() {
    unawaited(_load());
    return const LockState();
  }

  Future<void> _load() async {
    _settings = await _store.read();
    final available = await ref.read(biometricsProvider).available();
    _publish(locked: _settings.enabled, biometricsAvailable: available);
    await ref.read(secureWindowProvider)(_settings.enabled);
  }

  void _publish({bool? locked, bool? biometricsAvailable}) {
    final wait = _settings.waitUntil;
    state = LockState(
      loaded: true,
      enabled: _settings.enabled,
      locked: _settings.enabled && (locked ?? state.locked),
      delay: Duration(seconds: _settings.delaySeconds),
      biometrics: _settings.biometrics,
      biometricsAvailable: biometricsAvailable ?? state.biometricsAvailable,
      waitUntil: wait != null && wait.isAfter(_now) ? wait : null,
    );
  }

  Future<void> _save(LockSettings next, {bool? locked}) async {
    final wasEnabled = _settings.enabled;
    _settings = next;
    await _store.write(next);
    _publish(locked: locked);
    if (next.enabled != wasEnabled) await ref.read(secureWindowProvider)(next.enabled);
  }

  Future<UnlockResult> unlockWithPin(String pin) async {
    final wait = _settings.waitUntil;
    if (wait != null && wait.isAfter(_now)) return UnlockResult.waiting;
    final stored = _settings.pin;
    if (stored != null && await _hasher.verify(pin, stored)) {
      await _save(_settings.copyWith(failedCount: 0, clearWait: true), locked: false);
      return UnlockResult.unlocked;
    }
    final failed = _settings.failedCount + 1;
    final waitFor = failed < 5 ? null : Duration(seconds: (30 << (failed - 5).clamp(0, 4)).clamp(30, 300));
    await _save(
      _settings.copyWith(failedCount: failed, waitUntil: waitFor == null ? null : _now.add(waitFor)),
      locked: true,
    );
    return waitFor == null ? UnlockResult.wrongPin : UnlockResult.waiting;
  }

  /// The system prompt. The PIN keeps working whatever happens here.
  Future<bool> unlockWithBiometrics() async {
    if (!_settings.biometrics || !await ref.read(biometricsProvider).authenticate()) return false;
    await _save(_settings.copyWith(failedCount: 0, clearWait: true), locked: false);
    return true;
  }

  /// Turns the lock on with [pin], or changes the PIN when it is already on.
  Future<void> setPin(String pin) async {
    if (pin.length < minPinLength || pin.length > maxPinLength || int.tryParse(pin) == null) {
      throw ArgumentError('A PIN is 4 to 8 digits.');
    }
    await _save(
      _settings.copyWith(enabled: true, pin: await _hasher.hash(pin), failedCount: 0, clearWait: true),
      locked: false,
    );
  }

  /// Whether [pin] is the current PIN, for changing it. Does not lock or unlock anything.
  Future<bool> checkPin(String pin) async {
    final stored = _settings.pin;
    return stored != null && await _hasher.verify(pin, stored);
  }

  /// Turns the lock off. The current PIN is asked for first.
  Future<bool> disable(String pin) async {
    final stored = _settings.pin;
    if (stored == null || !await _hasher.verify(pin, stored)) return false;
    await _save(const LockSettings(), locked: false);
    return true;
  }

  Future<void> setDelay(Duration delay) => _save(_settings.copyWith(delaySeconds: delay.inSeconds));

  Future<void> setBiometrics(bool on) => _save(_settings.copyWith(biometrics: on));

  void lockNow() => _publish(locked: true);

  void onPaused() {
    _pausedAt ??= _now;
    if (_settings.enabled && _settings.delaySeconds == 0) _publish(locked: true);
  }

  void onResumed() {
    final since = _pausedAt;
    _pausedAt = null;
    if (!_settings.enabled || since == null) return;
    if (!_now.isBefore(since.add(Duration(seconds: _settings.delaySeconds)))) _publish(locked: true);
  }
}

final lockControllerProvider = NotifierProvider<LockController, LockState>(LockController.new);
