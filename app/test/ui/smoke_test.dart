// The app starts on Home with real data and every main tab opens.

import 'package:flutter_test/flutter_test.dart';

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
}
