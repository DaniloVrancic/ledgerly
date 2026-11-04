// The lock screen, and the gate that puts it over the whole app, sheets and dialogs included,
// while the app is locked. The app underneath keeps its place, so unlocking returns to it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/lock_controller.dart';
import '../../app/providers.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';

/// Wraps the app in MaterialApp.builder. It sits above the app's navigator, so the lock
/// screen brings its own Overlay for tooltips and ink.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    LockController controller() => ref.read(lockControllerProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: () => controller().onPaused(),
      onPause: () => controller().onPaused(),
      onResume: () => controller().onResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final covered = ref.watch(lockControllerProvider.select((s) => s.covered));
    return Stack(
      children: [
        // Hidden from sight, touch, focus and screen readers while locked, but kept alive.
        Offstage(
          offstage: covered,
          child: ExcludeFocus(excluding: covered, child: widget.child),
        ),
        // A new Overlay and entry each time the app locks; an entry cannot move between overlays.
        if (covered) Overlay(initialEntries: [OverlayEntry(builder: (_) => const LockScreen())]),
      ],
    );
  }
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _message;
  bool _checking = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Refreshes the waiting message every second.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(lockControllerProvider).waitUntil != null) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _tryBiometrics() async {
    final s = ref.read(lockControllerProvider);
    if (!s.locked || !s.biometrics || !s.biometricsAvailable) return;
    await ref.read(lockControllerProvider.notifier).unlockWithBiometrics();
  }

  void _key(String k) {
    if (_checking) return;
    HapticFeedback.selectionClick();
    setState(() {
      _message = null;
      if (k == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < maxPinLength) {
        _pin += k;
      }
    });
  }

  Future<void> _submit() async {
    if (_pin.length < minPinLength || _checking) return;
    setState(() => _checking = true);
    final result = await ref.read(lockControllerProvider.notifier).unlockWithPin(_pin);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _pin = '';
      _message = switch (result) {
        UnlockResult.unlocked => null,
        UnlockResult.wrongPin => 'That PIN is not right. Try again.',
        UnlockResult.waiting => null,
      };
    });
    if (result == UnlockResult.wrongPin) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(lockControllerProvider);
    final wait = state.waitUntil?.difference(ref.read(clockProvider).now());
    final waiting = wait != null && !wait.isNegative;
    return Material(
      color: c.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surfaceInverse,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: LedgerIcon('lock', size: 24, color: c.onInverse),
                  ),
                  const SizedBox(height: 16),
                  Text('Ledgerly is locked', style: context.text.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    waiting
                        ? 'Too many wrong PINs. Try again in ${wait.inSeconds + 1} seconds.'
                        : _message ?? 'Enter your PIN.',
                    style: context.text.bodySmall.copyWith(
                      color: _message != null || waiting ? c.negative : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    label: '${_pin.length} digits entered',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < (_pin.length < minPinLength ? minPinLength : _pin.length); i++)
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _pin.length ? c.textPrimary : Colors.transparent,
                              border: Border.all(color: c.borderControl, width: 1.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PinPad(
                    onKey: waiting ? null : _key,
                    onSubmit: waiting || _pin.length < minPinLength ? null : _submit,
                  ),
                  if (state.biometrics && state.biometricsAvailable) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _tryBiometrics,
                      icon: const LedgerIcon('key', size: 16),
                      label: const Text('Use fingerprint'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Digits, delete and Unlock, as large keys in thumb reach.
class PinPad extends StatelessWidget {
  const PinPad({super.key, required this.onKey, required this.onSubmit});

  final ValueChanged<String>? onKey;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget key(String label, {VoidCallback? onTap, Widget? child, String? semantics}) => Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: c.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.borderSubtle),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Center(
              child: Semantics(
                button: true,
                label: semantics,
                excludeSemantics: semantics != null,
                child: child ?? Text(label, style: context.text.amountLarge),
              ),
            ),
          ),
        ),
      ),
    );
    final digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Row(
            children: [
              for (final d in digits.sublist(row * 3, row * 3 + 3))
                Expanded(child: key(d, onTap: onKey == null ? null : () => onKey!(d))),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: key(
                'del',
                onTap: onKey == null ? null : () => onKey!('del'),
                semantics: 'Delete digit',
                child: LedgerIcon('backspace', size: 24, color: c.textPrimary),
              ),
            ),
            Expanded(child: key('0', onTap: onKey == null ? null : () => onKey!('0'))),
            Expanded(
              child: key(
                'ok',
                onTap: onSubmit,
                semantics: 'Unlock',
                child: LedgerIcon('check', size: 24, color: onSubmit == null ? c.textDisabled : c.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
