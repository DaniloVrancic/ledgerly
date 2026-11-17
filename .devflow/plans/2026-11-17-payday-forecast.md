# Ledgerly: payday forecast on Home

> **Implementation brief.**
> - **What to build:** a "Lowest before payday" card on Home, under Total balance, with a "How this estimate works" sheet. The lowest is spendable today − bills before payday − normal daily spending × days.
> - **Constraints:** no schema change, no new packages.
> - **Shipped as two stacked PRs** into `develop`, each under 12 files with its own README change:
>   - `feat/payday-forecast-rule` covers Steps 1–3: the rule, the query, the providers, their tests and "The money rules" in the README.
>   - `feat/payday-forecast-home` covers Steps 4–6: the card, the sheet, the widget tests and the Home row in the README.
>   - The rule is plain Dart in `app/lib/domain/payday_forecast.dart`.
>   - Data comes only through `EntryRepository.watchEverydaySpending`.
>   - Design-system tokens only.
> - **How to work:** follow the Steps in order, run the Verification commands, and don't commit. Merging is the user's call (regular merge into `develop`, never squash).

## Status

approved

## Goal

Home should answer the brief's second question, "will I make it to payday" (`docs/design-prompt.md`, Key screen requirements, Home item 2). Under Total balance, a card shows **Lowest before payday**: the expected lowest spendable balance before the next salary. It is worked out from today's spendable balance, the bills due before payday and normal daily spending, it is labelled as an estimate, and its calculation is one tap away.

The prototype designs this (`prototype/js/ledger.js` `forecast()`, `dailyNormal()`, `nextPayday()`, and `prototype/js/home.js` `forecastCard()` with the `forecast` sheet), but the Flutter app never built it, and `app/README.md` does not list it under "Not built yet".

Ship it as **one PR** from `develop` of `github.com/DaniloVrancic/ledgerly`, on branch `feat/payday-forecast`. Merge it with a regular merge commit, never squash, with **at most 11 files**.

## Non-goals

- No schema change, no new table, no new package.
- No forecast chart or day-by-day curve. The prototype computes a curve but never draws it.
- No forecast on Insights, the calendar or the desktop.
- No "biweekly" or other new repeat cadence.
- No setting to pick which income repeat counts as salary (see Open questions).
- Incoming money other than the payday itself (refunds, repayments, other income repeats before payday) is left out, which errs on the low side.

## Requirements and acceptance criteria

The test fixture day is **29 Oct 2026** (`FixedClock(DateTime(2026, 10, 29, 12))`, as in `test/ui/app_harness.dart` and `test/data/test_ledger.dart`).

| # | Requirement | Observable acceptance |
|---|---|---|
| R1 | **Payday** is the earliest next date of any active income repeat that is not daily, strictly after today. | Income repeats "Salary", monthly, next 1 Nov, and "Bonus", yearly, next 15 Dec: payday is 1 Nov, titled Salary. A daily income repeat alone gives no payday. |
| R2 | **No payday, no card.** Without a non-daily income repeat, Home shows no forecast card. | A fresh harness ledger with no repeats: `find.text('Lowest before payday')` finds nothing. |
| R3 | **Payday not marked paid.** While a non-daily income repeat is Due (`nextDay <= today`), the card shows no amount and says it is waiting. | Salary next 28 Oct, today 29 Oct: the card reads "Salary is due. Mark it paid to see the forecast." and shows no amount. Tapping Mark paid in Due brings the amount back. |
| R4 | **Spendable today** = min(sum of non-archived, non-savings accounts in EUR, Free to use). Goal money is taken first from Savings accounts and the rest from the other accounts. | Bank €1,000, Cash 200 KM (€102.26), Savings €500: with €0 set aside, spendable is €1,102.26. With €300 set aside it is still €1,102.26. With €700 set aside it is €902.26. |
| R5 | **Bills** are active **expense** repeats that are **monthly or yearly**, not on a Savings account. Each occurrence from `nextDay` to the day before payday counts at the repeat's current amount, converted to EUR. A Due bill (`nextDay <= today`) counts once, dated today. | Electricity monthly, next 29 Oct, €89: one bill, "Due". Netflix monthly, next 31 Oct, €12.99: one bill on 31 Oct. Rent monthly, next 1 Nov: not a bill, because it falls on payday. A weekly expense repeat is never a bill. |
| R6 | **Normal daily spending** is counted spending (expenses minus refunds, from category postings of kind `expense`, so transfers, Untracked and repayments never count) over the last 92 days, today included. It leaves out entries paid from monthly or yearly repeats (entries whose `repeatId` points to such a repeat, deleted repeats included). Entries from daily or weekly repeats stay in. It is divided by the history days: 92, or fewer when the first entry is more recent. It rounds half up to the cent and is never below zero. | €276 of ordinary spending in the window, plus a €460 rent entry paid from a monthly repeat, with the first entry 92 or more days ago: €3.00 a day. With the first entry on 20 Oct (10 days), €276 gives €27.60 a day. With no entries at all, €0.00 a day over 0 days. |
| R7 | **Lowest** = spendable − bills − daily × days, where days are the days strictly between today and payday. It is on the day before payday, or today when there are no such days. | Today 29 Oct, payday 1 Nov: 2 days (30 and 31 Oct). Spendable €1,102.26, bills €101.99, daily €3.00: lowest €994.27, around 31 Oct. |
| R8 | **Card.** Under Total balance and above Due: the "Lowest before payday" label, an "Estimate" tag, the amount (negative in the negative colour, always with its minus sign) and one line, "Around 31 Oct, after €89.00 of bills. Salary on 1 Nov." Tapping opens the sheet. Touch target at least 44px. Screen readers get the card's own texts, merged by its `InkWell`, with no custom label that would hide the amount. | With the widget-test fixture (see Tests): the test finds "Lowest before payday", "Estimate", "€743.26" and "Around 31 Oct, after €89.00 of bills. Salary on 1 Nov." |
| R9 | **Sheet "How this estimate works"** lists: spendable today, bills before payday (negative), normal daily spending × days (negative), and the lowest with its day (emphasised). Under that, one sentence on the history days, then every bill with its day ("Due" for a Due bill), title and amount. A Close button. | The widget test taps the card and finds "How this estimate works", "Normal daily spending, €90.00 × 2 days", "Due · Electricity", and a history note containing "average over the last day". Close dismisses it. |
| R10 | **Live.** Adding an expense, marking a repeat paid, or changing a goal updates the card without a restart. | The widget test adds a €50 expense through the repository while Home is shown. After `settle()` the card shows "€593.26". |
| R11 | **Small screens.** No overflow on a 360×640 phone at 100% and 150% text with the card shown. | `test/ui/small_screen_test.dart` passes with a salary repeat added to `fillLedger`. |

## Design

### Where things go

| Layer | File | Change |
|---|---|---|
| Rule (plain Dart) | `app/lib/domain/payday_forecast.dart` (new) | Types and the `forecastToPayday` function. Imports only `../core/day.dart` and `repeat_schedule.dart`. No Flutter, no drift. |
| Data | `app/lib/data/repositories/entry_repository.dart` | New `watchEverydaySpending(start, end)`. |
| Wiring | `app/lib/app/providers.dart` | `everydaySpendingProvider` and `paydayForecastProvider`. |
| Screen | `app/lib/features/home/payday_forecast.dart` (new) | `PaydayForecastCard` and the sheet. |
| Screen | `app/lib/features/home/home_screen.dart` | Insert the card. Update the header comment. |

### Domain: `app/lib/domain/payday_forecast.dart`

```dart
// Will I make it to payday: the lowest spendable balance before the next salary, from
// today's spendable balance, the bills before payday and normal daily spending. An estimate.

import '../core/day.dart';
import 'repeat_schedule.dart';

/// How many past days set normal daily spending.
const forecastWindowDays = 92;

/// A repeat as the forecast sees it. Amounts are in EUR.
class ForecastRepeat {
  const ForecastRepeat({
    required this.title,
    required this.isIncome,
    required this.every,
    required this.nextDay,
    required this.anchorDay,
    required this.baseMinor,
    required this.onSavings,
  });
  final String title;
  final bool isIncome;
  final Every every;
  final String nextDay;
  final int anchorDay;
  final int baseMinor;

  /// Kept on a Savings account, so it never touches the spendable balance.
  final bool onSavings;
}

class ForecastBill {
  const ForecastBill({required this.title, required this.day, required this.baseMinor, required this.due});
  final String title;
  final String day;
  final int baseMinor;

  /// Already Due and not paid: counted today.
  final bool due;
}

sealed class ForecastOutcome {
  const ForecastOutcome();
}

/// No income repeat to forecast to.
class NoPayday extends ForecastOutcome {
  const NoPayday();
}

/// An income repeat is Due and not marked paid, so the next payday is not known yet.
class PaydayDue extends ForecastOutcome {
  const PaydayDue(this.title);
  final String title;
}

class PaydayForecast extends ForecastOutcome {
  const PaydayForecast({
    required this.spendableMinor,
    required this.payday,
    required this.paydayTitle,
    required this.days,
    required this.bills,
    required this.perDayMinor,
    required this.historyDays,
    required this.lowestMinor,
    required this.lowestDay,
  });
  final int spendableMinor;
  final String payday;
  final String paydayTitle;

  /// Days strictly between today and payday.
  final int days;
  final List<ForecastBill> bills;
  final int perDayMinor;

  /// The days normal daily spending was averaged over: up to [forecastWindowDays].
  final int historyDays;
  final int lowestMinor;
  final String lowestDay;

  int get billsMinor => bills.fold(0, (s, b) => s + b.baseMinor);
  int get dailyTotalMinor => perDayMinor * days;
}

/// [everydaySpendingMinor] is counted spending from [windowStart] to [today] without monthly
/// and yearly repeats; [firstEntryDay] is the person's first entry, or null with none.
ForecastOutcome forecastToPayday({
  required String today,
  required int spendableMinor,
  required List<ForecastRepeat> repeats,
  required int everydaySpendingMinor,
  required String? firstEntryDay,
});
```

The function, step by step:

1. `income = repeats.where((r) => r.isIncome && r.every != Every.daily)`. Empty → `NoPayday()`.
2. If any income repeat has `isDue(r.nextDay, today)` → `PaydayDue(title)` of the earliest Due one.
3. Payday = the minimum `nextDay` over `income` (all are now after today). Ties are broken by title, so the result is stable. `days = Day.between(today, payday) - 1`.
4. Bills: for each repeat with `!isIncome && !onSavings && (every == monthly || every == yearly)`:
   - if `isDue(nextDay, today)`: one `ForecastBill(day: today, due: true)`, then continue from `advance(nextDay, every, anchorDay)` so a later occurrence before payday still counts;
   - add every date from `occurrences(nextDay: <that start>, every, anchorDay, start: Day.add(today, 1), end: Day.add(payday, -1))`, each with `due: false`.

   Sort bills by day, then title.
5. `windowStart = Day.add(today, -(forecastWindowDays - 1))`.
   - If `firstEntryDay` is null or after today, `historyDays = 0`.
   - Otherwise `from = firstEntryDay.compareTo(windowStart) > 0 ? firstEntryDay : windowStart` (days are `YYYY-MM-DD` strings and compare correctly as text), and `historyDays = Day.between(from, today) + 1`, which is 1 to 92.
6. `perDayMinor = historyDays == 0 ? 0 : (2 * s + historyDays) ~/ (2 * historyDays)` with `s = max(0, everydaySpendingMinor)`. This is half-up rounding, the same as `BudgetView.safePerDayMinor`.
7. `lowestMinor = spendableMinor - billsMinor - perDayMinor * days`. `lowestDay = days > 0 ? Day.add(payday, -1) : today`. Spending and bills only ever lower the balance before payday, so the end of the run is the lowest point, and no day-by-day loop is needed.

### Data: `EntryRepository.watchEverydaySpending`

It follows the `watchTotals` pattern: a `customSelect` with `readsFrom`, so drift keeps it live. It returns `Stream<EverydaySpending>`, where `typedef EverydaySpending = ({int spentMinor, String? firstDay});` is declared in `entry_repository.dart` next to the class.

```sql
SELECT
  COALESCE(-SUM(CASE WHEN c.kind = 'expense'
                      AND (r.id IS NULL OR r.every IN ('daily', 'weekly'))
                     THEN p.base_minor END), 0) AS spent,
  (SELECT MIN(day) FROM entries WHERE deleted_at IS NULL) AS first_day
FROM postings p
JOIN entries e ON e.id = p.entry_id
LEFT JOIN categories c ON c.id = p.category_id
LEFT JOIN repeats r ON r.id = e.repeat_id
WHERE e.deleted_at IS NULL AND p.deleted_at IS NULL AND e.day BETWEEN ? AND ?
```

- Use plain positional `?` with `variables: [Variable.withString(start), Variable.withString(end)]`, as `watchTotals` does. The date range is in `WHERE`, so only the window's postings are read.
- `readsFrom: {db.postings, db.entries, db.categories, db.repeats}`.
- The repeats join deliberately does not filter `r.deleted_at`, so a stopped monthly repeat's past entries stay out of normal spending.
- "Needs a category" (`uncategorised`) is kind `expense` and counts, as the README says ("counts as spending meanwhile"). Untracked is kind `system` and does not count.
- With no matching rows, the aggregate without `GROUP BY` still returns one row with `spent = 0`. `first_day` comes from the subquery over all entries, not only the window's.
- Map the row with `(spentMinor: row.read<int>('spent'), firstDay: row.readNullable<String>('first_day'))`.

### Wiring: `app/lib/app/providers.dart`

```dart
/// Spending from start to end without monthly and yearly repeats, and the first entry's day.
final everydaySpendingProvider = StreamProvider.autoDispose.family<EverydaySpending, (String, String)>(
  (ref, range) => ref.watch(entryRepositoryProvider).watchEverydaySpending(range.$1, range.$2),
);

/// Home's "Lowest before payday". Null while its data is still loading.
final paydayForecastProvider = Provider.autoDispose<ForecastOutcome?>((ref) { ... });
```

`paydayForecastProvider`:

- `today = ref.watch(todayProvider)`
- `accounts = ref.watch(accountsProvider).value`, `repeats = ref.watch(repeatsProvider).value`, `setAside = ref.watch(setAsideProvider).value`, `everyday = ref.watch(everydaySpendingProvider((Day.add(today, -(forecastWindowDays - 1)), today))).value`. If any is null, return null (still loading).
- `nonSavings = accounts.where((a) => a.account.kind != AccountKind.savings.name).fold(0, (s, a) => s + a.baseMinor)`
- `spendable = min(nonSavings, ref.watch(freeToUseProvider))`. `freeToUseProvider` already exists in `providers.dart` as `totalBalanceProvider - setAside`, and `totalBalanceProvider` sums the same `accountsProvider` list. Reading `setAsideProvider` above is only for the loading check.
- `byId = {for (final a in accounts) a.id: a.account}`. This is the same non-archived list that spendable uses. A repeat whose account is not in `byId` (archived) is left out, so bills and spendable cover the same accounts.
- Each remaining `Repeat r` maps to `ForecastRepeat(title: r.title, isIncome: r.kind == 'income', every: Every.parse(r.every), nextDay: r.nextDay, anchorDay: r.anchorDay, baseMinor: toBase(r.amountMinor, byId[r.accountId]!.currency), onSavings: byId[r.accountId]!.kind == AccountKind.savings.name)`.
- Return `forecastToPayday(...)`.
- Imports to add: `dart:math` (`min`), `../core/day.dart`, `../core/money.dart`, `../domain/payday_forecast.dart`, `../domain/repeat_schedule.dart`. `account_repository.dart` and `entry_repository.dart` are already imported.

`repeatsProvider` already excludes stopped repeats (`deletedAt.isNull()`).

### Screen: `app/lib/features/home/payday_forecast.dart`

`class PaydayForecastCard extends ConsumerWidget` switches on `ref.watch(paydayForecastProvider)`:

- `null` or `NoPayday` → `SizedBox.shrink()`.
- `PaydayDue(title)` → `LedgerCard` without `onTap`: the label row, then `Text('$title is due. Mark it paid to see the forecast.', style: context.text.bodySmall)`.
- `PaydayForecast f` → `LedgerCard(onTap: () => showLedgerSheet(context, (_) => _ForecastSheet(f)))` holding:
  - a `Row`: `Expanded(Text('Lowest before payday', style: context.text.label))` and the estimate tag. The tag is a `Container` with `BorderRadius.circular(999)`, a 1px `c.borderSubtle` border and padding 8×2, around `Text('Estimate', style: context.text.caption.copyWith(color: c.textSecondary))`;
  - `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: MoneyText(f.lowestMinor, tone: f.lowestMinor < 0 ? MoneyTone.negative : MoneyTone.plain, style: context.text.amountLarge))`;
  - `Text('Around ${Day.short(f.lowestDay)}, after ${formatMoney(f.billsMinor, 'EUR')} of bills. ${f.paydayTitle} on ${Day.short(f.payday)}.', style: context.text.bodySmall)`. With no days and no bills, the first sentence is dropped.
  - Add no custom `Semantics` label. The `InkWell` in `LedgerCard` merges the label, tag, amount and caption into one tappable node, so the amount is read aloud.
- Padding: `const SizedBox(height: 12)` above, the same spacing as the Needs Review card on Home.

`_ForecastSheet` is a `SheetBody(title: 'How this estimate works', subtitle: 'An estimate from your spendable balance, the bills before payday and your normal daily spending.', children: [...])` with a private `_Line(label, minor, {strong})` row: an `Expanded` label in `context.text.body` and a `MoneyText` on the right, the same layout as `_BalanceCard.row`.

- `_Line('Spendable today', f.spendableMinor)`, and under it a `bodySmall` line: "Your accounts without Savings, less any goal money they hold."
- `_Line('Bills before ${Day.short(f.payday)}', -f.billsMinor)`
- `_Line('Normal daily spending, ${formatMoney(f.perDayMinor, 'EUR')} × ${f.days} days', -f.dailyTotalMinor)`
- `Divider()`, then `_Line(f.days > 0 ? 'Lowest, around ${Day.short(f.lowestDay)}' : 'Lowest, today', f.lowestMinor, strong: true)`
- A `bodySmall` note:
  - with `historyDays > 0`: "Normal daily spending is your average over ${f.historyDays == 1 ? 'the last day' : 'the last ${f.historyDays} days'}, without monthly and yearly repeats."
  - with 0: "There is no spending history yet, so daily spending counts as zero."
- `SectionHeader('${f.bills.length} ${f.bills.length == 1 ? 'bill' : 'bills'}')`, shown only with at least one bill, then one `_Line('${b.due ? 'Due' : Day.short(b.day)} · ${b.title}', -b.baseMinor)` per bill.
- `const SizedBox(height: 16)`, then `OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))`.

Only `context.colors` and `context.text` tokens are used, with no new colours or type styles. Every amount is a `MoneyText`, so the sign always goes with the colour.

### Home: `app/lib/features/home/home_screen.dart`

- `import 'payday_forecast.dart';`
- In `children`, after `const _BalanceCard(),` insert `const PaydayForecastCard(),`.
- Header comment: "Home answers, in order: how much do I have, will I make it to payday, what is due, how is this month going, where is my money going, and what happened lately."

## Steps

Branch `feat/payday-forecast` from `develop`. Run the commands from `app/`, with Flutter 3.47.9 (on this machine `E:\SDK\flutter-3.47.9\bin`).

1. **Rule.** Create `app/lib/domain/payday_forecast.dart` and `app/test/domain/payday_forecast_test.dart`.
   Verify: `flutter test test/domain/payday_forecast_test.dart`.
2. **Query.** In `entry_repository.dart`, declare `typedef EverydaySpending = ({int spentMinor, String? firstDay});` at top level above `class EntryRepository`, and add `Stream<EverydaySpending> watchEverydaySpending(String start, String end)` after `totals`. Add tests in `app/test/data/entry_repository_test.dart`.
   Verify: `flutter test test/data/entry_repository_test.dart`.
3. **Providers.** Add `everydaySpendingProvider` and `paydayForecastProvider` to `app/lib/app/providers.dart`.
   Verify: `dart analyze`.
4. **Card and sheet.** Create `app/lib/features/home/payday_forecast.dart` and insert the card in `home_screen.dart`. Add `app/test/ui/payday_forecast_test.dart`.
   Verify: `flutter test test/ui/payday_forecast_test.dart`.
5. **Small screens.** In `fillLedger` in `app/test/ui/small_screen_test.dart`, add an income repeat "Salary", 2,450.00, monthly, `nextDay: '2026-11-01'`, so the card is on Home in the overflow run.
   Verify: `flutter test test/ui/small_screen_test.dart`.
6. **Docs.** In `app/README.md` › What it does › Home, add one sentence: "Lowest before payday estimates the least you will have before the next salary, from your spendable balance, the bills due before it and your normal daily spending, and shows how it is worked out."
7. **Whole suite.** `dart analyze` and `flutter test`. Check that `git diff --stat develop` lists 11 files or fewer.

Files (10):

1. `app/lib/domain/payday_forecast.dart` (new)
2. `app/lib/data/repositories/entry_repository.dart`
3. `app/lib/app/providers.dart`
4. `app/lib/features/home/payday_forecast.dart` (new)
5. `app/lib/features/home/home_screen.dart`
6. `app/test/domain/payday_forecast_test.dart` (new)
7. `app/test/data/entry_repository_test.dart`
8. `app/test/ui/payday_forecast_test.dart` (new)
9. `app/test/ui/small_screen_test.dart`
10. `app/README.md`

## Tests

**`test/domain/payday_forecast_test.dart`** (today `2026-10-29`):

- No repeats → `NoPayday`. Only a daily income repeat → `NoPayday`.
- Monthly Salary next `2026-11-01` and yearly Bonus next `2026-12-15` → payday `2026-11-01`, title Salary, `days == 2`.
- Salary next `2026-10-28` → `PaydayDue('Salary')`. Salary next `2026-10-29` (today) → `PaydayDue`.
- Bills: Electricity monthly next `2026-10-29` (Due, €89.00), Netflix monthly next `2026-10-31` (€12.99), Rent monthly next `2026-11-01` (on payday, left out), a weekly Coffee expense repeat (left out), and an expense repeat on Savings (left out) → two bills totalling 10199, Electricity first with `due: true` and day `2026-10-29`.
- A monthly bill Due since `2026-09-30`, payday `2026-11-05` → counted once as Due and again on `2026-10-30`. (`advance('2026-09-30', monthly, 30)` = `2026-10-30`, which falls before payday.)
- Daily spending: 27600 over full history → 300. 27600 with the first entry on `2026-10-20` → 10 history days → 2760. 1 cent over 92 days → 0 (half up: (2 + 92) ~/ 184 = 0). Negative spending (net refunds) → 0. No first entry → 0 days, 0 per day.
- Lowest: spendable 110226, bills 10199, 300 × 2 → 99427 on `2026-10-31`. Payday tomorrow (`2026-10-30`) → `days == 0`, lowest = spendable − Due bills, `lowestDay == today`.
- Negative result: spendable 5000, bills 10199 → lowest is negative and is returned as it is.

**`test/data/entry_repository_test.dart`** (new `group('everyday spending')`):

- An expense of 8500 today, a 2000 refund on it, a transfer of 5000 and a balance check of −1200 → `spentMinor == 6500`.
- An entry paid through `repeats.markPaid` from a monthly repeat → left out. The same from a weekly repeat → counted. After `repeats.stop` on the monthly one, its paid entry is still left out.
- An expense dated before the window start → not counted, but `firstDay` is that day.
- No entries → `(spentMinor: 0, firstDay: null)`.
- `addLater` (Needs a category) counts.

**`test/ui/payday_forecast_test.dart`** (with `AppHarness`; Bank €1,000, Cash 200 KM):

- No repeats → Home has no "Lowest before payday".
- **Fixture.** Create these before `h.show()`, through `EntryRepository` / `RepeatRepository` and `h.read`:
  - a Salary income repeat (`categoryId: 'salary'`, Bank, 245000, monthly, next `2026-11-01`);
  - an Electricity expense repeat (`'electricity'`, Bank, 8900, monthly, next `2026-10-29`, so it is Due);
  - a €90 grocery expense today (`'groceries'`, Bank, 9000).

  Expected, with the arithmetic stated in a comment in the test:
  - spendable 100000 + 10226 − 9000 = 101226;
  - history is 1 day, so 9000 a day;
  - days are 30 and 31 Oct, so 2;
  - lowest = 101226 − 8900 − 9000 × 2 = 74326, shown as "€743.26".

  The card shows the R8 texts. Tapping it shows the R9 texts, and Close dismisses it.
- **Live (R10).** With Home still shown, add a €50 groceries expense today via `h.read`, then `h.settle()`:
  - spendable is 96226;
  - daily spending is 14000;
  - lowest = 96226 − 8900 − 28000 = 59326, shown as "€593.26".
- **Due salary (R3).** Salary next `2026-10-28`: the card reads "Salary is due. Mark it paid to see the forecast." and shows no "Estimate". Tap the Salary row's "Mark paid" in Due, then settle. Salary moves to 28 Nov and the card shows "Estimate" again. Target the button with `find.widgetWithText(OutlinedButton, 'Mark paid')` inside the Salary row. If marking paid opens an amount sheet (varying repeats only), this repeat does not vary, so none appears.

## Verification commands

From `app/`:

```bash
dart analyze
flutter test
```

and from the repository root:

```bash
git diff --stat develop
```

## Risks, migration, compatibility, security

- **No migration.** It reads existing tables only, and `schemaVersion` is unchanged.
- **Small history overstates the average.** With a few days of history, one big shop makes "normal daily spending" high, so the forecast leans pessimistic. The sheet states the history days, so the number explains itself. Decision D5.
- **A bill paid by hand, not through its repeat,** stays Due and still counts as a bill, so it is counted twice. This is the same behaviour Due already has, and the Due section prompts the person to fix it.
- **The `PaydayDue` state blocks the number** until Salary is marked paid. Typing the salary on the Add sheet with the same title already pays the repeat (README: "Typing a title that already repeats pays its next one"), so this resolves itself in normal use.
- **Any Due income repeat blocks the number,** not only salary. A Due yearly bonus or tenant rent also shows the waiting state until it is marked paid or skipped. This is accepted for now, since Due lists it directly below with its action. It goes away if Open question 1 is answered with a salary flag.
- **A bill overdue by more than one period counts once.** The repeat model shows one Due date at a time, and marking it paid moves it forward one period, so the forecast counts the Due occurrence today plus the later dates that fall before payday, not the periods in between. That matches what Due shows.
- **Performance.** One aggregate query over postings for 92 days plus a `MIN(day)`, both on indexed or small tables, at personal-ledger sizes. It is fine.
- **Privacy and security.** Nothing new is stored or sent. Hide amounts is not built in the app yet, so there is nothing to respect.
- **Tests on Home.** No existing test creates an income repeat, so the card appears only in the new and changed tests, and no existing `find.text` of an amount on Home is duplicated.

## Open questions

1. **Which income counts as payday.** The default is any non-daily income repeat, the earliest wins. If the person adds an income repeat that isn't salary, such as monthly rent from a tenant, it becomes "payday" too. A later "This is my salary" toggle on a repeat would need a schema change, so it is out of scope here.

## Decision log

- **D1. Spendable = min(non-savings accounts, Free to use).** The prototype drops Savings accounts, and the app also has goal earmarks ("Free to use"). Subtracting both would count goal money twice when it sits in Savings. Taking the minimum treats goal money as held in Savings first and touches the other accounts only for any excess. Credit cards stay in as negative, and Owed to me stays out, as in Total balance.
- **D2. Payday excludes daily income repeats, and includes weekly, monthly and yearly.** A daily income repeat would make payday always tomorrow. The prototype takes any income repeat.
- **D3. A Due income repeat shows a waiting state** instead of a number. Forecasting to the following salary would ignore money that is about to arrive and look alarming, and forecasting to today would be meaningless. This differs from the prototype, which skips Due income.
- **D4. Due bills count today** rather than tomorrow, as the prototype does. They are owed now, and dating them today keeps them counted when payday is tomorrow.
- **D5. The daily average divides by the history days, up to 92,** not always by 92 as the prototype does, so a new ledger isn't under-forecast. It means more noise early on, which the sheet discloses.
- **D6. Closed form instead of a day loop.** The balance only falls before payday, so the lowest is always at the end. The prototype's loop gives the same number.
- **D7. Bills on Savings accounts are left out,** matching D1's spendable balance.
- **D8. A new `features/home/payday_forecast.dart`** keeps `home_screen.dart` (481 lines) from growing, and gives the widget test a clear target.
- **D9 (round 1). Repeats on archived accounts are left out,** and the lookup uses `accountsProvider`, not `allAccountsProvider`. Spendable and bills then cover the same accounts. Accepted from the critic.
- **D10 (round 1). The query takes plain `?` placeholders, with the date range in `WHERE`,** following `watchTotals`. Accepted from the critic. The earlier CASE-only filter was correct, but it read every posting.
- **D11 (round 1). Rejected: "`freeToUseProvider` does not exist".** It does, in `app/lib/app/providers.dart` on `develop` ("Total balance minus what is set aside for savings goals."). The excerpt sent to the critic stopped just above it, and the next round includes it.
- **D12 (round 1). Rejected as already covered: "`EverydaySpending` not declared".** The Design already declared it. Step 2 now says exactly where, so it can't be missed.
- **D13 (round 1, non-blocking, kept as is).** The `PaydayDue` card has no Mark paid button of its own. The Due section directly below it has one, and adding one would need the `Repeat` row in the domain outcome.
- **D14 (round 2, self).** R8, R9 and R10 now quote the widget-test fixture's own figures (€743.26, €90.00 × 2 days, €593.26). Before, they quoted the domain example (€994.27, Netflix), which that fixture never produces.
- **D15 (round 2, self).** R10 now has a test. It adds a €50 expense while Home is shown.
- **D16 (round 2, self).** The `max()` on day strings is replaced by an explicit `compareTo`, because Dart's `max` takes numbers only.
- **D17 (round 2, self).** The custom `Semantics` label is dropped, so screen readers hear the amount through the `InkWell`'s merged semantics.
- **D18 (round 2, self).** Two edge cases are now under Risks: any Due income repeat blocks the number, and a bill overdue by several periods counts once.
- **D19 (round 2, self).** The history note says "the last day" for one day, not "the last 1 days".

## Review trail

| Round | Critic | Verdict | Issues |
|---|---|---|---|
| 1 | nvidia:nvidia/nemotron-3-ultra-550b-a55b | REVISE | 5 blocking, 5 non-blocking. 3 accepted (D9, D10, plus a clearer Step 2), 2 rejected with reasons (D11, D12) |
| 2 | self (fallback): the NVIDIA models were unavailable (nemotron returned empty twice; kimi-k2.6 and deepseek-v4.1-flash end of life on 15 and 16 Nov 2026) | APPROVE after fixes | 6 found and fixed (D14–D19) |
