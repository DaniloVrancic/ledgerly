// The app: themes from the design system, light, dark or following the phone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lock/lock_screen.dart';
import '../ui/theme/app_theme.dart';
import 'app_shell.dart';
import 'navigation.dart';
import 'providers.dart';

class LedgerlyApp extends ConsumerWidget {
  const LedgerlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentProvider);
    final mode = switch (ref.watch(themeModeSettingProvider)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: 'Ledgerly',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(Brightness.light, accent),
      darkTheme: buildTheme(Brightness.dark, accent),
      themeMode: mode,
      // The lock covers everything, sheets and dialogs included.
      builder: (context, child) => LockGate(child: child ?? const SizedBox()),
      home: const AppShell(),
    );
  }
}
