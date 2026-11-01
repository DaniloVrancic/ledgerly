# Ledgerly

Offline-first personal finance manager for one person's private use. Not a commercial product: no accounts, tenants, billing or required backend.

## Status

Design stage. No application code or dependencies yet.

- [Design brief](docs/design-prompt.md)
- [Architecture review](docs/architecture.md)
- [Usability review](docs/usability-review.md)

## Environment

- Node 24 (`.nvmrc`), pnpm 12 (`packageManager` in `package.json`).
- Do not add dependencies until the design is approved and the stack is confirmed.

## Rules

- The local database is the source of truth. Normal use must never require a network connection.
- Transfers never count as income or expenses. Refunds reduce spending in their category and never count as income.
- Store money as integer minor units with the original currency and the rate used. Never recalculate history at today's rate.
- Income and spending come only from postings with a category. Balances are calculated, never stored as the source of truth.
- All database access goes through one interface. Financial logic stays plain TypeScript with no UI or plugin imports.
- No network access in release builds, no CDN, no telemetry.
- Never commit real financial data, databases, backups, exports or signing keys.
- Mark anything that is only visual as a prototype. Keep implemented and planned functionality separate.
