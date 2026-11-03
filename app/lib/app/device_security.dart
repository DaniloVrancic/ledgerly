// The phone's own security for the app lock: the fingerprint or face unlock through the system
// prompt, and a secure window that hides Ledgerly in the recent-apps screen. Android only;
// elsewhere both quietly do nothing and the PIN is the way in.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'lock_controller.dart';

class LocalAuthBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _auth.canCheckBiometrics && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Ledgerly',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Object {
      // Cancelled, locked out after too many tries, or no finger enrolled: the PIN still works.
      return false;
    }
  }
}

const _window = MethodChannel('ledgerly/window');

/// Marks the window secure while the lock is on: no content in recent apps, no screenshots.
Future<void> setSecureWindow(bool on) async {
  if (!Platform.isAndroid) return;
  try {
    await _window.invokeMethod<void>('secure', on);
  } on PlatformException {
    // Without it the lock still works; only the recent-apps preview shows the app.
  }
}
