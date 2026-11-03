# Sitemap

The same map is on the canvas, and in the prototype under Sitemap, where every line is a link.

## Navigation by layout

| Layout | Navigation | Add | Data |
|---|---|---|---|
| Phone | Bottom bar: Home, Transactions (labelled History by the system), Add, Analytics, More | Raised central button, opens a sheet | Live, editable |
| Tablet | Icon rail: Home, Transactions, Add, Analytics, Calendar, Accounts, More | Rail item, opens a side sheet | Live, editable |
| Desktop | Sidebar: Home, Transactions, Analytics, Calendar, Budgets, Goals, Accounts, Recurring, Notebook, Reports, Settings | None | Read-only copy, file date always shown, `/` and `?` shortcuts |

## Screens

**S** is a screen, **Sh** a sheet (a side sheet on wider layouts), **D** a dialog, **F** a full-screen step.

```text
Home S
├─ Total balance, expands in place → Account details S
├─ Lowest before payday → Forecast calculation Sh
├─ This month tiles → filtered Transactions S
├─ Where it went rows → filtered Transactions S
├─ Needs attention, at most 3
│  ├─ Mark a due repeat paid, in the row
│  ├─ Review → Needs Review S
│  ├─ Check → Balance check Sh
│  ├─ Close → Monthly close S
│  └─ View → Budget details S, Backup and data S
├─ Recent → Transaction details S
└─ Backup status line → Backup and data S

Add Sh (from the Add button and the Android widget)
├─ Frequent titles, amount, title with suggestions from earlier titles
├─ Expense, Income, Transfer
├─ Account and date choices, inside the sheet
├─ All categories, inside the sheet → New category, inside the sheet
├─ More details: repeat, merchant, tags, split, my share, currency, note, attachments
└─ Saved: confirmation with Undo and Add another

Transactions S
├─ List | Calendar switch
├─ Search, filter chips → Filters Sh
├─ Row → Transaction details S (side panel on tablet and desktop)
│  ├─ Choose a category Sh, Record a refund Sh, Record a repayment Sh
│  └─ Camera permission D, attachments
├─ Swipe to delete with Undo, on phones and tablets
├─ Long-press → multi-select → Choose a category Sh, Add a tag Sh, Delete
└─ Calendar: Month grid, Year ledger
   └─ Day → Day details Sh (side panel on tablet and desktop), day note

Analytics S (shared range and comparison)
├─ Overview: income and spending bars with net
├─ Categories: donut with ranked list, trend lines → Category analytics S
├─ Patterns: weekday, largest payments, fixed, recurring and variable
├─ Progress: balance over time, savings rate
└─ Any mark → Entries behind it Sh → Transaction details S

More S
├─ Budgets S → Budget details S, New budget Sh
├─ Goals S → Goal details S, New goal Sh, Earmark or release Sh
├─ Accounts S → Account details S → Balance check Sh
├─ Recurring S: Due with Mark paid and Skip, Coming up → Edit repeat Sh, New repeat Sh, Amount this time Sh
├─ Notebook S → Note details S → Add a link Sh, Photos permission D
├─ Reports S, with live preview, PDF and CSV
├─ Needs Review S
├─ Monthly close S, five steps
└─ Settings S
   ├─ Appearance S
   ├─ Regional S, month start
   ├─ Security S → Lock screen F
   ├─ Categories S → Category form Sh → Delete category D
   ├─ Backup and data S
   │  ├─ Export all data Sh → Verified result
   │  ├─ Import from a data file F: choose, password, preview, typed confirmation, done
   │  │  └─ Failures: damaged, wrong password, newer version
   │  └─ Bank statement CSV S: map, compare, done
   ├─ Home-screen widget S
   ├─ States S: empty, loading, error, dialogs, permission prompts
   └─ First launch F: start empty → First account, explore demo data, import a data file
```
