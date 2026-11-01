# Ledgerly prototype

A clickable, high-fidelity prototype. Everything in this folder is a prototype: nothing is implemented, and nothing is saved. Reloading starts again from the demo data.

Open [index.html](index.html) in a browser. It needs no server, no install and no network.

| Open | What it shows |
|---|---|
| [index.html](index.html) | The prototype, starting on Home with demo data |
| [index.html?desktop&theme=dark](index.html?desktop&theme=dark) | One layout and theme directly. Also `?phone`, `?tablet` and `?route=analytics` |
| [screens.html?tier=1](screens.html?tier=1) | Stills of the Tier 1 screens. Also `tier=2` and `tier=3` |
| [SITEMAP.md](SITEMAP.md) | Every screen and how it is reached |
| [NOTES.md](NOTES.md) | What is interactive, what is simulated, additions to the system, recommended brief changes |

The bar above the app belongs to the prototype, not the product. It switches Phone, Tablet, Desktop and Fit (follows the window width), Light and Dark, opens the Sitemap, and Reset reloads the demo data.

| File | What |
|---|---|
| `js/ledger.js` | Extends the design system's one sample ledger in place, and holds the financial rules |
| `js/core.js` | State, navigation, rendering, shared helpers, the viewer bar |
| `js/charts.js` | The system's chart style with any date range, and every mark leading to its entries |
| `js/home.js`, `add.js`, `tx.js`, `calendar.js`, `analytics.js` | Tier 1 screens |
| `js/money.js`, `notes.js`, `flows.js`, `settings.js` | Budgets, Goals, Accounts, Recurring, Notebook, Reports, Review, Close, First launch, Settings, Backup and data |
| `js/gallery.js`, `screens.html` | Stills drawn by the same views as the live screens |
| `prototype.css` | Layout only, from tokens. Component looks come from `design-system/` |

All sample data is fictional. The demo day is 29 Oct 2026, the design system's ledger date.
