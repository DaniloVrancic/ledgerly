# Ledgerly

Offline-first personal finance manager for one person's private use. Not a commercial product: no accounts, tenants, billing or required backend.

## Status

The app is built in Flutter, in [app/](app/README.md), for Android and Windows. Its README lists what is built and what is not yet. `prototype/` is the clickable design it follows, and `design-system/` holds the tokens and icons the app uses.

- [Design brief](docs/design-prompt.md)
- [Architecture review](docs/architecture.md). It assumed React and Capacitor; the stack is now Flutter with Drift on SQLite, and its data model and backup rules still apply.
- [Usability review](docs/usability-review.md)

## Environment

- App: Flutter 3.47.9, Dart 3.13. The SDK must be in a path without spaces (`E:\SDK\flutter-3.47.9`), because Flutter's native build hooks fail on spaces.
- After changing `app/lib/data/database/tables.dart`, run `dart run build_runner build` in `app/`.
- Design system and prototype: Node 24 (`.nvmrc`), pnpm 12 (`packageManager` in `package.json`).
- Keep dependencies few. Each one in `app/pubspec.yaml` carries a comment saying why it is there.

## Rules

- The local database is the source of truth. Normal use must never require a network connection.
- Transfers never count as income or expenses. Refunds reduce spending in their category and never count as income.
- Store money as integer minor units with the original currency and the rate used. Never recalculate history at today's rate.
- Income and spending come only from postings with a category. Balances are calculated, never stored as the source of truth.
- All database access goes through the repositories in `app/lib/data/repositories`. Money rules stay plain Dart in `app/lib/domain`, with no Flutter or database imports, and are covered by tests.
- Every synced record keeps a UUID id, `updatedAt` and a soft `deletedAt`, so sync can be added later.
- No network access in release builds, no CDN, no telemetry. The Android release manifest removes the INTERNET permission.
- Never commit real financial data, databases, backups, exports or signing keys.
- Mark anything that is only visual as a prototype. Keep implemented and planned functionality separate.
