// After a change, a short message with Undo for five seconds. No confirmation dialogs for
// anything Undo can reverse.

import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../data/repositories/repository.dart';
import '../theme/ledgerly_colors.dart';

/// Shows [message] with Undo and an optional second action. Safe to call just before a sheet
/// closes: the message is shown by the app, not by the sheet.
void showUndo(BuildContext context, String message, {Undo? undo, String? extraLabel, VoidCallback? onExtra}) {
  final messenger = messengerKey.currentState ?? ScaffoldMessenger.of(context);
  final onInverse = context.colors.onInverse;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 5),
      content: Row(
        children: [
          Expanded(child: Text(message)),
          if (undo != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: onInverse),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                undo();
              },
              child: const Text('Undo'),
            ),
          if (extraLabel != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: onInverse),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onExtra?.call();
              },
              child: Text(extraLabel),
            ),
        ],
      ),
    ),
  );
}

/// Shows a problem the person can fix, such as an amount of zero.
void showProblem(BuildContext context, Object error) {
  final messenger = messengerKey.currentState ?? ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(error.toString())));
}
