// The app lock through the real screens: turn it on in Settings, leave the app for longer
// than the delay, come back to the lock screen, and unlock with the PIN.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void main() {
  testWidgets('turn the lock on, come back after 6 minutes, unlock with the PIN', (tester) async {
    final h = await AppHarness.create(tester);
    await h.show();

    await tester.tap(find.text('More').last);
    await h.settle();
    await tester.tap(find.text('Settings'));
    await h.settle();
    await tester.tap(find.text('App lock'));
    await h.settle();
    await tester.tap(find.byType(Switch));
    await h.settle();

    await tester.enterText(find.byType(TextField), '2580');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await h.settle();
    expect(find.text('The same PIN again'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2580');
    await tester.pump();
    await tester.tap(find.text('Turn on'));
    await h.settle();
    expect(find.text('On, with a PIN'), findsOneWidget);

    void lifecycle(List<AppLifecycleState> states) {
      for (final s in states) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
    }

    lifecycle([AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    await h.settle();
    h.clock.value = h.clock.value.add(const Duration(minutes: 6));
    lifecycle([AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    await h.settle();

    expect(find.text('Ledgerly is locked'), findsOneWidget);
    expect(find.text('On, with a PIN'), findsNothing, reason: 'the app underneath is hidden');

    for (final d in ['1', '1', '1', '1']) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.tap(find.bySemanticsLabel('Unlock'));
    await h.settle();
    expect(find.text('That PIN is not right. Try again.'), findsOneWidget);

    for (final d in ['2', '5', '8', '0']) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.tap(find.bySemanticsLabel('Unlock'));
    await h.settle();
    expect(find.text('Ledgerly is locked'), findsNothing);
    expect(find.text('On, with a PIN'), findsOneWidget, reason: 'unlocking returns to the same place');

    await h.dispose();
  });
}
