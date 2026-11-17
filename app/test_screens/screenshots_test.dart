// Renders the README screenshots from the real screens with a fictional demo ledger.
// Every name and amount here is made up. Run from app/:
//
//   flutter test test_screens --update-goldens
//
// The PNGs land in docs/screenshots/ at the root of the repository.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/budget_repository.dart';
import 'package:ledgerly/data/repositories/entry_repository.dart';
import 'package:ledgerly/data/repositories/goal_repository.dart';
import 'package:ledgerly/data/repositories/repeat_repository.dart';
import 'package:ledgerly/data/repositories/settings_repository.dart';
import 'package:ledgerly/domain/repeat_schedule.dart';

import '../test/ui/app_harness.dart';

/// Real fonts, so text is drawn as letters instead of the test font's boxes.
Future<void> loadFonts() async {
  final fonts = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<ByteData> file(String name) async => ByteData.sublistView(File('$fonts/$name').readAsBytesSync());
  // Text without a family falls back to the test font, so Roboto stands in for it as on Android.
  for (final family in ['Roboto', 'FlutterTest']) {
    final roboto = FontLoader(family);
    for (final w in ['regular', 'medium', 'bold', 'light']) {
      roboto.addFont(file('roboto-$w.ttf'));
    }
    await roboto.load();
  }
  await (FontLoader('MaterialIcons')..addFont(file('materialicons-regular.otf'))).load();
}

/// A small, steady pseudo-random sequence, so every run draws the same ledger.
class _Dice {
  int _s = 20261029;
  int next(int min, int max) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return min + _s % (max - min + 1);
  }
}

/// Four months of a fictional person's money, ending on the harness day, 29 Oct 2026.
Future<void> fillDemo(AppHarness h) async {
  final entries = EntryRepository(h.db, h.clock);
  final repeats = RepeatRepository(h.db, h.clock, entries);
  final accounts = AccountRepository(h.db, h.clock);
  final dice = _Dice();
  Future<T> r<T>(Future<T> Function() call) => h.read(call);

  final savings = await r(
    () => accounts.create(name: 'Savings', kind: AccountKind.savings, currency: 'EUR', openingMinor: 240000),
  );

  Future<String> repeat(
    String title,
    String kind,
    String cat,
    int amount,
    String next, {
    bool varies = false,
  }) => r(
    () => repeats.create(
      title: title,
      kind: kind,
      categoryId: cat,
      accountId: h.bank,
      amountMinor: amount,
      every: Every.monthly,
      nextDay: next,
      varies: varies,
    ),
  );
  final salary = await repeat('Salary', 'income', 'salary', 245000, '2026-11-01');
  final rent = await repeat('Rent', 'expense', 'rent', 46000, '2026-11-02');
  final electricity = await repeat('Electricity', 'expense', 'electricity', 8900, '2026-10-29', varies: true);
  final internet = await repeat('Internet', 'expense', 'internet', 2999, '2026-10-30');
  final netflix = await repeat('Netflix', 'expense', 'streaming', 1299, '2026-10-31');

  Future<String> spend(String day, String cat, int amount, String title, {String? account}) async {
    final (id, _) = await r(
      () => entries.addEntry(
        isExpense: true,
        accountId: account ?? h.bank,
        amountMinor: amount,
        categoryId: cat,
        title: title,
        day: day,
      ),
    );
    return id;
  }

  Future<void> paid(
    String repeatId,
    String day,
    String cat,
    int amount,
    String title, {
    bool income = false,
  }) => r(
    () => entries.addEntry(
      isExpense: !income,
      accountId: h.bank,
      amountMinor: amount,
      categoryId: cat,
      title: title,
      day: day,
      repeatId: repeatId,
      repeatDay: day,
    ),
  );

  for (final m in [7, 8, 9, 10]) {
    String d(int day) => '2026-${m.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    await paid(salary, d(1), 'salary', 245000, 'Salary', income: true);
    await paid(rent, d(2), 'rent', 46000, 'Rent');
    if (m < 10) {
      await paid(electricity, d(28), 'electricity', dice.next(6200, 9800), 'Electricity');
      await paid(internet, d(30), 'internet', 2999, 'Internet');
      await paid(netflix, d(30), 'streaming', 1299, 'Netflix');
    }
    await r(
      () => entries.addTransfer(fromAccountId: h.bank, toAccountId: savings, amountMinor: 30000, day: d(3)),
    );

    final last = m == 10 ? 29 : 28;
    for (var day = 1; day <= last; day += dice.next(2, 4)) {
      await spend(d(day), 'groceries', dice.next(1800, 7400), day.isEven ? 'Konzum' : 'Groceries');
    }
    for (var day = 4; day <= last; day += 7) {
      await spend(d(day), 'dining', dice.next(1500, 4800), day > 14 ? 'Dinner with friends' : 'Lunch');
      await spend(
        d(day + 1 > last ? last : day + 1),
        'coffee',
        dice.next(400, 900),
        'Coffee',
        account: h.cash,
      );
    }
    for (var day = 6; day <= last; day += 10) {
      await spend(d(day), 'fuel', dice.next(4500, 7000), 'Fuel');
    }
    await spend(d(12), 'pharmacy', dice.next(800, 2600), 'Pharmacy');
    await spend(d(17), 'cinema', 1400, 'Cinema');
    if (m == 9) await spend(d(20), 'trips', 18500, 'Weekend in Mostar');
    if (m == 8) await spend(d(15), 'electronics', 12900, 'Headphones');
  }
  final jacket = await spend('2026-10-21', 'clothes', 8900, 'Winter jacket');
  await r(() => entries.addRefund(ofEntryId: jacket, amountMinor: 2000, day: '2026-10-24'));
  await r(() => entries.addLater(accountId: h.cash, amountMinor: 1500));

  final budgets = BudgetRepository(h.db, h.clock);
  await r(() => budgets.create(categoryId: 'food', limitMinor: 50000, every: BudgetEvery.monthly));
  await r(() => budgets.create(categoryId: 'transport', limitMinor: 20000, every: BudgetEvery.monthly));
  await r(() => budgets.create(categoryId: 'shopping', limitMinor: 10000, every: BudgetEvery.monthly));

  final goals = GoalRepository(h.db, h.clock);
  final trip = await r(
    () => goals.create(
      name: 'Summer trip',
      icon: 'plane',
      colorSlot: 3,
      targetMinor: 150000,
      targetDay: '2027-06-01',
      accountId: savings,
    ),
  );
  await r(() => goals.addMoney(trip, 60000, freeMinor: 1 << 40));
  final laptop = await r(
    () => goals.create(
      name: 'New laptop',
      icon: 'laptop',
      colorSlot: 7,
      targetMinor: 120000,
      accountId: savings,
    ),
  );
  await r(() => goals.addMoney(laptop, 35000, freeMinor: 1 << 40));
}

void main() {
  setUpAll(loadFonts);
  late WidgetTester tester_;

  Future<AppHarness> start(WidgetTester tester, {Size size = const Size(390, 844), bool dark = false}) async {
    tester_ = tester;
    // Real shadows instead of the test's black outlines, switched on before anything is drawn.
    debugDisableShadows = false;
    final h = await AppHarness.create(tester);
    await fillDemo(h);
    if (dark) await h.read(() => SettingsRepository(h.db, h.clock).write(SettingKeys.themeMode, 'dark'));
    await h.show();
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    await h.settle();
    return h;
  }

  Future<void> shoot(String name) async {
    // Lets tap ink fade before the picture is taken.
    await tester_.pump(const Duration(seconds: 2));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('../../docs/screenshots/$name.png'));
  }

  Future<void> tap(AppHarness h, Finder f) async {
    await h.tester.tap(f);
    await h.settle();
  }

  testWidgets('phone screens', (tester) async {
    final h = await start(tester);
    await shoot('phone_home');

    await tap(h, find.text('Lowest before payday'));
    await shoot('phone_forecast');
    await tap(h, find.widgetWithText(OutlinedButton, 'Close'));

    await tap(h, find.text('Entries'));
    await shoot('phone_entries');
    await tap(h, find.text('Calendar'));
    await shoot('phone_calendar');

    await tap(h, find.text('Insights'));
    await shoot('phone_insights');

    await tap(h, find.text('Home'));
    await tap(h, find.byTooltip('Add'));
    await shoot('phone_add');

    await h.dispose();
    debugDisableShadows = true;
  });

  testWidgets('phone home in dark mode', (tester) async {
    final h = await start(tester, dark: true);
    await shoot('phone_home_dark');
    await h.dispose();
    debugDisableShadows = true;
  });

  testWidgets('wide window', (tester) async {
    final h = await start(tester, size: const Size(1280, 800));
    await shoot('desktop_home');
    await h.dispose();
    debugDisableShadows = true;
  });
}
