# Ledgerly: architecture review

Checked on 2026-11-01. Nothing here has been built or tested yet. Items marked **Spike** must be proven on a real Android device before the app depends on them.

## Verdict

Keep React, TypeScript, SQLite, and Capacitor. The stack holds up, but the first proposal left the real risks unaddressed. Those risks are losing data, being tied to a plugin, and losing the ability to install updates.

| Option | Decision | Why |
|---|---|---|
| React, TypeScript, Capacitor, native SQLite | **Use** | One codebase, with the database as a normal file outside the WebView's storage |
| PWA only | Reject as the main app | Browser storage can be cleared, and it can't provide widgets or reliable folder access |
| SQLite in the WebView (WASM) | Reject on Android | It puts the data back inside WebView storage |
| Kotlin and Compose | Reject | Strong for Android, but no code can be reused for the desktop view |
| Flutter | Reject | Solid option, but it's further from the React direction and no better for the risks below |
| Any backend or cloud database | Reject | It adds a dependency and solves no current problem |

## Changes from the original proposal

### 1. No network access at all

Release builds remove Android's `INTERNET` permission, so the operating system itself blocks any network access, including from a dependency. Fonts, icons, and libraries all ship inside the app, with no CDN and no telemetry. Android Auto Backup is also turned off, so data isn't copied to Google without anyone choosing that.

**Spike:** confirm Capacitor runs without the permission. Capacitor serves its files locally, so this should work, but I found no Capacitor-specific confirmation. Debug builds keep the permission for live reload.

A later online feature, such as exchange rates, would mean adding the permission back. That should be a deliberate decision.

### 2. The SQLite plugin stays replaceable

The plugin is the largest third-party risk, and I could not confirm its current release from an official source. Third-party reports say `@capacitor-community/sqlite` is on an 8.x line, and that source sells a competing plugin.

- All database access goes through one small interface: `query`, `execute`, `transaction`.
- No other code imports the plugin.
- Financial logic is plain TypeScript with no React or plugin imports, so it can be tested and moved on its own.
- If the plugin stalls, the way out is a replacement behind that interface or a small custom Kotlin plugin. The database file doesn't change.

**Spike:** check the plugin against the current Capacitor release, including `VACUUM INTO` and WAL mode.

### 3. One data model that makes the rules hard to break

Each transaction has one or more postings:

```sql
postings (
  id, transaction_id, account_id, category_id,  -- category_id is NULL for money only moving between accounts
  amount_minor, currency,                       -- integer minor units, signed
  base_minor                                    -- reporting currency value, frozen when recorded
)
```

| Case | Postings |
|---|---|
| Expense | Bank −85, Groceries |
| Split | Bank −60 Groceries, Bank −15 Household, Bank −10 Personal Care |
| Transfer | Bank −100, Savings +100, no category |
| Refund | Bank +20, on the original expense category |
| €40 dinner, €25 my share | Bank −25 Dining, Bank −15, Owed to Me +15 |
| Repayment of that €15 | Owed to Me −15, Bank +15, no category |
| Untracked adjustment | Cash −12, on the system Untracked category, excluded from reports |

Two rules follow, and tests can enforce both:

- Income and spending only ever come from postings with a category, so transfers are excluded by construction.
- Postings without a category must sum to zero per transaction in `base_minor`.

This gives the benefit of double-entry bookkeeping without showing it in the interface. "Owed to Me" is a system account.

Other model rules:

- Balances are always calculated from postings. Any cached total must be safe to delete and rebuild.
- Categories belong to accounts through a `category_accounts (category_id, account_id)` table. No rows means the category applies to all accounts. The table only limits what the Add sheet offers and is never checked against postings, so changing a category's accounts can't invalidate history.
- A category's icon is either a name from the line set or an image stored with the attachments, resized to about 96px, so backups and exports include it.
- At 20 entries a day for 15 years, the database holds about 110,000 transactions, which SQLite handles easily with proper indexes.
- IDs are UUIDv7, so records from separate installs never collide and later sync stays possible.
- Dates are stored as local `YYYY-MM-DD`, with a separate UTC `created_at`, so travel can't move a transaction to another day.
- Deletes are soft, and every change is written to an append-only `change_log`.
- Recurring occurrences have a unique constraint on rule and scheduled date, so a duplicate can't be inserted. Due items are generated when the app opens, and this is safe to repeat.
- Tables use `STRICT`, foreign keys, and `CHECK` constraints.
- WAL mode with `synchronous=FULL` favours durability over a little write speed.

### 4. Backups run when the app is used

Capacitor's JavaScript doesn't run reliably in the background, so a timed background job isn't a dependable design. Instead, the app checks when it opens and when it moves to the background, and it creates a backup if the last one is older than a day.

A backup in the phone's own storage doesn't survive a lost phone. So the app asks for a folder through Android's file picker, and any folder the user trusts works, including a synced folder or SD card. Ledgerly doesn't need to know about it. The app also prompts occasionally for a copy off the device.

**Spike:** keeping access to the chosen folder after restarts needs native Android code.

### 5. One open data file for backup, export, and transfer

A `.ledgerly` file is a ZIP containing:

```text
manifest.json     format version, schema version, app version, date, counts, SHA-256 of every file
data/ledgerly.sqlite     consistent snapshot made with VACUUM INTO
data/*.csv               the same data in readable form
attachments/      files named by content hash
settings.json
```

- Never copy the live database files, because a copy taken during writes can be corrupt. `VACUUM INTO` avoids this.
- Password-protected exports use the open [age](https://github.com/FiloSottile/typage) format with a passphrase, so the file can be decrypted with the standard `age` tool and doesn't depend on Ledgerly. Check large-file streaming during the build.
- After writing a file, the app reopens it, verifies each hash, runs `PRAGMA integrity_check`, and compares counts and balances.
- Keep 7 daily, 4 weekly, and 12 monthly backups.
- Import always validates into a separate copy first. It takes a safety snapshot and only then swaps the database in, so a failed import changes nothing.
- A newer-format file is refused with a clear message. An older one is migrated after it's copied.
- Import in the first version replaces the data. Merging two installs is a sync problem, and it's postponed.

### 6. Safe upgrades

- Migrations are numbered, forward-only SQL files, tracked with `PRAGMA user_version` and run in a transaction.
- A snapshot is taken automatically before any migration.
- Tests run every migration against a fixture database from each past schema version.
- If the database fails to open, the app shows a recovery screen with restore and raw export. It must not crash in a loop.

### 7. Read-only desktop without an install

The same web build can open a `.ledgerly` file in a desktop browser, using SQLite compiled to WASM, in memory only. It needs no server and no install. If that ever proves limiting, Tauri could wrap it later.

### 8. Distribution and signing

These are the risks most likely to catch a personal app by surprise.

- **Lost signing key:** Android refuses an update signed with a different key. Losing the key means uninstalling, which deletes the app's data. Keep the keystore and its passwords in a password manager and in an offline copy, never in git. Debug and release builds also use different keys, so don't install one over the other.
- **Developer verification:** Google began enforcing this in four countries on 2026-09-30, with a [global expansion planned for 2027](https://android-developers.googleblog.com/2026/06/android-developer-verification.html). Three routes remain: installing over ADB, which [skips verification](https://www.whistleout.com/CellPhones/Guides/how-to-sideload-apps-on-android); a free limited distribution account for up to 20 devices; or the [advanced flow](https://www.androidauthority.com/google-android-advanced-flow-sideloading-rollout-begins-3700073/), which adds a one-time 24-hour wait. Use ADB for now, and re-check before 2027.
- **iOS:** needs a paid developer account, or re-signing every 7 days, so it stays out of scope.
- **Home-screen widget:** Capacitor doesn't provide one, so it needs a small amount of Kotlin. It only launches the Add sheet and doesn't read the database.

## Dependencies

Each dependency must be replaceable, and must either run at build time or be small enough to replace.

| Need | Choice | Notes |
|---|---|---|
| Build and UI | Vite, React, TypeScript | No Next.js, because there's no server |
| Android wrapper | Capacitor | Only for packaging and native access |
| Database | Native SQLite plugin behind the interface; SQLite WASM for desktop read-only | No ORM, plain SQL with typed helpers |
| Accessible primitives | Radix UI | Dialogs, menus, and similar |
| Styling | CSS variables and CSS Modules | Tokens come from `design-system/` |
| Charts | `d3-scale`, `d3-shape`, and own SVG components | Eight chart views don't justify a large chart library, and SVG can also go into PDFs |
| PDF | `pdfmake` | Check SVG charts during the build |
| CSV | Hand-written | Too small to need a library |
| ZIP | `fflate` | Check memory use with large attachment sets |
| Encryption | `age-encryption` | Open format, see section 5 |
| Tests | Vitest | The financial core gets the most coverage |

Excluded: Redux, ORMs, Firebase and Supabase, analytics, crash reporting, and anything loaded from a CDN.

Photos are compressed to about 2000px on import. They're stored as files named by hash, with only metadata in the database, which keeps the database small and removes duplicates.

## Postponed

- **Database encryption:** Android's storage encryption and encrypted exports cover the main risks at first. SQLCipher can follow if needed, and it makes the plugin choice harder.
- **Sync:** UUIDs, soft deletes, and the change log keep it possible.
- **Online exchange rates:** BAM and EUR are pegged, and other currencies use manual rates.

## Sources

- [Android developer verification, Android Developers Blog](https://android-developers.googleblog.com/2026/06/android-developer-verification.html)
- [Android sideloading in 2026, WhistleOut](https://www.whistleout.com/CellPhones/Guides/how-to-sideload-apps-on-android)
- [Advanced flow rollout, Android Authority](https://www.androidauthority.com/google-android-advanced-flow-sideloading-rollout-begins-3700073/)
- [Capacitor SQLite alternatives, Capgo (a competing vendor)](https://capgo.app/blog/capacitor-community-sqlite-alternative/)
- [typage, TypeScript implementation of age](https://github.com/FiloSottile/typage)
- [Removing the Android INTERNET permission, Anyline](https://anyline.atlassian.net/wiki/spaces/SP/pages/3901947918/Android+-+Internet+Permission)
