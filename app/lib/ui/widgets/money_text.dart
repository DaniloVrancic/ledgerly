// An amount, always with its sign and colour together, so colour is never the only cue.

import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../theme/ledgerly_colors.dart';

enum MoneyTone { auto, positive, negative, neutral, plain }

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor, {
    super.key,
    this.currency = 'EUR',
    this.sign = false,
    this.tone = MoneyTone.plain,
    this.style,
    this.textAlign,
  });

  final int minor;
  final String currency;

  /// Shows a plus for positive amounts.
  final bool sign;
  final MoneyTone tone;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (tone) {
      MoneyTone.positive => c.positive,
      MoneyTone.negative => c.negative,
      MoneyTone.neutral => c.neutral,
      MoneyTone.auto =>
        minor > 0
            ? c.positive
            : minor < 0
            ? c.negative
            : c.textPrimary,
      MoneyTone.plain => null,
    };
    final base = style ?? context.text.amount;
    return Text(
      formatMoney(minor, currency, sign: sign),
      style: base.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
      textAlign: textAlign,
      softWrap: false,
    );
  }
}
