import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/lock_controller.dart';
import 'package:ledgerly/app/providers.dart';
import 'package:ledgerly/core/clock.dart';
import 'package:ledgerly/data/security/lock_store.dart';
import 'package:ledgerly/data/security/pin_hasher.dart';

class FakeBiometrics implements Biometrics {
  bool answer = true;
  int asked = 0;

  @override
  Future<bool> available() async => true;

  @override
  Future<bool> authenticate() async {
    asked += 1;
    return answer;
  }
}

void main() {
  const fast = PinHasher(iterations: 1000, inBackground: false);

  group('PIN hashes', () {
    test('the right PIN verifies and a wrong one does not', () async {
      final h = await fast.hash('2580');
      expect(await fast.verify('2580', h), isTrue);
      expect(await fast.verify('2581', h), isFalse);
      expect(h.hash, isNot(contains('2580')));
    });

    test('the same PIN gets a different salt each time', () async {
      final a = await fast.hash('2580');
      final b = await fast.hash('2580');
      expect(a.salt, isNot(b.salt));
      expect(a.hash, isNot(b.hash));
    });

    test('a hash keeps its own number of rounds', () async {
      final old = await const PinHasher(iterations: 500, inBackground: false).hash('1234');
      expect(await fast.verify('1234', old), isTrue);
    });
  });

  test('the lock file round trips and an unreadable one means no lock', () async {
    final dir = Directory.systemTemp.createTempSync('ledgerly_lock');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = FileLockStore(File('${dir.path}/app_lock.json'));
    expect((await store.read()).enabled, isFalse);
    final pin = await fast.hash('2580');
    await store.write(LockSettings(enabled: true, pin: pin, delaySeconds: 60, failedCount: 2));
    final back = await store.read();
    expect((back.enabled, back.delaySeconds, back.failedCount), (true, 60, 2));
    expect(await fast.verify('2580', back.pin!), isTrue);

    File('${dir.path}/app_lock.json').writeAsStringSync('{broken');
    expect((await store.read()).enabled, isFalse);
  });

  group('the lock', () {
    late FixedClock clock;
    late MemoryLockStore store;
    late FakeBiometrics biometrics;

    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(clock),
          lockStoreProvider.overrideWithValue(store),
          pinHasherProvider.overrideWithValue(fast),
          biometricsProvider.overrideWithValue(biometrics),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Future<LockController> ready(ProviderContainer c) async {
      c.read(lockControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(lockControllerProvider).loaded, isTrue);
      return c.read(lockControllerProvider.notifier);
    }

    setUp(() {
      clock = FixedClock(DateTime(2026, 11, 4, 9));
      store = MemoryLockStore();
      biometrics = FakeBiometrics();
    });

    test('off by default, and nothing is covered once loaded', () async {
      final c = container();
      await ready(c);
      expect(c.read(lockControllerProvider).enabled, isFalse);
      expect(c.read(lockControllerProvider).covered, isFalse);
    });

    test('locks after the delay in the background, not before', () async {
      final c = container();
      final lock = await ready(c);
      await lock.setPin('2580');
      expect(c.read(lockControllerProvider).locked, isFalse);

      lock.onPaused();
      clock.value = clock.value.add(const Duration(minutes: 4, seconds: 59));
      lock.onResumed();
      expect(c.read(lockControllerProvider).locked, isFalse, reason: 'the default delay is 5 minutes');

      lock.onPaused();
      clock.value = clock.value.add(const Duration(minutes: 5));
      lock.onResumed();
      expect(c.read(lockControllerProvider).locked, isTrue);
      expect(await lock.unlockWithPin('2580'), UnlockResult.unlocked);
      expect(c.read(lockControllerProvider).locked, isFalse);
    });

    test('Immediately locks as soon as the app goes away', () async {
      final c = container();
      final lock = await ready(c);
      await lock.setPin('2580');
      await lock.setDelay(Duration.zero);
      lock.onPaused();
      expect(c.read(lockControllerProvider).locked, isTrue);
    });

    test('a lock that is on starts locked, also after a restart', () async {
      final lock = await ready(container());
      await lock.setPin('2580');
      final again = container();
      await ready(again);
      expect(again.read(lockControllerProvider).locked, isTrue);
    });

    test('five wrong PINs mean waiting, doubling each time, and the wait survives a restart', () async {
      final c = container();
      final lock = await ready(c);
      await lock.setPin('2580');
      lock.lockNow();
      for (var i = 0; i < 4; i++) {
        expect(await lock.unlockWithPin('0000'), UnlockResult.wrongPin);
      }
      expect(await lock.unlockWithPin('0000'), UnlockResult.waiting);
      expect(c.read(lockControllerProvider).waitUntil, clock.value.add(const Duration(seconds: 30)));
      expect(
        await lock.unlockWithPin('2580'),
        UnlockResult.waiting,
        reason: 'not even the right PIN while waiting',
      );

      final restarted = container();
      final again = await ready(restarted);
      expect(await again.unlockWithPin('2580'), UnlockResult.waiting);

      clock.value = clock.value.add(const Duration(seconds: 31));
      expect(await again.unlockWithPin('0000'), UnlockResult.waiting);
      expect(restarted.read(lockControllerProvider).waitUntil, clock.value.add(const Duration(seconds: 60)));

      clock.value = clock.value.add(const Duration(seconds: 61));
      expect(await again.unlockWithPin('2580'), UnlockResult.unlocked);
      expect((await store.read()).failedCount, 0);
    });

    test('the fingerprint unlocks when it is on, and a failure leaves the PIN', () async {
      final c = container();
      final lock = await ready(c);
      await lock.setPin('2580');
      lock.lockNow();
      expect(await lock.unlockWithBiometrics(), isFalse, reason: 'off until turned on');
      expect(biometrics.asked, 0);

      await lock.setBiometrics(true);
      biometrics.answer = false;
      expect(await lock.unlockWithBiometrics(), isFalse);
      expect(c.read(lockControllerProvider).locked, isTrue);

      biometrics.answer = true;
      expect(await lock.unlockWithBiometrics(), isTrue);
      expect(c.read(lockControllerProvider).locked, isFalse);
    });

    test('turning it off asks for the PIN, and PINs are 4 to 8 digits', () async {
      final lock = await ready(container());
      await lock.setPin('2580');
      expect(await lock.disable('1111'), isFalse);
      expect((await store.read()).enabled, isTrue);
      expect(await lock.checkPin('2580'), isTrue);
      expect(await lock.disable('2580'), isTrue);
      expect((await store.read()).enabled, isFalse);
      expect(() => lock.setPin('123'), throwsArgumentError);
      expect(() => lock.setPin('123456789'), throwsArgumentError);
      expect(() => lock.setPin('12ab'), throwsArgumentError);
    });
  });
}
