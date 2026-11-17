// Security: the app lock. Off by default; a PIN works everywhere, and on phones the
// fingerprint or face unlock can be used too.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/lock_controller.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lock = ref.watch(lockControllerProvider);
    final controller = ref.read(lockControllerProvider.notifier);

    Future<void> turnOn() async {
      final pin = await _askNewPin(context);
      if (pin == null) return;
      await controller.setPin(pin);
      if (context.mounted) showUndo(context, 'App lock is on');
    }

    Future<void> turnOff() async {
      final pin = await _askPin(context, title: 'Turn off app lock', action: 'Turn off');
      if (pin == null) return;
      final ok = await controller.disable(pin);
      if (context.mounted) {
        showUndo(context, ok ? 'App lock is off' : 'That PIN is not right. App lock stays on.');
      }
    }

    Future<void> changePin() async {
      final current = await _askPin(context, title: 'Your current PIN', action: 'Next');
      if (current == null || !context.mounted) return;
      if (!await controller.checkPin(current)) {
        if (context.mounted) showProblem(context, 'That PIN is not right.');
        return;
      }
      if (!context.mounted) return;
      final next = await _askNewPin(context);
      if (next == null) return;
      await controller.setPin(next);
      if (context.mounted) showUndo(context, 'PIN changed');
    }

    String delayLabel(Duration d) => d == Duration.zero
        ? 'Immediately'
        : d.inMinutes == 1
        ? 'After 1 minute'
        : 'After ${d.inMinutes} minutes';

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const LedgerIcon('lock'),
              title: const Text('App lock'),
              subtitle: Text(lock.enabled ? 'On, with a PIN' : 'Off'),
              value: lock.enabled,
              onChanged: (on) => on ? turnOn() : turnOff(),
            ),
          ),
          if (lock.enabled) ...[
            const SizedBox(height: 8),
            LedgerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Duration>(
                    isExpanded: true,
                    initialValue: lockDelays.contains(lock.delay) ? lock.delay : const Duration(minutes: 5),
                    decoration: const InputDecoration(labelText: 'Lock when Ledgerly has been away'),
                    items: [
                      for (final d in lockDelays) DropdownMenuItem(value: d, child: Text(delayLabel(d))),
                    ],
                    onChanged: (d) {
                      if (d != null) controller.setDelay(d);
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A few minutes means checking Ledgerly often does not ask for the PIN every time.',
                    style: context.text.caption,
                  ),
                  if (lock.biometricsAvailable)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Unlock with fingerprint'),
                      subtitle: const Text('Or face unlock. The PIN always works too.'),
                      value: lock.biometrics,
                      onChanged: controller.setBiometrics,
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: changePin, child: const Text('Change PIN')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          LedgerCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LedgerIcon('info', color: c.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App lock hides Ledgerly on this device until the PIN is entered, also in the list of recent apps. '
                    'It does not encrypt your data; a password on an export protects a file. A forgotten PIN can only be '
                    'cleared by clearing Ledgerly\'s app data, which deletes your data on this device, so keep a backup '
                    'or an export.',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for a new PIN twice. Null when cancelled.
Future<String?> _askNewPin(BuildContext context) async {
  final first = await _askPin(context, title: 'Choose a PIN', action: 'Next', hint: '4 to 8 digits');
  if (first == null || !context.mounted) return null;
  final second = await _askPin(context, title: 'The same PIN again', action: 'Turn on');
  if (second == null) return null;
  if (second != first) {
    if (context.mounted) showProblem(context, 'The two PINs are not the same. Nothing was changed.');
    return null;
  }
  return first;
}

Future<String?> _askPin(BuildContext context, {required String title, required String action, String? hint}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final ok = controller.text.length >= minPinLength;
        void submit() {
          if (controller.text.length >= minPinLength) Navigator.pop(dialogContext, controller.text);
        }

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: maxPinLength,
            decoration: InputDecoration(labelText: 'PIN', helperText: hint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: ok ? submit : null, child: Text(action)),
          ],
        );
      },
    ),
  );
}
