// The on-screen number pad on the Add sheet. Keys are at least 56 tall and the pad stays
// phone width on wide screens.

import 'package:flutter/material.dart';

import '../icons/ledger_icon.dart';
import '../theme/ledgerly_colors.dart';

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey});

  /// Called with "0" to "9", "." or "del".
  final ValueChanged<String> onKey;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'del'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
        children: [
          for (final k in _keys)
            Material(
              color: c.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.borderSubtle),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onKey(k),
                child: Center(
                  child: k == 'del'
                      ? LedgerIcon('backspace', size: 24, color: c.textPrimary, semanticLabel: 'Delete digit')
                      : Text(k, style: context.text.amountLarge),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
