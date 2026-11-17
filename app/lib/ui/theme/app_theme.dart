// Material theme built from the design tokens, so standard widgets match the design system.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ledgerly_colors.dart';

ThemeData buildTheme(Brightness brightness, AccentChoice accent) {
  final c = brightness == Brightness.dark ? LedgerlyColors.dark(accent) : LedgerlyColors.light(accent);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.negative,
    onError: c.onAccent,
    surface: c.surface1,
    onSurface: c.textPrimary,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.surface1,
    surfaceContainer: c.surface2,
    surfaceContainerHigh: c.surface2,
    surfaceContainerHighest: c.surface3,
    onSurfaceVariant: c.textSecondary,
    outline: c.borderControl,
    outlineVariant: c.borderSubtle,
  );
  final radius = BorderRadius.circular(12);
  // Styles the theme sets directly start from the platform's font, like the rest of the text.
  final type = Typography.material2021(platform: defaultTargetPlatform).black;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: type.titleLarge!.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      systemOverlayStyle: systemBars(brightness),
    ),
    // Predictive back on Android: the page underneath shows while swiping back.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()},
    ),
    cardTheme: CardThemeData(
      color: c.surface1,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.borderSubtle),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.borderSubtle, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.borderControl, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.borderControl, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
      labelStyle: TextStyle(color: c.textSecondary),
      hintStyle: TextStyle(color: c.textTertiary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 44),
        foregroundColor: c.accent,
        side: BorderSide(color: c.borderControl),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.accent, minimumSize: const Size(44, 44)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface2,
      selectedColor: c.surfaceTint,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: type.labelLarge!.copyWith(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: c.surface2,
        selectedBackgroundColor: c.surface1,
        selectedForegroundColor: c.accent,
        foregroundColor: c.textSecondary,
        side: BorderSide(color: c.borderSubtle),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface1,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.borderControl,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surfaceInverse,
      contentTextStyle: type.bodyMedium!.copyWith(color: c.onInverse, fontSize: 14),
      actionTextColor: c.onInverse,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface1,
      indicatorColor: c.surfaceTint,
      surfaceTintColor: Colors.transparent,
    ),
    navigationRailTheme: NavigationRailThemeData(backgroundColor: c.surface1, indicatorColor: c.surfaceTint),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      shape: const CircleBorder(),
    ),
    listTileTheme: ListTileThemeData(iconColor: c.textSecondary, textColor: c.textPrimary),
  );
}

/// Transparent status and navigation bars, drawn edge to edge, with icons that stay readable
/// on the app's light or dark background.
SystemUiOverlayStyle systemBars(Brightness brightness) {
  final iconBrightness = brightness == Brightness.dark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: brightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: iconBrightness,
    systemNavigationBarContrastEnforced: false,
  );
}
