// The app starts on Home with real data and every main tab opens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/ui/theme/app_theme.dart';
import 'package:ledgerly/ui/theme/ledgerly_colors.dart';

import 'app_harness.dart';

void main() {
  testWidgets('the app opens on Home and every tab shows', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();
    expect(find.text('Total balance'), findsOneWidget);
    for (final tab in ['Entries', 'Insights', 'More', 'Home']) {
      await tester.tap(find.text(tab).last);
      await h.settle();
    }
    expect(find.text('Total balance'), findsOneWidget);
    await h.dispose();
  });

  test('system bars are transparent with readable icons, and back is predictive on Android', () {
    for (final b in Brightness.values) {
      final theme = buildTheme(b, AccentChoice.values.first);
      final bars = theme.appBarTheme.systemOverlayStyle!;
      expect(bars.statusBarColor, Colors.transparent);
      expect(bars.systemNavigationBarColor, Colors.transparent);
      final icons = b == Brightness.dark ? Brightness.light : Brightness.dark;
      expect(bars.statusBarIconBrightness, icons);
      expect(bars.systemNavigationBarIconBrightness, icons);
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<PredictiveBackPageTransitionsBuilder>(),
      );
    }
  });
}
