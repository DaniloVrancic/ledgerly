# Ledgerly: remaining features, in 17 pull requests

> **Implementation brief.**
> - **What to build:** budgets, a calendar, bank statement CSV import, a `.ledgerly` export / import file with an optional age password, a backup folder you choose, an app lock (PIN everywhere, fingerprint on Android), the final app icon and a mobile polish pass.
> - **How to ship it:** as 17 sequential PRs against `main` of `github.com/DaniloVrancic/ledgerly`. Each PR changes **at most 11 files**, generated, lock and registrant files included.
> - **Constraints:** offline only; money rules in `lib/domain`; database access only through `lib/data/repositories`; design-system tokens only; never commit real data.
> - **How to work:** follow the Steps in order, one branch per PR, and run the Verification commands before each PR. Don't commit anything outside the PR's listed files.

| PR | Branch | What | Files |
|---|---|---|---|
| 1 | `feat/budgets-core` | Budgets table (schema v2), rules, repository | 9 |
| 2 | `feat/budgets-screens` | Budgets screens, Home bars, More entry | 8 |
| 3 | `feat/calendar-month` | Month calendar, day sheet, Add on a day | 10 |
| 4 | `feat/calendar-year` | Year heatmap, calendar UI test | 6 |
| 5 | `feat/statement-parsing` | CSV reader, column mapping, matching, cp1250 | 8 |
| 6 | `feat/statement-import` | Import flow with `file_picker` | ≤ 11 |
| 7 | `refactor/backup-store` | Backups go through a `BackupStore` | 7 |
| 8 | `feat/backup-folder` | Your own backup folder (Android SAF, Windows) | ≤ 11 |
| 9 | `feat/ledgerly-file` | `.ledgerly` ZIP format, verify, CSV tables | 7 |
| 10 | `feat/age-encryption` | age passphrase encryption | 6 |
| 11 | `feat/export-import` | Export and import screens, replace data | 9 |
| 12 | `feat/app-lock-pin` | PIN lock on every platform | 10 |
| 13 | `feat/app-lock-biometrics` | Fingerprint, hidden recents | 10 |
| 14 | `feat/app-icon-android` | Adaptive vector icon, minSdk 26 | 11 |
| 15 | `feat/app-icon-windows` | ICO, brand asset, "Ledgerly" names | 8 |
| 16 | `feat/mobile-system-ui` | Splash, edge-to-edge, predictive back | 9 |
| 17 | `fix/small-screens` | No overflow at 360×640 and 150% text | ≤ 11 |

## Status

approved

## Goal

Finish the features `app/README.md` lists as not built yet, in the order a person using the app every day benefits most:

- budgets
- a financial calendar
- bank statement CSV import
- a `.ledgerly` export file with an optional password, and importing it
- choosing your own backup folder
- an app lock with a PIN everywhere and the fingerprint on phones
- the final app icon
- a polish pass so the app looks clean on phones

Each pull request is one logical increment that builds, passes its tests and changes **at most 11 files**.

## Non-goals

- The notebook, day notes, reports (PDF), monthly close, the home-screen widget and a read-only desktop copy. They are separate later work.
- Splitting one payment across categories, and a third currency.
- Database encryption (SQLCipher). App lock hides the app; the export password protects the exported file. `docs/architecture.md` postpones database encryption.
- Merging an imported `.ledgerly` file with existing data. Import replaces everything, as the brief says.
- Rollover budgets, custom budget periods and a weekly calendar view, which the brief excludes.
- iOS, macOS, Linux and web. The project only has `android/` and `windows/`.
- Any network access. Every new package must work fully offline.

## Ground rules for every PR

1. **Branching.** Branch from `main` of `github.com/DaniloVrancic/ledgerly`, which is private. Name the branch `feat/<pr-slug>` and open a PR against `main`. Merge before starting the next PR that depends on it. Dependencies are listed per PR.
2. **File budget.** "Files changed" means everything in `git diff --stat main`, including:
   - generated `app_database.g.dart`;
   - `pubspec.lock`;
   - `windows/flutter/generated_plugin_registrant.cc` and `windows/flutter/generated_plugins.cmake`;
   - binary files and deleted files.

   Each PR lists its files. If an extra file turns out to be needed and the count would reach 12, move a test-only or screen-only part into the next PR. Never exceed 11.
3. **Adding a package.** Use `flutter pub add <name>` (or `--dev`) so the latest version compatible with Flutter 3.47.9 is chosen and locked. Then:
   - add a one-line comment above it in `pubspec.yaml` saying why it is there, as the existing entries do;
   - confirm it has no network code paths in what we call;
   - confirm it supports Android and Windows (or that the code guards the platform).
4. **Schema changes.**
   - Bump `schemaVersion` in `app/lib/data/database/app_database.dart`.
   - Add an `if (from < N)` step in `onUpgrade`, and create the same thing in `onCreate` (which calls `m.createAll()`).
   - Run `dart run build_runner build` in `app/`.
   - Add a migration test that opens a version N-1 database and upgrades it (see PR 1).
5. **Layers** (from `CLAUDE.md`):
   - Money rules stay plain Dart in `app/lib/domain/`, with no Flutter or drift imports.
   - Database access only goes through `app/lib/data/repositories/`.
   - Screens live in `app/lib/features/<feature>/`.
   - Shared widgets live in `app/lib/ui/widgets/`.
6. **Look and feel.** Use only the design system's tokens via `context.colors` and `context.text` (`app/lib/ui/theme/ledgerly_colors.dart`), and icons from `LedgerIcon` (the generated set in `app/lib/ui/icons/icon_paths.dart`). Pair colour with a sign, icon or label. Touch targets are at least 44px. The phone layout is the main one.
7. **Money.** Budget figures are EUR minor units from posting `baseMinor`, the same source as Home and Insights, so every screen agrees. Transfers and balance checks never count. Refunds lower spending.
8. **Tests.** Every PR keeps `dart analyze` clean and `flutter test` green, and adds tests for what it adds.
9. **Docs.** When a PR finishes a feature, update `app/README.md` "Features" and "Not built yet" in that PR. Its file count includes the README.

## Requirements and acceptance criteria

| # | Requirement | Observable acceptance |
|---|---|---|
| R1 | Budgets: overall, category or subcategory, monthly (following month start) or weekly (Mon–Sun), in EUR | Create "Food, €400 monthly". After a €100 Food expense the budget shows €100 spent, €300 left, 25%. A transfer changes nothing. A €20 Food refund makes it €80. |
| R2 | Budget states: warning at 80%, over at 100% | €320 of €400 shows the amber warning label and icon. €410 shows "€10 over" in the negative colour with an icon. |
| R3 | Safe to spend per day and today's pace marker | On 15 Oct of a 31-day October, €200 of €400 used shows "€11.76 a day for 17 days" (20000 cents / 17 = 1176.47, rounded half up to 1176) and a pace marker at 15/31 of the bar. |
| R4 | Budget history: the last 6 periods | The details screen lists 6 periods, each with spent / limit. |
| R5 | Budgets on Home | A top-category row on Home with a budget shows its bar. The budget furthest over 80% appears as one "needs attention" row. |
| R6 | Calendar month grid, from the Entries tab List / Calendar switch | Each past day shows its net in EUR, and a heat shade for spending backed by the number. Markers for income, repeats (paid or due) and high-spending days. Future days show planned repeats. A legend explains the markers. |
| R7 | Day details sheet | Tapping a day shows spent, income, net, the top category, that day's entries, and "Add on this day", which opens the Add sheet dated that day. |
| R8 | Year view | Switching to Year shows a 12-month grid of days shaded by spending, with a legend. Tapping a day opens its details. |
| R9 | Bank statement CSV import | Pick a `.csv` file, then map the date, amount (or debit and credit) and description columns. The guessed mapping is pre-filled and a preview of 5 rows is shown. Choose the account. |
| R10 | Statement review | Rows are grouped as **Matched** (an existing entry on that account, same amount, within ±3 days), **To add**, and **Likely duplicates** (same date, amount and description twice in the file). Only ticked "To add" rows are added, in one transaction. Titles that title memory knows get their category; the rest go to Needs Review. Importing the same file again adds nothing. |
| R11 | Export all data to a `.ledgerly` file, optionally with a password | The file is a ZIP with `manifest.json`, `data/ledgerly.sqlite`, `data/*.csv`, `attachments/` and `settings.json`. With a password, the whole ZIP is wrapped in the age format (scrypt passphrase), so `age -d` opens it. Before saving, the app reads the bytes back and shows "N entries, M accounts, verified". A password warning says it can't be recovered. |
| R12 | Import a `.ledgerly` file | A preview shows date, app version and counts, and asks for the password if needed. The person types REPLACE to confirm. A safety copy is taken and its location shown. A damaged file, a wrong password or a newer-version file each give a plain message, and nothing changes. Available in Settings and on the first-launch screen. |
| R13 | Choose your own backup folder | Settings › Backups › "Backup folder" opens the system folder picker (Android Storage Access Framework, Windows folder dialog). Backups then go there and keep the 3-file / 3-day rule. Access survives restarts. If access is lost, backups fall back to the default folder and the screen says so. |
| R14 | App lock with a PIN on every platform | Off by default. Turning it on asks for a 4–8 digit PIN twice. The app locks on start and after being in the background longer than the delay (Immediately, 1, 5 or 15 minutes; 5 by default). After 5 wrong PINs it waits 30 s, doubling up to 5 min. The PIN is stored only as a salted PBKDF2 hash. |
| R15 | Fingerprint on mobile | On Android with an enrolled fingerprint or face unlock, "Unlock with fingerprint" can be turned on. The lock screen offers it first, and the PIN always works as a fallback. While the lock is on, the app content is hidden in the recent-apps screen. |
| R16 | Final app icon | The Android launcher shows the design-system icon (`design-system/brand/app-icon.svg`) as an adaptive icon, with a monochrome version for Android 13 themed icons. Windows shows it in the taskbar and the exe. The window title and product name are "Ledgerly". |
| R17 | Clean on mobile | Branded splash on Android 12+ and older versions. Edge-to-edge with transparent system bars whose icons follow light and dark. Portrait on phones. Predictive back. No overflow on a 360×640 screen at 100% and 150% text size across the main screens. |

## Design overview

### Budgets (PR 1–2)

- **Table `Budgets`** (with `SyncColumns`):
  - `categoryId` text, nullable, references `Categories` (null means overall);
  - `limitMinor` int (EUR);
  - `every` text, `'monthly'` or `'weekly'`.

  One active budget per `(categoryId, every)` is enforced in the repository (a soft-deleted row doesn't count). This is schema version 2.
- **`app/lib/core/period.dart`**: add `Period weekOf(String day)` (Monday to Sunday; label "26 Oct to 1 Nov") and `Period previousWeek(Period p)`.
- **`app/lib/domain/budget_plan.dart`** (pure):
  ```dart
  enum BudgetState { normal, warning, over }
  class BudgetView {
    final int limitMinor, spentMinor; final Period period;
    int get leftMinor;           // limit - spent, may be negative
    double get ratio;            // spent / limit
    BudgetState get state;       // >= 1.0 over, >= 0.8 warning
    double pace;                 // period.paceOn(today)
    int daysLeft;                // days from today to period.end inclusive, at least 1
    int get safePerDayMinor;     // max(0, left) / daysLeft rounded half up: (2*l + d) ~/ (2*d)
  }
  BudgetView viewBudget({required int limitMinor, required int spentMinor, required Period period, required String today});
  ```
- **`app/lib/data/repositories/budget_repository.dart`**:
  - `watchBudgets()`;
  - `create({String? categoryId, required int limitMinor, required String every})`, which throws `BudgetException` on a duplicate or a limit ≤ 0;
  - `update(id, {limitMinor})`;
  - `delete(id)` returns `Undo`.
  - `Stream<Map<String, int>> watchSpending(String start, String end)` runs one SQL query:
    - `SELECT c.id, c.parent_id, -SUM(p.base_minor)`, joined like `EntryRepository.watchTotals`, for `c.kind = 'expense'`;
    - it returns spent per leaf id, plus a rolled-up value for each parent id and a key `''` for overall.

    Overall equals `PeriodTotals.spendingMinor` (it includes "Needs a category"), so Home, Insights and Budgets agree.
- **Providers** (`app/lib/app/providers.dart`):
  - `budgetRepositoryProvider`;
  - `budgetsProvider`;
  - `budgetViewsProvider`, which combines the budgets, `currentPeriodProvider` or `weekOf(today)`, and `watchSpending` for each distinct period. It returns a list of `(Budget, BudgetView)`.
- **Screens** (`app/lib/features/budgets/`):
  - `budgets_screen.dart`: the overall budget on top, then categories, each row being a `LedgerBar` with spent / limit, the state label and the pace tick.
  - `budget_form.dart`: a sheet with the scope (Overall / Category / Subcategory via `pickCategory`), Monthly / Weekly, and the limit via `AmountKeypad`.
  - `budget_screen.dart`: details with safe-per-day, the pace, 6-period history bars, "See entries" (opens `FilteredEntriesScreen` with an `EntryQuery` for the period and category), Edit and Delete with Undo.
  - Entry points: a More item "Budgets", the Home `_TopCategories` bar, and a needs-attention row on Home.

### Calendar (PR 3–4)

- **`app/lib/domain/calendar_month.dart`** (pure):
  - `List<String> monthGrid(int year, int month)` returns full weeks starting Monday, including days outside the month.
  - `int heatStep(int spentMinor, List<int> monthSpends)` returns 0–4, using quartiles of the month's non-zero spending days, so a shade is relative and always paired with the number. With no spending days in the month, every step is 0; with only one spending day, that day is step 2.
  - `bool isHighSpending(int spent, List<int> monthSpends)` is true at the top step and when spending is ≥ 2× the median.
- **`EntryRepository.watchDayTotals(String start, String end)`** returns `Stream<Map<String, DayTotals>>`. `DayTotals { spentMinor, incomeMinor, count, topCategoryId, hasRepeat }` comes from one grouped SQL query on postings with a category of kind expense or income, plus `entries.repeat_id IS NOT NULL` for `hasRepeat`. The class goes in `entry_view.dart`, next to the other read models.
- **Repeat markers** come from three sources, each with its own icon in the legend:
  - **Paid:** a past day with a paid repeat entry has `DayTotals.hasRepeat`.
  - **Due:** a repeat whose `nextDay <= today` marks its `nextDay` in the amber "due" style, from `dueRepeatsProvider`.
  - **Planned:** future days use the existing `occurrences()` from `domain/repeat_schedule.dart` over `repeatsProvider`, leaving out daily repeats (as the prototype does).
- **Screens** (`app/lib/features/calendar/`):
  - `month_calendar.dart`: month navigation, the 7-column grid, cells with the day number, a compact net (for example "−42" without cents; the full amount in semantics), the heat background from the expense tint tokens, marker dots with icons, and a legend row.
  - `day_sheet.dart`: `showLedgerSheet` with totals, the top category, `EntryList(embedded: true, query: EntryQuery(start: day, end: day))`, and "Add on this day".
  - `year_heatmap.dart` (PR 4): 12 small month blocks, a legend, and tap to open the day sheet.
- **`openAddEntry`** gains `String? day`, passed into the sheet's initial date. The sheet already has date state and a date pill.
- **`EntriesScreen`** gets a `SegmentedButton` List / Calendar in its app bar. Calendar shows `MonthCalendar`, which has its own Month / Year switch in PR 4.

### CSV import (PR 5–6)

- **`app/lib/domain/statement/csv_reader.dart`**: an RFC 4180 parser for quoted fields, `""` escapes and CRLF. It detects the delimiter (`,`, `;` or tab) by consistent column counts over the first 10 lines, and strips a UTF-8 BOM. Hand-written, as `docs/architecture.md` decided.
- **`app/lib/domain/statement/statement_mapping.dart`**:
  - `StatementMapping { int dateCol; int? amountCol; int? debitCol; int? creditCol; int descriptionCol; String dateFormat; bool decimalComma; bool hasHeader; }`
  - `StatementMapping guessMapping(List<List<String>> rows)`: header keywords in English and local languages (date/datum, amount/iznos, description/opis/purpose/svrha, debit/duguje/isplata, credit/potražuje/uplata), date formats `yyyy-MM-dd`, `dd.MM.yyyy`, `dd/MM/yyyy`, `MM/dd/yyyy`, and the decimal comma.
  - `List<StatementRow> applyMapping(rows, mapping)` gives `StatementRow { day, amountMinor (signed, negative = money out), description, sourceLine }`. Rows that can't be parsed are kept with an error message.
- **`app/lib/domain/statement/statement_match.dart`**:
  ```dart
  enum RowStatus { matched, toAdd, duplicate, invalid }
  class ExistingEntry { String id; String day; int amountMinor; }   // signed, account currency
  List<ReviewRow> reviewStatement(List<StatementRow> rows, List<ExistingEntry> existing, {int dayWindow = 3});
  ```
  - Each existing entry matches at most one row: the closest day first, then the first in the file.
  - Rows identical in day, amount and description after the first are marked as duplicates.
- **`EntryRepository.signedAmountsOnAccount(accountId, start, end)`** returns `List<ExistingEntry>`: every posting on that account for entries in range that aren't deleted, transfers and balance checks included. A bank statement lists transfers too, so matching them stops an already-recorded transfer from being imported again as an expense (D13).
- **`EntryRepository.importStatement(accountId, List<ImportDraft>)`** inserts them all in one `db.transaction`. `ImportDraft { day, amountMinor (signed), title, String? categoryId }`. Each draft becomes:
  - `addEntry` (expense for money out, income for money in) when `categoryId` is set. The review step fills it from `exactTitle` in title memory when the kind matches the sign, or from the income picker (D7).
  - Otherwise `addLater`, for money out only.

  Rows of money in without a category can't be ticked (D7). It returns `(int added, Undo)`.
- **The file is picked** with `file_picker` (`FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true)`). The bytes are decoded as UTF-8 (`utf8.decode`, with `allowMalformed: false`). When that fails, they fall back to Windows-1250, which many local banks use for č, ć, đ, š and ž. Dart has no Windows-1250 codec, so `app/lib/domain/statement/cp1250.dart` holds a 128-entry table for bytes 0x80–0xFF and a `String decodeCp1250(List<int>)` function. No package is needed.
- **Screens** (`app/lib/features/statement_import/`):
  - `statement_import_screen.dart` is a 3-step flow: pick → map → review.
  - `mapping_step.dart`: column dropdowns, date format, decimal comma, header toggle, account, and a 5-row preview.
  - `review_step.dart`: three groups with counts, checkboxes on "To add", and an "Add N entries" button showing the result with Undo (the Undo deletes the imported entries).
  - The entry point is Settings › Your data › "Import bank statement".

### Backup store and chosen folder (PR 7–8)

- **`app/lib/data/backup/backup_store.dart`**:
  ```dart
  abstract interface class BackupStore {
    String get displayName;                          // "Documents\Ledgerly\Backups" or the folder name
    Future<List<StoredBackup>> list();              // name, size, modified
    Future<void> put(String name, File source);     // copy in, replacing a same-named file
    Future<void> remove(String name);
    Future<File> fetch(String name, Directory temp); // copy out for restore or import
  }
  class LocalFolderStore implements BackupStore { LocalFolderStore(Directory folder); }
  ```
- **`BackupService`** changes:
  - It takes a `BackupStore` and a `Directory workDir`, which is the app cache.
  - `backUpNow()` writes the snapshot to `workDir/<name>.part`, checks it is not empty, then calls `store.put(name, file)`, then deletes the temp file.
  - It then removes the oldest beyond `keep`, by the names that match `_name`.
  - The 3-day / 3-file rule, the file names and "a failed backup never costs an existing one" stay the same.
  - `list()` becomes async. `BackupController` and `BackupsScreen` are updated to match.
- **`main.dart`** `_restore` uses `store.fetch` to get a local file, then does what it does today.
- **Android chosen folder** (PR 8):
  - **Native side**: a Kotlin `MethodChannel('ledgerly/folder')` in `MainActivity.kt`:
    - `pick()` launches `ACTION_OPEN_DOCUMENT_TREE` (`startActivityForResult` plus `onActivityResult`). It calls `contentResolver.takePersistableUriPermission(uri, FLAG_GRANT_READ_URI_PERMISSION or FLAG_GRANT_WRITE_URI_PERMISSION)`, releases the previously chosen URI's permission, and returns `{uri, name}`.
    - `canAccess(uri)`: true when `contentResolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission && it.isWritePermission }` **and** querying `DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri))` for `COLUMN_DISPLAY_NAME` returns a row (the folder still exists).
    - `list(uri)`: query `buildChildDocumentsUriUsingTree(uri, treeDocId)` for `COLUMN_DOCUMENT_ID`, `COLUMN_DISPLAY_NAME`, `COLUMN_SIZE` and `COLUMN_LAST_MODIFIED`.
    - `put(uri, name, path)`: if a child named `name` exists, open it with `openOutputStream(childUri, "wt")`; otherwise `DocumentsContract.createDocument(resolver, treeDocUri, "application/octet-stream", name)`. Then stream the file in.
    - `remove(uri, name)`: `DocumentsContract.deleteDocument`.
    - `fetch(uri, name, path)`: `openInputStream`, written to `path`.
    - No new Gradle dependency (no `androidx.documentfile`). Every call runs on one background executor and replies on the main thread.
  - **Dart side**: `app/lib/data/backup/android_folder_store.dart` implements `BackupStore` over the channel.
- **Windows chosen folder**: `FilePicker.platform.getDirectoryPath()`, then `LocalFolderStore(Directory(path))`.
- **Setting**: `SettingKeys.backupFolder` holds JSON `{"kind":"tree"|"path","value":...,"name":...}`. `connection.dart` gains `Future<BackupStore> backupStore(SettingsRepository)`, which returns the chosen store if `canAccess`, else the default `LocalFolderStore(backupFolder())`, and reports the fallback.
- **Changing the folder** re-creates the `BackupService` through a callback provider, as restore does in `main.dart` (bump the generation). Existing backups aren't moved; the screen offers "Copy the 3 current backups there".

### `.ledgerly` data file (PR 9–11)

- **ZIP** with `archive` (pure Dart). Layout as in `docs/architecture.md` §5:
  - `manifest.json`: `{format: 1, schemaVersion, appVersion, createdAt, counts: {entries, accounts, categories, repeats, goals, budgets}, sha256: {path: hex}}`;
  - `data/ledgerly.sqlite`, from `db.snapshotTo`;
  - `data/<table>.csv` for every synced table, all columns, ISO dates, minor units;
  - `attachments/` holds files from the app support `category_images` folder, named as they are on disk (the path stored in `Categories.imagePath` is rewritten relative on export and absolute on import);
  - `settings.json` holds the Settings rows, except `backup_folder`.
- **`app/lib/data/export/ledgerly_file.dart`**:
  - `Future<Uint8List> buildLedgerlyFile(AppDatabase db, {required Directory attachments, required Directory workDir})`
  - `Future<LedgerlyPreview> readLedgerlyFile(Uint8List bytes, {required Directory workDir})`. It verifies every SHA-256, runs `PRAGMA integrity_check` and `PRAGMA user_version` on the extracted SQLite. It opens it with `package:sqlite3` (`sqlite3.open(path, mode: OpenMode.readOnly)`, a direct dependency from PR 9 and already in the lock file through drift), never with `AppDatabase`, which would migrate it. compares counts with the manifest, and refuses `schemaVersion > current`. It returns `LedgerlyPreview { createdAt, appVersion, counts, extractedDb, extractedAttachments, settings }`, or throws `LedgerlyFileException(kind: damaged|newerVersion|wrongPassword|notLedgerly)`.
- **`app/lib/data/export/csv_tables.dart`**: writes the table CSVs, with RFC 4180 quoting.
- **`app/lib/data/export/age_passphrase.dart`** (PR 10) implements the age v1 format for the scrypt recipient only, with `pointycastle`:
  - **header**: `age-encryption.org/v1`, a `-> scrypt <salt b64> <logN>` stanza, a file key wrapped with ChaCha20-Poly1305 using the scrypt key over `"age-encryption.org/v1/scrypt" + salt`, and a header MAC with HMAC-SHA256, the key coming from HKDF(file key, "header");
  - **payload**: a 16-byte nonce, then HKDF(file key, nonce, "payload") gives the key, then STREAM over 64 KiB ChaCha20-Poly1305 chunks with a last-chunk flag;
  - **API**: `Uint8List ageEncrypt(Uint8List plain, String passphrase, {int logN = 16})` and `Uint8List ageDecrypt(Uint8List file, String passphrase)`. It throws `AgeException.wrongPassphrase` / `.malformed` / `.workFactorTooHigh`. `ageDecrypt` parses the stanza and rejects logN > 20 **before** running scrypt. Both run in `Isolate.run`.
  - **Detection**: a file starting with `age-encryption.org/v1\n` is encrypted, and one starting with `PK\x03\x04` is a plain ZIP.
- **`app/lib/features/data/`** (PR 11):
  - `export_screen.dart`: an include-pictures switch (on), an optional password with a confirm field and a warning, an estimated size, and "Export". It builds, encrypts, then **verifies by reading the bytes back** (decrypt plus `readLedgerlyFile`), then saves with `FilePicker.platform.saveFile(fileName: 'ledgerly-YYYYMMDD.ledgerly', bytes: ...)`. On Android this uses the system "create document" and writes the bytes. On Windows `saveFile` only returns the chosen path, so the screen writes the bytes there itself (`File(path).writeAsBytes(bytes, flush: true)`) and then reads that file back for the verification. All of this sits behind a small `FileSaver` provider in `export_screen.dart`, so the UI test can fake it. It shows "2,418 entries, 6 accounts, verified".
  - `import_screen.dart`: pick, ask for the password if the file is age, a preview card, typed "REPLACE", then a call to `replaceDataProvider`.
- **`main.dart`**:
  - generalise `_restore(BackupFile)` into `_replaceWith(File sqlite, {Directory? attachments, Map<String, String>? settings})`, exposed as `replaceDataProvider`;
  - `restoreBackupProvider` keeps its type and callers (`BackupsScreen`); it becomes `store.fetch`, then `_replaceWith(file)`;
  - the safety copy is written to the backup store as `ledgerly-before-import-<stamp>.sqlite`, and its location is shown;
  - after the swap, attachments are copied into `category_images` and settings rows are written.
- **`FirstAccountScreen`** gets a text button "Import a Ledgerly file".

### App lock (PR 12–13)

- **Lock settings live outside the database**, in `app_support/app_lock.json`, so a backup restore or an import can never add or remove a PIN. That makes a lock-out after restoring someone else's file impossible. The file holds `{enabled, pinHash, salt, iterations, delaySeconds, biometrics, failedCount, lockedUntil}`.
- **`app/lib/data/security/pin_hasher.dart`**: PBKDF2-HMAC-SHA256 from `pointycastle` (added in PR 10), a 16-byte random salt from `Random.secure()`, 210,000 iterations, a 32-byte output, and a constant-time compare. It runs in `Isolate.run`.
- **`app/lib/data/security/lock_store.dart`**: reads and writes the JSON atomically (write to a temp file, then rename).
- **`app/lib/app/lock_controller.dart`** is a `Notifier<LockState>`. It reads `clockProvider` (so tests use `FixedClock`), `lockStoreProvider` and `biometricsProvider`. It loads `app_lock.json` in `build()` and starts locked when the lock is enabled. `LockState { enabled, locked, biometrics, waitUntil }`:
  - `lockNow()`; `unlockWithPin(String)` returns an `UnlockResult`, applying the back-off (5 failures, then 30 s doubling up to 300 s, persisted); `unlockWithBiometrics()`;
  - `setPin(String)`, `disable(String currentPin)`, `setDelay(Duration)`;
  - `onPaused(DateTime)` and `onResumed(DateTime)` lock when the time away is at least the delay.
- **`app/lib/features/lock/lock_screen.dart`**: a full-screen cover with the app icon, a PIN dot row, the `AmountKeypad`-style digit pad (reusing the visual, not the amount logic), the wait message, and a "Use fingerprint" button.
- **`LedgerlyApp`** (`app/lib/app/app.dart`): `MaterialApp.builder` wraps the navigator in a `LockGate`. `LockGate` is a stateful widget in `lock_screen.dart` that owns an `AppLifecycleListener` (`onPause`/`onHide` call `onPaused(clock.now())`, `onResume` calls `onResumed(clock.now())`) and stacks `LockScreen` over the app while locked. `MaterialApp.builder` sits above the app's `Navigator` and `Overlay`, so `LockScreen` is wrapped in its own `Overlay(initialEntries: [OverlayEntry(builder: (_) => const LockScreen())])` inside a `Material`. Without that, tooltips and ink effects throw "No Overlay widget found". `LockScreen` uses no dialogs or sheets. After a restore or import, the `ProviderScope` is rebuilt and the app is locked again when the lock is on. That is intended. Sheets and dialogs are hidden too, and focus is blocked by `ExcludeFocus` and `Offstage` semantics.
- **`app/lib/features/settings/security_screen.dart`**: an "App lock" switch (asks for the PIN twice), "Lock after" (Immediately / 1 / 5 / 15 min), Change PIN, "Unlock with fingerprint" (PR 13, Android only), and one sentence: "App lock hides the app on this device. A password protects an exported file. If you forget the PIN, the only way back in is clearing the app's data, so keep an export."
- **PR 13**:
  - `local_auth` (`authenticate(localizedReason: 'Unlock Ledgerly', options: AuthenticationOptions(biometricOnly: true, stickyAuth: true))`), with a capability check using `canCheckBiometrics` and `getAvailableBiometrics`;
  - `MainActivity` becomes `FlutterFragmentActivity`;
  - the same Kotlin file sets `WindowManager.LayoutParams.FLAG_SECURE` through `MethodChannel('ledgerly/window')`, `secure(bool)`, while the lock is on, which hides the content in recents and blocks screenshots;
  - `app/lib/data/security/biometrics.dart` wraps `local_auth` and returns false on Windows.

### Icon and mobile polish (PR 14–17)

- **Android adaptive icon** (PR 14):
  - set `minSdk = 26` in `app/android/app/build.gradle.kts` (Flutter's default is 24), so a vector adaptive icon covers every device and the 5 default PNGs can be deleted;
  - hand-convert `design-system/brand/app-icon.svg` to VectorDrawables:
    - `res/drawable/ic_launcher_background.xml` (#163d32);
    - `res/drawable/ic_launcher_foreground.xml`, the artwork scaled into the 66/108 safe zone (polygons become `<path>`, transforms become `<group>`, strokes become `strokeWidth`/`strokeLineCap`);
    - `res/drawable/ic_launcher_monochrome.xml`, a one-colour version of the ledger and line;
  - `res/mipmap-anydpi-v26/ic_launcher.xml` declares the background, foreground and monochrome layers.
- **Windows icon and brand asset** (PR 15):
  - **`app/tool/render_icons.dart`**: run with `flutter test tool/render_icons.dart`. It renders the SVG with `flutter_svg` (`vg.loadPicture`, then `Picture.toImage`) at 16, 24, 32, 48, 64 and 256 px, and writes a PNG-in-ICO file, a tiny hand-written writer with the ICONDIR header and entries.
  - **Outputs**: `app/windows/runner/resources/app_icon.ico`, plus `app/assets/brand/app-icon.svg` (a copy) declared under `flutter: assets:`.
  - **In-app use**: `FirstAccountScreen` and `LockScreen` (if merged) show it via `SvgPicture.asset`.
  - **Naming**: the `main.cpp` window title and the `Runner.rc` product name / file description become "Ledgerly".
- **System UI** (PR 16):
  - **Splash**: `values/styles.xml` and `values-night/styles.xml` LaunchTheme uses a `launch_background` drawable with the brand background and a centred foreground. `values-v31/styles.xml` and `values-night-v31/styles.xml` set `windowSplashScreenBackground` and `windowSplashScreenAnimatedIcon` to `@drawable/ic_launcher_foreground`.
  - **Edge to edge**: `main.dart` calls `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` and sets portrait-only when `shortestSide < 600` (read from `PlatformDispatcher.instance.views.first`).
  - **Theme**: `app_theme.dart` sets `AppBarTheme.systemOverlayStyle` per brightness (transparent status and navigation bars, matching icon brightness) and a `pageTransitionsTheme` with `PredictiveBackPageTransitionsBuilder` on Android.
  - **Manifest**: `AndroidManifest.xml` gets `android:enableOnBackInvokedCallback="true"`.
  - **Bottom bar**: `app_shell.dart` checks that the bottom bar respects the gesture inset (`SafeArea(top: false)` around the `BottomAppBar` row, if needed).
- **Small-screen pass** (PR 17): `test/ui/small_screen_test.dart` pumps Home, Entries, Insights, More, Budgets, the Calendar and the Add sheet at 360×640 logical px (`tester.view.physicalSize = Size(1080, 1920)`, `devicePixelRatio = 3`), with text scale 1.0 and 1.5 (`tester.platformDispatcher.textScaleFactorTestValue`, which feeds `MediaQuery.textScaler`). It fails on any `FlutterError` (overflow). Fixes go in the screens that fail (at most 9 files; if more fail, PR 17b).

## Steps (one PR each, in order)

Counts are files changed versus `main`.

### PR 1 `feat/budgets-core`: budget data and rules (9 files)

Depends on: nothing.

1. `app/lib/data/database/tables.dart`: add `Budgets`.
2. `app/lib/data/database/app_database.dart`: register the table, `schemaVersion => 2`, `onUpgrade: if (from < 2) await m.createTable(budgets);`.
3. `app/lib/data/database/app_database.g.dart`: regenerated.
4. `app/lib/core/period.dart`: `weekOf`, `previousWeek`.
5. `app/lib/domain/budget_plan.dart`: `BudgetState`, `BudgetView`, `viewBudget`.
6. `app/lib/data/repositories/budget_repository.dart`.
7. `app/test/domain/budget_plan_test.dart`: R1–R3 figures, warning at exactly 80%, over at exactly 100%, safe-per-day 0 when over, and the last day of the period.
8. `app/test/data/budget_repository_test.dart`: spending with a transfer (ignored), a refund (lowers), a subcategory rollup, overall equal to `EntryRepository.totals().spendingMinor`, a duplicate refused, a soft-deleted budget not blocking a new one with the same scope, delete then Undo.
9. `app/test/data/migration_test.dart`:
   1. Create a database **file** in a temp dir with the current `AppDatabase`, and add an account and an entry.
   2. Close it. Turn it into v1 with `NativeDatabase(file)` plus `customStatement('DROP TABLE budgets')` and `PRAGMA user_version = 1`.
   3. Reopen with `AppDatabase`.
   4. Assert that `budgets` exists, a budget can be created, the account and entry are kept, and `user_version` is 2.

   This tests the real `onUpgrade` path without a stored schema dump.

Verify: `dart analyze`, `flutter test test/domain/budget_plan_test.dart test/data/budget_repository_test.dart test/data/migration_test.dart`, then `flutter test`.

### PR 2 `feat/budgets-screens`: budgets you can see and edit (8 files)

Depends on: PR 1.

1. `app/lib/app/providers.dart`: `budgetRepositoryProvider`, `budgetsProvider`, `budgetViewsProvider`.
2. `app/lib/features/budgets/budgets_screen.dart`.
3. `app/lib/features/budgets/budget_form.dart`.
4. `app/lib/features/budgets/budget_screen.dart`.
5. `app/lib/features/more/more_screen.dart`: a "Budgets" item with the subtitle "N budgets, M over" or "Set a limit for a category".
6. `app/lib/features/home/home_screen.dart`: the `_TopCategories` row shows a `LedgerBar` when that category has a monthly budget, and one needs-attention row for the worst budget at 80% or more.
7. `app/test/ui/budgets_test.dart`: create a budget via the form, see it on Budgets and Home, and a warning state.
8. `app/README.md`: Features gets Budgets; remove it from "Not built yet".

Verify: `flutter test test/ui/budgets_test.dart`, then a full `flutter test`. A manual check on Windows (`flutter run -d windows`) that a €400 Food budget shows the right figures after adding entries.

### PR 3 `feat/calendar-month`: month calendar and day details (10 files)

Depends on: PR 2 (only for the README order; the code depends on nothing new).

1. `app/lib/domain/calendar_month.dart`: `monthGrid`, `heatStep`, `isHighSpending`.
2. `app/lib/data/repositories/entry_view.dart`: `DayTotals`.
3. `app/lib/data/repositories/entry_repository.dart`: `watchDayTotals`.
4. `app/lib/app/providers.dart`: `dayTotalsProvider` (an autoDispose family on `(start, end)`).
5. `app/lib/features/calendar/month_calendar.dart`.
6. `app/lib/features/calendar/day_sheet.dart`.
7. `app/lib/features/entries/entries_screen.dart`: the List / Calendar switch.
8. `app/lib/features/add_entry/add_entry_sheet.dart`: `openAddEntry(context, {kind, String? day})`, setting the initial date.
9. `app/test/domain/calendar_month_test.dart`: a grid for Feb 2026 (starts Sunday 1st, so the grid starts Mon 26 Jan), Nov 2026, heat steps, and high-spending.
10. `app/test/data/entry_repository_test.dart`: `watchDayTotals` with an expense, income, a transfer (ignored), a refund, and a repeat flag.

Verify: the tests above plus `flutter test`. Manually, the calendar on a phone-size window (`flutter run -d windows`, resized to 400×800).

### PR 4 `feat/calendar-year`: year heatmap and calendar test (6 files)

Depends on: PR 3.

1. `app/lib/features/calendar/year_heatmap.dart`.
2. `app/lib/features/calendar/month_calendar.dart`: the Month / Year switch.
3. `app/test/ui/calendar_test.dart`:
   - open Entries, then Calendar;
   - tap the 29th, and the sheet shows the day's entries;
   - "Add on this day", type 5, tap a chip, and the entry is dated that day;
   - Year shows 12 months.
4. `app/lib/domain/calendar_month.dart`: `yearWeeks(int year)` returns the year as Monday-first weeks, each a list of 7 days, with days outside the year as null. Tested in `app/test/domain/calendar_month_test.dart`, which is the 6th file.
5. `app/README.md`: the calendar is done.

### PR 5 `feat/statement-parsing`: CSV statement parsing and matching (8 files)

Depends on: nothing.

1. `app/lib/domain/statement/csv_reader.dart`.
2. `app/lib/domain/statement/statement_mapping.dart`.
3. `app/lib/domain/statement/statement_match.dart`.
4. `app/test/domain/statement/csv_reader_test.dart`: quotes, `""`, newlines inside quoted fields, `;` and tab, BOM, CRLF / LF / CR-only line endings, empty fields, spaces around fields (kept inside quotes, trimmed outside), a trailing newline, and a ragged last line.
5. `app/test/domain/statement/statement_mapping_test.dart`:
   - an English bank export with debit and credit, and a Bosnian export using `dd.MM.yyyy` and the decimal comma;
   - amounts like `1.234,56` and `-12,00`;
   - invalid rows kept with an error.
6. `app/test/domain/statement/statement_match_test.dart`: ±3 days, the closest day wins, one-to-one matching, duplicates in the file, a transfer posting matching a statement row, and re-importing gives zero rows to add.
7. `app/.gitignore`: ignore `*.csv` under `app/` except `test/fixtures/**`, so a real statement can't be committed while testing the import.
8. `app/lib/domain/statement/cp1250.dart`: the Windows-1250 table. Tested in `csv_reader_test.dart` with the bytes for "Plaćanje Đ" (`0x50 0x6C 0x61 0xE6 0x61 0x6E 0x6A 0x65 0x20 0xD0`).

### PR 6 `feat/statement-import`: the import flow (≤ 11 files)

Depends on: PR 5.

1. `app/pubspec.yaml`: `file_picker`.
2. `app/pubspec.lock`.
3. `app/windows/flutter/generated_plugin_registrant.cc` and 4. `generated_plugins.cmake`, **only if** `flutter pub get` changes them. `file_picker` is Dart-only on Windows at the time of writing; check with `git status`.
5. `app/lib/data/repositories/entry_repository.dart`: `signedAmountsOnAccount`, `importStatement` (one transaction, returns `(int added, Undo)`).
6. `app/lib/features/statement_import/statement_import_screen.dart`.
7. `app/lib/features/statement_import/mapping_step.dart`.
8. `app/lib/features/statement_import/review_step.dart`.
9. `app/lib/features/settings/settings_screen.dart`: the "Import bank statement" row.
10. `app/test/data/entry_repository_test.dart`: import adds the ticked rows, a known title gets its category, and Undo removes all of them.
11. `app/README.md`.

Verify: tests. Manually, import a hand-made `statement.csv` (kept outside the repo; never commit real statements) twice; the second time "To add" is 0.

### PR 7 `refactor/backup-store`: backups go through a store (7 files)

Depends on: nothing. No behaviour change.

1. `app/lib/data/backup/backup_store.dart`: `BackupStore`, `StoredBackup`, `LocalFolderStore`.
2. `app/lib/data/backup/backup_service.dart`: uses the store; `list()` is async.
3. `app/lib/app/backup_controller.dart`: async list; `BackupState.files` becomes a `List<StoredBackup>`.
4. `app/lib/features/settings/backups_screen.dart`: adapt to the new shape.
5. `app/lib/main.dart`: build a `LocalFolderStore`; `_restore` uses `store.fetch`.
6. `app/test/data/backup_service_test.dart`: the existing 6 tests ported, plus "put failing keeps the old ones".
7. `app/test/ui/app_harness.dart`: it constructs `BackupService`, so pass a `LocalFolderStore` and a work dir.

### PR 8 `feat/backup-folder`: choose your own backup folder (≤ 11 files)

Depends on: PR 7, and PR 6 for `file_picker`.

1. `app/android/app/src/main/kotlin/app/ledgerly/ledgerly/MainActivity.kt`: the `ledgerly/folder` channel.
2. `app/lib/data/backup/android_folder_store.dart`.
3. `app/lib/data/database/connection.dart`: `backupStore(...)` with the fallback.
4. `app/lib/data/repositories/settings_repository.dart`: `SettingKeys.backupFolder`.
5. `app/lib/main.dart`: resolve the store at start; `changeBackupFolder` bumps the generation.
6. `app/lib/app/backup_controller.dart`: `chooseFolder()`, `resetFolder()`, `copyExistingTo()`, and expose `usingFallback`.
7. `app/lib/features/settings/backups_screen.dart`: a "Backup folder" row, the fallback warning, and "Copy current backups there".
8. `app/lib/features/settings/backup_status.dart`: names the folder.
9. `app/test/data/backup_store_test.dart`: `LocalFolderStore` put/list/remove/fetch, and fallback selection with a fake store whose `canAccess` is false.
10. `app/README.md`.

Verify: tests. Manually on an Android device or emulator:

1. Choose a folder in Downloads.
2. Back up now; the file appears in the Files app.
3. Restart; the next backup goes to the same folder.
4. Revoke access (clear the app's permission via Settings › Apps › Ledgerly › Storage, or delete the folder); the app falls back and says so.

On Windows: choose `D:\Backups` and check it works the same way.

### PR 9 `feat/ledgerly-file`: the `.ledgerly` format (7 files)

Depends on: PR 1, since budgets are in the counts.

1. `app/pubspec.yaml`: `archive`.
2. `app/pubspec.lock`.
3. `app/lib/data/export/ledgerly_file.dart`.
4. `app/lib/data/export/csv_tables.dart`.
5. `app/test/data/ledgerly_file_test.dart`, with these cases:
   - build from a `TestLedger` with entries and one category image;
   - read back; the counts and hashes match;
   - flip one byte in the sqlite entry, which gives `damaged`;
   - a manifest with `schemaVersion: 99`, which gives `newerVersion`;
   - a non-ZIP, which gives `notLedgerly`.
6. `app/test/data/csv_tables_test.dart`: quoting and the columns of entries and postings.
7. `app/.gitignore`: add `*.ledgerly` and `*.age` (except `test/fixtures/**`).

The counts are plain `SELECT COUNT(*) … WHERE deleted_at IS NULL` queries inside `ledgerly_file.dart`, with no change to `AppDatabase`. `pubspec.yaml` also gets `sqlite3` as a direct dependency (the same two files as `archive`).

### PR 10 `feat/age-encryption`: password-protected export files (6 files)

Depends on: PR 9 (only for order).

1. `app/pubspec.yaml`: `pointycastle`.
2. `app/pubspec.lock`.
3. `app/lib/data/export/age_passphrase.dart`.
4. `app/test/data/age_passphrase_test.dart`: round trips at 0 B, 1 B, exactly 64 KiB, and 64 KiB + 1; a wrong passphrase; a truncated file; a work factor that is too high.
5. `app/test/fixtures/age/hello-scrypt.age`, made with the reference `age` CLI (`age -p -o hello-scrypt.age` on the text `hello ledgerly\n`, passphrase `ledgerly-test`). The test decrypts it. Make it once on the developer's machine and record the command in the test file.
6. `app/test/fixtures/age/README.md`: how the fixture was made and that it contains no real data.

Verify: tests. Manually, `age -d` on a file the app exported (after PR 11).

### PR 11 `feat/export-import`: export and import screens (9 files)

Depends on: PR 8 (store, `file_picker`), PR 9 and PR 10.

1. `app/lib/features/data/export_screen.dart`.
2. `app/lib/features/data/import_screen.dart`.
3. `app/lib/main.dart`: `_replaceWith(...)` and `replaceDataProvider`; restore uses it.
4. `app/lib/app/backup_controller.dart`: move `restoreBackupProvider` next to `replaceDataProvider`, or replace it.
5. `app/lib/features/settings/settings_screen.dart`: "Export all data" and "Import a Ledgerly file" rows.
6. `app/lib/features/onboarding/first_account_screen.dart`: "Import a Ledgerly file".
7. `app/test/ui/app_harness.dart`: override `replaceDataProvider`.
8. `app/test/ui/export_import_test.dart`:
   - export with a password (with `saveFile` faked through a small `FileSaver` provider in `export_screen.dart`), and see "verified";
   - import that file with the wrong password (message, nothing changed), then the right one;
   - with REPLACE typed, `replaceDataProvider` is called with the extracted db.
9. `app/README.md`.

### PR 12 `feat/app-lock-pin`: app lock with a PIN (10 files)

Depends on: PR 10 (`pointycastle`).

1. `app/lib/data/security/pin_hasher.dart`.
2. `app/lib/data/security/lock_store.dart`.
3. `app/lib/app/lock_controller.dart`.
4. `app/lib/features/lock/lock_screen.dart`.
5. `app/lib/features/settings/security_screen.dart`.
6. `app/lib/features/settings/settings_screen.dart`: a "Security" row.
7. `app/lib/app/app.dart`: `builder:` with `LockGate`; listens to the app lifecycle for `onPaused`/`onResumed`.
8. `app/lib/main.dart`: create the `LockStore` at `app_support/app_lock.json` and override `lockStoreProvider`. `biometricsProvider` defaults to `NoBiometrics`; the `Biometrics` interface and `NoBiometrics` live in `lock_controller.dart` (D12).
9. `app/test/data/lock_test.dart`, with these cases:
   - the hash verifies, and a wrong PIN fails;
   - the salt differs per set;
   - the controller locks after the delay (a `FixedClock` moved forward) and doesn't lock before it;
   - with a fake `Biometrics`, success unlocks, and a failure or cancel leaves it locked with the PIN pad;
   - the back-off times;
   - state persists across a new controller.
10. `app/test/ui/lock_test.dart`: turn the lock on in Security, simulate pause and resume past 5 min, see the lock screen, enter the PIN, and see Home.

### PR 13 `feat/app-lock-biometrics`: fingerprint and hidden recents (≤ 11 files)

Depends on: PR 12.

1. `app/pubspec.yaml`: `local_auth`.
2. `app/pubspec.lock`.
3. `app/windows/flutter/generated_plugin_registrant.cc`.
4. `app/windows/flutter/generated_plugins.cmake`. `local_auth_windows` is native, so expect both to change.
5. `app/android/app/src/main/kotlin/app/ledgerly/ledgerly/MainActivity.kt`: `FlutterFragmentActivity` and the `ledgerly/window` secure channel. Keep PR 8's `ledgerly/folder` channel and its `onActivityResult` exactly as they are.
6. `app/lib/data/security/biometrics.dart`: `LocalAuthBiometrics` implementing PR 12's `Biometrics` interface. It returns `available() == false` on Windows.
7. `app/lib/app/lock_controller.dart`: `secure(true/false)` calls when the lock is turned on or off, and at start.
8. `app/lib/features/lock/lock_screen.dart`: the fingerprint button, shown first when enabled. It prompts automatically once on show.
9. `app/lib/features/settings/security_screen.dart`: the switch, shown only when `available()`.
10. `app/lib/main.dart`: override `biometricsProvider` with `LocalAuthBiometrics()`.

The controller's biometric paths are already tested in PR 12 with a fake `Biometrics` (D12), so PR 13 needs no new test file.

If the system prompt crashes or doesn't show on the test device, the `LaunchTheme`/`NormalTheme` parent in `values/styles.xml` may need to be an AppCompat theme. That adds 1–2 files (still ≤ 11 with the registrants), or moves to PR 16, which owns `styles.xml`.

Verify: on an Android device:

1. Enable fingerprint.
2. Lock, then unlock with the finger.
3. Cancel, and the PIN still works.
4. The recent-apps thumbnail is blank.

### PR 14 `feat/app-icon-android`: adaptive launcher icon (11 files)

Depends on: nothing.

1. `app/android/app/build.gradle.kts`: `minSdk = 26`.
2. `app/android/app/src/main/res/drawable/ic_launcher_background.xml`.
3. `app/android/app/src/main/res/drawable/ic_launcher_foreground.xml`.
4. `app/android/app/src/main/res/drawable/ic_launcher_monochrome.xml`.
5. `app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`.
6. to 10. Delete `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png`.
11. `app/README.md`: "Android 8.0 (API 26) or newer".

Only the `minSdk` line changes in `build.gradle.kts`. `compileSdk` and `targetSdk` stay `flutter.compileSdkVersion` / `flutter.targetSdkVersion` (API 36 in Flutter 3.47), which also covers `enableOnBackInvokedCallback` in PR 16.

Verify: `flutter build apk --debug`. Install on a device or emulator (API 26 and API 34). Check the launcher icon in circle and squircle masks and with themed icons on. Compare with `design-system/brand/app-icon.svg` side by side.

### PR 15 `feat/app-icon-windows`: Windows icon, brand asset and names (8 files)

Depends on: PR 14 (for order).

1. `app/tool/render_icons.dart`.
2. `app/windows/runner/resources/app_icon.ico`.
3. `app/assets/brand/app-icon.svg`.
4. `app/pubspec.yaml`: the `assets:` entry.
5. `app/lib/features/onboarding/first_account_screen.dart`: the brand mark.
6. `app/windows/runner/main.cpp`: the title "Ledgerly".
7. `app/windows/runner/Runner.rc`: FileDescription and ProductName "Ledgerly".
8. `app/README.md`: the icon is done; how to re-render it (`flutter test tool/render_icons.dart`).

Make sure `flutter test` without arguments doesn't pick up `tool/`. It only runs `test/` by default.

### PR 16 `feat/mobile-system-ui`: splash, edge-to-edge, predictive back (9 files)

Depends on: PR 14 (the splash uses the foreground drawable).

1. `app/android/app/src/main/res/drawable/launch_background.xml`.
2. `app/android/app/src/main/res/drawable-v21/launch_background.xml`.
3. `app/android/app/src/main/res/values-v31/styles.xml` (new).
4. `app/android/app/src/main/res/values-night-v31/styles.xml` (new).
5. `app/android/app/src/main/AndroidManifest.xml`: `enableOnBackInvokedCallback`.
6. `app/lib/main.dart`: edge-to-edge and portrait on phones.
7. `app/lib/ui/theme/app_theme.dart`: overlay styles and predictive back transitions.
8. `app/lib/app/app_shell.dart`: the bottom inset, if needed.
9. `app/test/ui/smoke_test.dart`: assert that `AppBarTheme.systemOverlayStyle` is set for both brightnesses.

Verify: on a device in light and dark mode, check that the splash has the brand colour and icon, the status and navigation bars are transparent with readable icons, and back-swipe shows the predictive animation (Android 14+, with "predictive back animations" turned on in the developer options).

### PR 17 `fix/small-screens`: no overflow on small phones (≤ 11 files)

Depends on: PRs 2, 4, 6, 11, 12 (all screens exist).

1. `app/test/ui/small_screen_test.dart`.
2. Up to 9 screen or widget files fixed. Typical fixes:
   - `Flexible`/`Expanded` around text in rows;
   - `TextOverflow.ellipsis` on titles;
   - `Wrap` instead of `Row` for chips;
   - `LayoutBuilder` for 2 vs 1 column tiles;
   - a scrollable sheet body.
3. `app/README.md` (if anything is worth noting).

If more than 9 files need fixing, fix the most-used screens here (Home, Add sheet, Entries, Calendar) and open `fix/small-screens-2` for the rest.

## Tests

- **Domain (pure):** `budget_plan`, `calendar_month`, `csv_reader`, `statement_mapping`, `statement_match`. These have the highest coverage, with exact figures.
- **Data:**
  - `budget_repository`, the migration v1→v2 and `entry_repository` (day totals, import), using an in-memory drift database via `TestLedger`;
  - `backup_store` and `backup_service`, using temp directories;
  - `ledgerly_file` and `age_passphrase` (including a reference-tool fixture), with `lock` using a `FixedClock` and a temp dir.
- **UI (`AppHarness`, fake time, no `runAsync`):** budgets, calendar, export/import and lock flows, and the small-screen sweep.
- **Manual (not automatable here):**
  - SAF folder persistence;
  - the fingerprint prompt;
  - `FLAG_SECURE` in recents;
  - launcher icon masks and themed icons;
  - the splash, edge-to-edge and predictive back;
  - `age -d` interop on an exported file.

## Verification commands

Run from `app/`, with Flutter at `E:\SDK\flutter-3.47.9\bin` (on Windows PowerShell, run `& "E:\SDK\flutter-3.47.9\bin\flutter.bat" ...`):

```bash
dart run build_runner build      # only after tables.dart changes
dart format --line-length 110 lib test   # add "tool" from PR 15 on
dart analyze
flutter test
flutter build apk --release       # then check the merged manifest has no INTERNET permission:
# build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
flutter build windows
git diff --stat main | tail -1    # must say at most 11 files changed
```

## Risks, migration, compatibility, security

- **Schema v2 migration.** Budgets are a new table only, so existing data is untouched. Backups made by v1 restore fine: the app migrates on open. Restoring a v2 backup into an older app isn't possible (there is only one install). The `.ledgerly` import refuses newer schemas.
- **Backup list becomes async (PR 7).** Every caller of `BackupService.list()` and `latest` changes, and `isDue` becomes `Future<bool>`. The callers are `BackupController` (its `build()` starts with an empty list and loads it in a microtask), `BackupsScreen` and `backup_status.dart` through `BackupState`. `AppShell` only calls `BackupController.runIfDue()`, which is already async, so it doesn't change. Confirm with `grep -rn "list()\|latest\|isDue" lib test`.
- **SAF without a library (PR 8).** Each `DocumentsContract` call runs on a background thread in Kotlin (`Executors.newSingleThreadExecutor`), and results come back on the main thread. Persisted permissions are limited (128 on older Android versions), so release the old URI permission when the folder changes.
- **Hand-written age (PR 10).**
  - **Spec compliance:** follow the age v1 spec exactly (C2SP `age.md`), check against the reference-tool fixture, and keep the code under 300 lines with comments citing each spec section.
  - **scrypt cost:** logN 16 needs about 64 MB and a few seconds in pure Dart on a phone, so run it in an isolate with a progress indicator. Measure on the device. If it takes over 10 s, use logN 15 and record it.
  - **Decrypting outside files:** accept files up to logN 20 only.
  - Never log passphrases.
- **Pure-Dart PBKDF2 (PR 12).** 210,000 iterations may take about 1 s on a slow phone, so do it in an isolate. Store the iteration count so it can be raised later.
- **Lock is not encryption.** With root access or ADB backup (`allowBackup` is false), the database is readable. Say so in the Security screen sentence (it already says "hides").
- **`FLAG_SECURE`** also blocks screenshots while the lock is on. That is intended and should be mentioned in the Security screen.
- **`minSdk` 26 (PR 14)** drops Android 7.x (2016) devices. Acceptable for one person's phone. Record it in the README.
- **`file_picker` / `local_auth`** must not request network permissions. Check the merged release manifest after each PR that adds a plugin.
- **Never commit** real statements, exports, backups or the `app_lock.json`. PR 5 adds `*.csv` and PR 9 adds `*.ledgerly` / `*.age` to `app/.gitignore`, except `test/fixtures/**`. `app_lock.json` lives in the app support folder, outside the repository.

## Open questions

These are settled with a default and can be changed before the PR starts:

1. **App lock on Windows** uses the PIN only. Windows Hello would be a small addition to PR 13 through `local_auth_windows`, which comes with `local_auth` anyway. It wasn't asked for, so it is left out.
2. **Statement rows with money in** that title memory doesn't know need an income category before they can be added (D7). They are never counted as spending.

## Decision log

- **D1. Budgets are stored in EUR, like goals**, so one overall budget can cover both currencies. A BAM-only budget isn't needed for one person with a pegged rate.
- **D2. One budget per category per cadence.** No custom periods (excluded by the brief). Weekly runs Monday to Sunday, matching the calendar.
- **D3. Calendar heat is relative to the month's quartiles**, not fixed amounts, so it works at any income level. It is always paired with the number (brief: never colour alone).
- **D4. CSV parsing is hand-written in `domain/`** (architecture decision: too small for a library). `file_picker` is used only to get bytes.
- **D5. Backup store abstraction before the custom folder**, so PR 8 stays under 11 files and the 3-day / 3-file rule stays in one place.
- **D6. SAF via a small Kotlin channel** instead of a third-party SAF package. There is no well-maintained, Windows-irrelevant package we can rely on, and the needed surface is 6 calls.
- **D7. Statement import categorisation.** Known titles get their category and kind from title memory. Unknown money-out rows go through `addLater` (Needs Review). Unknown money-in rows are shown unticked by default with the note "Income needs a category"; ticking them asks for an income category for all ticked income rows in one picker. This avoids counting unknown income as spending.
- **D8. age with a hand-written scrypt recipient on `pointycastle`**, keeping the architecture's open-format decision. There is no maintained Dart age package. The reference-tool fixture guards interop.
- **D9. Lock settings in `app_lock.json` outside the database**, so restore and import never change the lock.
- **D10. `minSdk` 26 and vector-only adaptive icons**, which keeps PR 14 to 10 files and stays sharp at every density. `flutter_launcher_icons` was rejected because it adds 10+ generated PNGs (it breaks the file budget) and a dev dependency.
- **D11. ICO rendered by a Flutter tool script** using `flutter_svg` (already a dependency), with no new tool or package.
- **D12. The `Biometrics` interface lands in PR 12**, so PR 13 stays at ≤ 11 files.
- **D13. Statement matching includes transfers and balance checks** on the account, because bank statements list them.
- **D14. Critic round 1 points rejected:**
  - "`watchDayTotals` file missing": `entry_repository.dart` is PR 3 file 3.
  - "`openAddEntry` callers break": the new parameter is optional and named.
  - "PR 13 exceeds 11": its count already includes both Windows registrant files.
  - "age fixture not listed": it is PR 10 file 5.
  - "back-off persistence test missing": it is listed.
  - "`.gitignore` for `app_lock.json`": the file lives in the app support folder, never in the repository.
  - "`AppShell` must change in PR 7": it only calls the controller's already-async `runIfDue`.
  - "`file_picker` registrants will change": kept as "count them if they change", and PR 6 has room for both.
  - "animated splash": a static icon is enough.
- **D15. Fixes from critic round 1:**
  - a concrete migration-test recipe;
  - the SAF calls, including `canAccess`, spelled out;
  - `restoreBackupProvider` kept as a wrapper;
  - `LockGate` owns the lifecycle listener, and the controller reads `clockProvider`;
  - half-up rounding for safe-per-day;
  - a heat fallback for empty months;
  - paid / due / planned repeat markers;
  - `.gitignore` rules in PR 5 and PR 9, keeping PR 6 at 11;
  - `sqlite3` read-only validation;
  - logN checked before scrypt;
  - more CSV and budget test cases;
  - README in PR 14;
  - the text-scale test API named.

- **D16. Fixes from round 2 (self-review):**
  - Windows `saveFile` writes the bytes itself;
  - `LockScreen` gets its own `Overlay`;
  - a hand-written Windows-1250 decoder;
  - PR 4's file list made definite;
  - the format command no longer names `tool/` before it exists.

## Review trail

| Round | Critic | Verdict | Issues |
|---|---|---|---|
| 1 | nvidia:nvidia/nemotron-3-ultra-550b-a55b | REVISE | 100 points listed. About 25 were real problems: 16 fixed (D15) and 9 rejected with reasons (D14). The rest were confirmations. |
| 2 | self (fallback): the second model was unreachable (helper exit 3, all models failed on the 77 KB input) | APPROVE after fixes | 5 blocking issues, all fixed (D16) |
