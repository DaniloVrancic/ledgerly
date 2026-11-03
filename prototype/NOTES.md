# Closing notes

## What was checked

Each of the 22 interactions was driven through the real interface, with figures compared before and after. The closing checks from the brief were run the same way.

| Check | Result |
|---|---|
| A common expense in two taps plus the digits | Pass: Add, digits, category chip. Save appears only when it is needed |
| Any account balance in one tap from Home | Pass: tap Total balance |
| Export and import without confusion | Pass: one file, a preview first, a typed confirmation, a plain result |
| Each Home section earns its place | Pass, with the length note below |
| Figures agree across screens | Pass: Home, Analytics, Calendar days, History day nets, Budgets and Reports match the raw entries, across all 14 months |
| Transfers and repaid shares excluded | Pass: all 71 transfers, Untracked adjustments and repayments count as zero; repaying €15 left income and spending unchanged |
| Desktop clearly read-only | Pass: no Add, no write action on any desktop screen, file date always visible |
| Every chart leads to its transactions | Pass: all 55 marks open their entries, and each entry opens its details |
| Layouts | 31 screens in phone, tablet and desktop: no horizontal overflow, no missing values |

**Not checked.** The published canvas was not opened on claude.ai, because the test browser is not signed in. Its files were run locally on the canvas's own runtime instead, and the prototype, stills and sitemap all rendered without console errors. Nothing was tried on a physical phone, so swipe and long-press were tested with synthetic touch events. Contrast was not re-measured for the additions below.

## Titles and repeats

An entry is a **title** and a **subcategory**. The merchant is optional, under More details.

- Titles are remembered. Typing one offers titles used before, and choosing one brings back its usual subcategory and account. The six titles used most in the last 90 days sit at the top of the Add sheet, and with an amount typed one tap saves.
- With no title typed, a chip saves the entry under the subcategory's name, so Add, digits, chip still takes two taps.
- **Repeats** replace fixed recurring items. Any title can repeat daily, weekly, monthly or yearly, from More details on the Add sheet, from Repeat this in an entry's details, or from Recurring.
- A repeat becomes Due on its date and waits. **Mark paid** posts it with Undo. When the amount changes each time, Ledgerly asks for this time's amount first. **Skip** moves it to the next date.
- Typing the title of a repeat on the Add sheet counts as paying its next one, so you never end up with two Electricity repeats.
- Tapping a repeat opens one form. Changes save themselves, and Stop repeating leaves past entries alone.
- The forecast counts monthly and yearly repeats as bills. Daily and weekly repeats stay inside normal daily spending, so they are not counted twice. Daily repeats are left off the calendar grid.
- Templates are gone. Frequent titles and repeats cover the same need with less to set up.

## What is interactive

Everything in the 22 interactions, plus: frequent titles, repeats, multi-select and bulk edit, refunds linked to their entry, Duplicate, the reconciled-period warning, month start, goals, new budgets, new recurring items, notes with links, category archive and delete, Start empty, hide amounts, accent colour. Changes last for the session.

## What is simulated

Each of these says so on screen where it happens.

| Simulated | What really happens |
|---|---|
| Export, encryption, verification | No file is written. The result is derived from the session's real counts |
| Import from a data file | No file is read. The demo data stays in place |
| Backups, folder choice, restore test | Dates and status change. Nothing is copied |
| Bank statement CSV | A sample statement is built from the ledger. Added rows do become real entries in the session |
| Report PDF and CSV | The preview is real. No file is written |
| Camera and photo prompts, receipts | Permission prompts are imitations. Receipts are placeholder drawings |
| App lock and biometrics | No check runs |
| Android widget | A drawing of a home screen. Its button opens the real Add sheet |
| Weekly refresh of chip order | Chips stay stable. No refresh runs during a session |
| Desktop file | The copy mirrors the live session, so an entry added on the phone appears on desktop under a fixed file date. A real copy would not change |

## Additions to the design system

Nothing in `design-system/` was changed, and no colour, type style or token was added. These are built from existing tokens and live in `prototype/`.

| Addition | Why |
|---|---|
| Dense table (`.p-table`) | The desktop history, report CSV preview and statement preview need one. The system has no table |
| Date-range charts (`js/charts.js`) | `Ledgerly.charts` are fixed to October 2026 and cannot carry drill-down. These keep the same style, sizes and slots |
| Cost mix bar (`.p-mix`) | Fixed, recurring and variable costs have no chart in the system |
| Bars against a limit | Budget history and monthly comparisons |
| Entry rows for repayments, Untracked adjustments and foreign currency | `ui.tx` shows these with the wrong sign or as Needs review |
| Balance rows that open an account | `ui.balance` rows are not buttons |
| Sidebar with Recurring and Notebook | `ui.sidebar` has nine fixed items, and these two had no route on desktop |
| Swipe-to-delete layer, multi-select bar, split rows, positioned tooltip | Interactions the system defines in words only |
| Viewer bar, receipt placeholder, Android home screen | Prototype scaffolding, not product |

Subcategories are added to the ledger's `CUSTOM` list at load, and `Ledgerly.data` functions for accounts, summary, budgets, forecast and owed amounts are replaced at load, so the system's own builders read the one extended ledger.

**Worth folding into the system.** `ui.tx` should handle repayments and positive Untracked adjustments. `Ledgerly.charts` should accept a range. The `README.md` on the design system artifact names `ledgerly.css` and `ledgerly.js`, but that artifact serves them as `components/bundle.css` and `components/bundle.js`.

## Where I followed the brief or the system, and recommend a change

1. **Transactions or History.** The brief names the second tab Transactions. The locked `ui.nav` labels it History, because Transactions is tight at this size. The prototype keeps the system's label, and the screen title stays Transactions. Pick one.
2. **Year heatmap.** The brief asks for a heatmap, and the system forbids a grid of squares by week. The Year view uses the system's year ledger, with the same five spending steps. It answers the same question, so I recommend rewording the brief.
3. **Home length.** Home is about 1,700px, or 2.2 phone screens, against a target of about two, even with Recent at three rows and one insight. Only Recent can shrink further without losing a required section. I recommend accepting 2.2.
4. **Needs attention, three rows.** Budget warnings come last, so on a busy day they do not appear there. Over-limit bars still show under Where it went, so this costs little, but the brief's order could be stated.
5. **Balance and frozen rates.** A 12.00 KM expense adds €6.14 to spending but moves Balance by €6.13. Entries freeze their EUR value, while Balance converts each account total at the current rate. Both follow the rules, and the difference is at most a cent or so per entry. I recommend a line in the Balance definition.
6. **Calendar months.** Month start applies to Budgets, Home and Reports, as the brief says. The calendar stays on calendar months, so with a payday start its monthly totals will differ from Home. Consider showing the financial month's boundary in the grid.
7. **More details hides the keypad.** With More details open and an amount entered, the keypad collapses to leave room, and tapping the amount brings it back. The brief does not cover this.
8. **Transfers need Save.** A transfer has no chip to commit it, so it cannot follow the save-on-tap rule. This is expected, but the brief does not say so.
9. **Demo date.** The sample ledger is fixed at 29 Oct 2026, so 14 months end on that date rather than today. Keeping it means no second ledger, and it also shows a due item and a month ready to close.

## Other things to know

- **Canvas editing.** `Ledgerly.ui` returns HTML strings, so the Prototype and the three Tier boards are drawn by script. They run normally, but their text cannot be retyped or selected in the canvas editor. Only the Sitemap board is native canvas markup.
- **Inter.** The system does not include it, so type falls back to the system sans, as its README says.
- **`docs/design-prompt.md`** already had an uncommitted change when this work began. It was left untouched and is not part of the prototype commit.
