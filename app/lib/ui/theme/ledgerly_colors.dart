// The design system's colour tokens (design-system/tokens/tokens.json) for both themes.
// Screens read them with `context.colors`. Meanings never change: positive is income,
// negative is spending, warning needs attention, neutral is transfers and supporting text.

import 'package:flutter/material.dart';

enum AccentChoice {
  forest('Forest', Color(0xFF163D32), Color(0xFF9CD4BA)),
  lake('Lake', Color(0xFF1F4E79), Color(0xFF9CC6EA)),
  plum('Plum', Color(0xFF5B3A6E), Color(0xFFCFB4E2)),
  slate('Slate', Color(0xFF3B4A54), Color(0xFFBAC8D2));

  const AccentChoice(this.label, this.light, this.dark);
  final String label;
  final Color light;
  final Color dark;
}

@immutable
class LedgerlyColors extends ThemeExtension<LedgerlyColors> {
  const LedgerlyColors({
    required this.background,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.surfaceInverse,
    required this.onInverse,
    required this.surfaceTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.borderSubtle,
    required this.borderControl,
    required this.positive,
    required this.positiveFill,
    required this.positiveTint,
    required this.negative,
    required this.negativeFill,
    required this.negativeTint,
    required this.warning,
    required this.warningFill,
    required this.warningTint,
    required this.neutral,
    required this.neutralFill,
    required this.neutralTint,
    required this.accent,
    required this.onAccent,
    required this.categories,
    required this.chart,
    required this.chartGrid,
  });

  final Color background;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color surfaceInverse;
  final Color onInverse;
  final Color surfaceTint;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color borderSubtle;
  final Color borderControl;
  final Color positive;
  final Color positiveFill;
  final Color positiveTint;
  final Color negative;
  final Color negativeFill;
  final Color negativeTint;
  final Color warning;
  final Color warningFill;
  final Color warningTint;
  final Color neutral;
  final Color neutralFill;
  final Color neutralTint;
  final Color accent;
  final Color onAccent;

  /// The twelve curated category colours. Slot 0 is the neutral colour.
  final List<Color> categories;

  /// Chart colours by rank: the largest item always uses the first.
  final List<Color> chart;
  final Color chartGrid;

  Color category(int slot) => slot >= 1 && slot <= categories.length ? categories[slot - 1] : neutral;

  static LedgerlyColors light(AccentChoice accent) => LedgerlyColors(
    background: const Color(0xFFF7F8F5),
    surface1: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFF0F2ED),
    surface3: const Color(0xFFE6E9E3),
    surfaceInverse: const Color(0xFF163D32),
    onInverse: const Color(0xFFF7F8F5),
    surfaceTint: const Color(0xFFE8F2EC),
    textPrimary: const Color(0xFF252C2A),
    textSecondary: const Color(0xFF4F5A55),
    textTertiary: const Color(0xFF5F6A65),
    textDisabled: const Color(0xFF8A938E),
    borderSubtle: const Color(0xFFE2E5DF),
    borderControl: const Color(0xFF7F8984),
    positive: const Color(0xFF1F6B4F),
    positiveFill: const Color(0xFF2F8A66),
    positiveTint: const Color(0xFFE3F1E9),
    negative: const Color(0xFFB23F35),
    negativeFill: const Color(0xFFD9685D),
    negativeTint: const Color(0xFFFBEBE8),
    warning: const Color(0xFF7A5710),
    warningFill: const Color(0xFFD9A441),
    warningTint: const Color(0xFFFAF1DC),
    neutral: const Color(0xFF55615C),
    neutralFill: const Color(0xFF7C8782),
    neutralTint: const Color(0xFFECEEEA),
    accent: accent.light,
    onAccent: const Color(0xFFF7F8F5),
    categories: const [
      Color(0xFF4A4A8D),
      Color(0xFF487B00),
      Color(0xFF007FBF),
      Color(0xFFA1497F),
      Color(0xFF106D3B),
      Color(0xFF9365B5),
      Color(0xFF665FA2),
      Color(0xFF575CCB),
      Color(0xFF7A8228),
      Color(0xFFA43952),
      Color(0xFF822A5A),
      Color(0xFF59248E),
    ],
    chart: const [
      Color(0xFF3770BF),
      Color(0xFF905C0E),
      Color(0xFF651A7B),
      Color(0xFF247A3C),
      Color(0xFF9949A3),
      Color(0xFF683705),
      Color(0xFF7C8782),
    ],
    chartGrid: const Color(0xFFE2E5DF),
  );

  static LedgerlyColors dark(AccentChoice accent) => LedgerlyColors(
    background: const Color(0xFF0D1412),
    surface1: const Color(0xFF141D1A),
    surface2: const Color(0xFF1A2521),
    surface3: const Color(0xFF222F2A),
    surfaceInverse: const Color(0xFF1A2521),
    onInverse: const Color(0xFFEDF1EC),
    surfaceTint: const Color(0xFF1B2D26),
    textPrimary: const Color(0xFFEDF1EC),
    textSecondary: const Color(0xFFB4C0BA),
    textTertiary: const Color(0xFF97A49D),
    textDisabled: const Color(0xFF6B7871),
    borderSubtle: const Color(0xFF26332E),
    borderControl: const Color(0xFF6F7E76),
    positive: const Color(0xFF7CCBA2),
    positiveFill: const Color(0xFF5FAF87),
    positiveTint: const Color(0xFF16302A),
    negative: const Color(0xFFF0A195),
    negativeFill: const Color(0xFFD9806F),
    negativeTint: const Color(0xFF35201D),
    warning: const Color(0xFFE6C27A),
    warningFill: const Color(0xFFD0A650),
    warningTint: const Color(0xFF322A16),
    neutral: const Color(0xFFAAB6B0),
    neutralFill: const Color(0xFF7F8D86),
    neutralTint: const Color(0xFF222C28),
    accent: accent.dark,
    onAccent: const Color(0xFF0D1412),
    categories: const [
      Color(0xFF8689CC),
      Color(0xFFADD78C),
      Color(0xFF63B5F1),
      Color(0xFFDC9FC0),
      Color(0xFF97C7A4),
      Color(0xFF926FAE),
      Color(0xFFB7B6E1),
      Color(0xFFC9D1FE),
      Color(0xFF818847),
      Color(0xFFFBC2CA),
      Color(0xFFA86C88),
      Color(0xFFA695C0),
    ],
    chart: const [
      Color(0xFF6C9DE2),
      Color(0xFFC88E46),
      Color(0xFFE4C1EF),
      Color(0xFF9DD2A5),
      Color(0xFFA76BAE),
      Color(0xFFFBB075),
      Color(0xFF7F8D86),
    ],
    chartGrid: const Color(0xFF26332E),
  );

  @override
  LedgerlyColors copyWith() => this;

  @override
  LedgerlyColors lerp(ThemeExtension<LedgerlyColors>? other, double t) =>
      t < 0.5 ? this : (other as LedgerlyColors? ?? this);
}

extension LedgerlyContext on BuildContext {
  LedgerlyColors get colors => Theme.of(this).extension<LedgerlyColors>()!;
  LedgerlyText get text => LedgerlyText.of(this);
}

/// The type scale from the design system. Money always uses tabular figures.
class LedgerlyText {
  LedgerlyText._(this._c);
  final LedgerlyColors _c;

  factory LedgerlyText.of(BuildContext context) => LedgerlyText._(context.colors);

  static const _tabular = [FontFeature.tabularFigures()];

  TextStyle get balance => TextStyle(
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    color: _c.textPrimary,
    fontFeatures: _tabular,
  );
  TextStyle get amountLarge => TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: _c.textPrimary,
    fontFeatures: _tabular,
  );
  TextStyle get amount => TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: _c.textPrimary,
    fontFeatures: _tabular,
  );
  TextStyle get amountSmall => TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    color: _c.textTertiary,
    fontFeatures: _tabular,
  );
  TextStyle get titleLarge => TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: _c.textPrimary,
  );
  TextStyle get title =>
      TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600, color: _c.textPrimary);
  TextStyle get subtitle =>
      TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500, color: _c.textPrimary);
  TextStyle get body => TextStyle(fontSize: 16, height: 1.5, color: _c.textPrimary);
  TextStyle get bodySmall => TextStyle(fontSize: 14, height: 20 / 14, color: _c.textSecondary);
  TextStyle get label =>
      TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: _c.textPrimary);
  TextStyle get caption =>
      TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, color: _c.textTertiary);
}
