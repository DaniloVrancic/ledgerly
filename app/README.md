# Ledgerly app

Ledgerly keeps track of one person's money, offline, on their own device. It records income and expenses in a few taps and shows where the money comes from, where it goes per category, and how that affects what is left. It also plans savings goals.

It is built with Flutter for Android and Windows. Nothing needs a network connection. Release builds on Android cannot reach the network at all.

## Run it

The project needs Flutter 3.47.9 (Dart 3.13). The Android app runs on Android 8.0 (API 26) or newer. The SDK must sit in a folder without spaces, because Flutter's native build hooks break on paths like `E:\Program Files\…`. On this machine it is installed at `E:\SDK\flutter-3.47.9`.

```bash
cd app
flutter pub get
flutter run -d windows          # or an Android phone or emulator
flutter test                    # all unit and widget tests
flutter build apk --release --split-per-abi
```

After changing `lib/data/database/tables.dart`, regenerate the database code:

```bash
dart run build_runner build
```

## What it does

| Area | What you can do |
|---|---|
| Add | An expense is Add, the amount, one category chip. Titles you typed before are suggested and bring back their subcategory and account, and the six most used titles sit at the top of the sheet. Under More details you can set a repeat, a merchant, your share of a shared payment, and a note. Later saves just the amount, to sort out afterwards. |
| Home | Total balance, with every account one tap away, and how much of it is free to use after savings goals. It also shows repeats that are due with Mark paid, this month's income, spending, net and savings rate, where the money went, and recent entries. |
| Entries | Grouped by day with each day's net. Search ignores Bosnian diacritics and also finds amounts. Filter by type, category or account, and swipe to delete with Undo. In an entry's details every field saves itself, and you can duplicate it, record a refund, record a repayment, or make it repeat. |
| Calendar | On Entries, switch List to Calendar. Each day shows its net, a shade for how much was spent compared with the month's other days, and markers for income, paid and due repeats, planned repeats and high-spending days. A day opens its totals, top category, repeats and entries, and Add on this day. Year shows twelve months shaded day by day; a month opens its grid. |
| Insights | Any month compared with the one before and with the usual level: income, spending, net, savings rate, spending per category with its share of income, income per source, a six-month chart, and a few plain observations. Every figure opens its entries. |
| Repeats | Daily, weekly, monthly or yearly. A repeat turns Due on its date and waits until you mark it paid or skip it. When the amount varies, it asks for this time's amount. Typing a title that already repeats pays its next one. Shows the monthly and yearly cost of subscriptions. |
| Budgets | A monthly or weekly limit for all spending, a category or a subcategory, in EUR. Monthly budgets follow your month start, and weeks run Monday to Sunday. Each shows what is spent and left, a marker for how far the period has gone, how much is safe to spend per day, and the last six periods. It warns at 80% and shows when it goes over. Home shows the budget bar on its category rows and the one budget that most needs attention. |
| Savings | A goal has a target and an optional date. Setting money aside keeps it in your account but marks it as not free to spend. Each goal shows what to set aside per month, whether you are on track, and when you will get there at your recent pace. Finishing a goal frees its money for the purchase. |
| Categories | Add your own categories and subcategories: name, icon from the line set or your own picture, colour, and which accounts offer them. You can archive them, or delete them by moving their entries to another category. Also reachable from All on the Add sheet. |
| Accounts | Balances, a balance check that saves any difference as Untracked, and a nudge when Cash has not been checked for two weeks. |
| Statement import | Settings › Import bank statement. Choose a CSV export from your bank (comma, semicolon or tab, UTF-8 or Windows-1250), check the guessed date, amount and description columns, and choose the account. Ledgerly then shows what is already recorded (same amount within 3 days), what is missing, likely duplicates and unreadable lines. Only ticked rows are added, in one step with Undo. Without a category, money out waits in Needs Review; money in needs an income category first. |
| Export and import | Settings › Export all data writes one `.ledgerly` file: a ZIP with an SQLite snapshot, every table as CSV, category pictures and a manifest with SHA-256 hashes. A password is optional and uses the open age format, so `age -d` opens it too. The file is read back and checked before it is saved. Settings › Import a Ledgerly file (also on the first screen) checks the file, shows its date and counts, asks for the password if there is one, and replaces everything only after you type REPLACE, saving a safety copy first. |
| App lock | Off by default. Settings › App lock turns it on with a 4 to 8 digit PIN, stored only as a salted PBKDF2 hash. Ledgerly locks when it opens and after it has been away longer than the delay (immediately, 1, 5 or 15 minutes; 5 by default). On Android the fingerprint or face unlock can be used too, and while the lock is on the app's content is hidden in recent apps and screenshots are blocked. After 5 wrong PINs it waits 30 seconds, doubling up to 5 minutes. The lock's settings are kept outside the database, so a restore or import never changes them. |
| Backups | Every 3 days, the newest 3 kept, the newest replacing the oldest. Restore saves the current data as a safety copy first. Settings › Backups › Choose a folder puts them in a folder you pick (Android's folder picker or the Windows folder dialog), such as an SD card or a folder a sync app copies to your computer; the current backups are copied there. If that folder can't be reached, backups go to Ledgerly's own folder and Home and Backups say so. |

## The money rules

They live in `lib/domain/postings.dart` and are covered by tests.

- Money is stored as integer minor units, never as decimals. Each posting keeps its own currency and its EUR value, frozen when it is recorded. BAM is pegged at 1 EUR = 1.95583 KM.
- Each entry becomes postings. Income and spending only ever come from postings with a category, so a transfer can never count.
- Refunds go back on the expense's category and lower spending there. They are never income.
- My share: only your part of a shared payment counts as spending. The rest is "Owed to me" until it is repaid, and the repayment is not income.
- A balance check saves the difference on Untracked, which reports leave out.
- Balances are never stored. They are always calculated from the postings.
- The payday forecast (`lib/domain/payday_forecast.dart`) estimates the lowest balance before the next income repeat, which is payday:
  - It starts from what is spendable today: the accounts without Savings, less any goal money they hold.
  - It takes off the monthly and yearly expense repeats due before payday.
  - It takes off normal daily spending for each day until then: the average of the last 92 days, without monthly and yearly repeats so bills are not counted twice.
  - While an income repeat is Due and not marked paid, it waits instead of guessing.

## How the code is organised

```text
lib/
  main.dart               Opens the database, sets up backups, starts the app
  app/                    Wiring: providers, navigation, the shell around the tabs, backups state
  core/                   Small helpers with no app knowledge: money, days, months, ids, text search
  domain/                 The rules, as plain Dart: postings, repeats, savings plans, title memory, insights
  data/
    database/             Drift tables, the database, default categories
    repositories/         The only code that reads or writes the database
    backup/               The 3-day, 3-file backup rotation
  features/<area>/        One folder per area of the app, holding its screens and sheets
  ui/                     The design system in Flutter: colours, type, icons, shared widgets
test/
  core/ domain/           Rules without a database
  data/                   Repositories and backups against an in-memory database
  ui/                     The real app driven through its screens
```

A screen reads data from a provider in `app/providers.dart` and changes it through a repository. Drift's live queries then update every screen that shows that data. Every change a person can make returns an Undo.

The colours, type scale and icons come from `design-system/` at the root of the repository. `lib/ui/icons/icon_paths.dart` is generated from `design-system/ledgerly.js`.

## Getting ready for sync

Nothing syncs today, but the data is shaped so a server can be added later without moving anything:

- Every record has a UUIDv7 id, so records made on two devices never collide.
- Every record has `createdAt`, `updatedAt` and `deletedAt`. Deletes are soft, so a sync can send deletions too.
- To add sync, write a service that sends rows whose `updatedAt` is newer than the last sync, receives the server's changes, and applies them through the repositories. The screens do not need to change.
- Device-only preferences live in the `settings` table, which is not meant to sync.

## Where the data lives

| | Database | Backups |
|---|---|---|
| Android | The app's private folder | `Android/data/app.ledgerly.ledgerly/files/backups` |
| Windows | `%APPDATA%\app.ledgerly\ledgerly\ledgerly.sqlite` | `Documents\Ledgerly\Backups` |

Each backup is a complete SQLite file. Uninstalling the app on Android removes its own backup folder too, so choose a folder of your own under Settings › Backups, or copy a backup somewhere else now and then.

## On phones

Ledgerly draws edge to edge under transparent status and navigation bars, whose icons follow light and dark. Phones stay in portrait; tablets and desktop windows turn freely. `test/ui/small_screen_test.dart` opens the main screens on a 360 x 640 phone at 100% and 150% text and fails on any layout overflow. The calendar grid and the bottom bar keep their figures and labels near their size (the calendar's full figures are in each day's screen-reader label and day sheet); everything else grows with the system text size. Android shows a splash in the icon's green with its artwork (the system splash on Android 12 and later), and back gestures preview the page underneath (predictive back).

## App icon

The icon comes from `design-system/brand/app-icon.svg`. On Android it is an adaptive vector icon in `android/app/src/main/res/drawable/ic_launcher_*.xml`, converted by hand from the SVG and scaled into the safe zone, with a one-colour version for themed icons. If the SVG changes, change those files to match.

On Windows, `windows/runner/resources/app_icon.ico` is rendered from the same SVG at 16 to 256 px, and `assets/brand/app-icon.svg` (shown on the first screen) is refreshed with it:

```bash
flutter test tool/render_icons.dart
```

## Not built yet

- The notebook, reports and monthly close.
- Splitting one payment across several categories, and purchases in a third currency. The postings model supports both; only the screens are missing.
- The home-screen widget and a read-only desktop copy.
