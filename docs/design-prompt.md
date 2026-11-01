# Ledgerly: design brief

Design a complete, clickable, high-fidelity prototype of Ledgerly, a personal finance app for one person's private use. It is not a commercial product: no sign-up, subscriptions, roles, or marketing pages.

The product decisions below are final. Do not reopen them or write an analysis. Spend your effort on the interface. If a decision makes a screen clearly worse, follow it anyway and flag it in your closing notes.

## Core principle

Recording money takes seconds, understanding it takes one glance, and every number can be traced to the transactions behind it. The design goal is to keep the logging habit alive and the numbers trustworthy. It should feel like a calm, premium everyday app, not accounting software or a spreadsheet.

## Product context

- Offline-first: everything runs on the device and the local database is the source of truth. Do not design login, cloud, sync, or loading that implies a server. A quiet status such as "Backed up 2 days ago" replaces any online indicator.
- Android first. Design for a phone, then tablet and desktop. Larger layouts are redesigned for their width, not stretched phone screens.
- One main device: the phone or tablet holds the live data and is where entries are made. Desktop opens a Ledgerly data file in the browser as a read-only copy for analysis and reports, and it shows the file's date clearly. The same file moves the data to a new device.
- Assumed build: React, TypeScript, SQLite, Capacitor for Android. Use patterns that are realistic on the web and in a mobile wrapper. Release builds have no network access, so nothing in the design can rely on it.
- UI language is English. Support long labels and Bosnian characters (č, ć, đ, š, ž) in user data.

## Financial rules

Every screen must follow these. Show the definition in a small info tooltip wherever the metric appears.

- Balance: sum of all account balances. Credit cards count as negative. Converted at the current rate.
- Income: income transactions only.
- Spending: expenses minus refunds.
- Net: income minus spending. This replaces "net cash flow" and "net savings", which would be the same number.
- Savings rate: net divided by income.
- Transfers: never count as income or spending, including transfers to savings, credit card payments, and ATM withdrawals into Cash. Show them in neutral colour with a two-way arrow.
- Credit card purchases count as spending on the purchase date.
- Refunds: linked to the original transaction when possible, shown as a negative expense in the same category, and they reduce budget usage. They are never income.
- Split transactions: one payment across several categories, with a live remaining amount that must reach zero.
- My share: when paying for friends or a work cost that will be repaid, the user marks the amount that is really theirs. Only that share counts as spending. The rest appears as "Owed to me" until it is repaid, and the repayment is not income.
- Currencies: EUR is the reporting currency and BAM is the second currency. BAM is pegged at 1 EUR = 1.95583 BAM, so show this as a fixed rate. Any other currency uses a manually entered rate. Every foreign-currency transaction shows its original amount first and the converted amount in smaller text.
- Reconciliation: the user enters the real balance, sees the difference, and resolves it with a labelled "Untracked" adjustment that is excluded from income and spending.
- Reconciled periods: editing a transaction dated before the last reconciliation shows a warning first.
- Goals: money in a goal is earmarked inside an account, not moved or spent. Always separate "Total balance", "Earmarked for goals", and "Free to use".
- Recurring items have three clear states: Planned, Due (waiting for confirmation), Posted. Due items are confirmed with one tap, so the app never silently duplicates or posts.
- Categories in use cannot be destroyed: deleting one requires reassigning its transactions or archiving it. Archived categories stay in history and reports. Categories have one level of subcategories only.
- Categories belong to accounts: each category applies to all accounts by default, or to the accounts the user chooses, with at least one. The Add sheet shows only the categories for the selected account. History, budgets, and reports always keep every category, and changing a category's accounts never moves or hides past entries.
- Custom categories: the user can add their own, with a name, a type, any icon from the line set or their own image, and a colour from the curated set.
- Month start: the user can choose the day a financial month begins, such as payday. Budgets, Home, and reports all follow it. The default is the 1st.

## Navigation

Mobile bottom bar with five items:

1. Home
2. Transactions, with a List | Calendar switch at the top
3. Add, a raised central button
4. Analytics
5. More: Budgets, Goals, Accounts, Recurring, Notebook, Reports, Settings

Tablet uses a compact icon rail. Desktop uses a full labelled sidebar in which Calendar, Budgets, Goals, and Accounts are direct items, plus a persistent "Read-only copy" label with the backup date. Desktop has no Add button. Its keyboard shortcuts are / for search and ? for shortcut help.

## Speed rules

The app is used 10 to 20 times a day, so these apply to every screen.

- Prefer acting in place to opening a new screen. Common actions sit in the row where the information appears.
- No Apply buttons: filters and settings take effect immediately.
- No confirmation dialogs for anything Undo can reverse. Keep dialogs for restore, reset, and deleting a category.
- Going back keeps scroll position and filters.
- Details save themselves. There is no separate edit mode.
- Primary controls stay in thumb reach on phones.

## Scope

Design these screens, using nested views, sheets, and dialogs where they fit better than full pages.

**Tier 1, highest polish, in light and dark mode**

- Home dashboard, on phone and desktop
- Add transaction: expense, income, transfer, on phone
- Transaction history, on phone and desktop
- Analytics, on phone and desktop
- Financial calendar, on phone and desktop

**Tier 2, full design**

- Needs Review list
- Monthly close
- Transaction details, directly editable, and search and filters
- Category and subcategory management
- Category analytics, monthly comparisons
- Daily calendar details
- Budgets, budget details
- Accounts, account details with reconciliation
- Savings goals, recurring transactions with a subscription total per month and year
- Notebook, note details
- Reports, report configuration, report preview

**Tier 3, same system, simpler layouts**

- Settings, appearance (light, dark, system, accent colour), regional, security
- Backup and data: automatic backups, export all data, import from a data file, bank statement CSV import
- Android home-screen quick-add widget, which shows no balances
- First launch, with a choice of starting empty, exploring demo data, or importing a data file, and creating the first account
- Empty, loading, and error states, confirmation dialogs, camera and photo permission prompts
- Backup status: healthy, overdue, failed

Do not design: bank connections, cloud sync, AI analysis, OCR, online sharing, debt or loan management, shopping lists, wishlists, warranty or tax tracking, rollover budgets, a weekly calendar view, custom budget periods, or dashboard customisation. These are later versions.

## Key screen requirements

**Home.** It answers, in this order: how much do I have, will I make it to payday, how is this month going, where is my money going, and what needs my attention.

1. Total balance with a change from last month. Tapping it expands every account's balance in place.
2. Payday forecast: the expected lowest balance before the next salary, based on the current balance, upcoming bills, and normal daily spending. Labelled as an estimate, with its calculation one tap away.
3. This month: income, spending, net, and savings rate.
4. Spending by category, top five, with a budget bar in each row that has a budget. Tapping a row opens its filtered transactions.
5. Needs attention: items to review, due recurring items, a balance check, budget warnings, overdue backup, monthly close when ready. At most three rows, each with its action in the row, such as Confirm. Hidden when empty.
6. Recent transactions.

Keep it under about two phone screens. Show one or two real insights, not a feed.

**Add transaction.** This is the most important interaction.

- It opens from anywhere as a sheet with the amount focused and an on-screen numeric keypad. The home-screen widget opens the same sheet directly.
- A common expense is two taps plus the digits: Add, amount, category chip. Tapping a category chip saves the entry immediately, so there is no Save button in the normal flow.
- Chips cannot be tapped until an amount is entered. Typing 12 means 12.00.
- Above the keypad, within thumb reach and from top to bottom: an optional merchant field, the Expense, Income, and Transfer switch with a colour cue for each, account and date pills, and the category chips.
- Expense is the default type. The date pill shows Today, and one tap offers Yesterday or a picker. Account defaults to the last used, and currency follows the account.
- Show up to six chips, which can be subcategories such as Groceries or Fuel, plus All, which opens a searchable list, and Later, which saves the entry to Needs Review with only the amount. Chips follow the selected account, and each account's chips keep a stable order that refreshes at most weekly, for muscle memory.
- Merchant memory: choosing a known merchant fills in its usual category and account, which the user can change, and a Save button appears.
- Tags, split, my share, a different currency, notes, and attachments sit behind a compact "More details" row. Once it is open, chips select instead of save, and a Save button appears.
- Time is recorded automatically and is not a field.
- After saving, the sheet closes and a confirmation shows Undo and Add Another for 5 seconds.
- Templates appear as a row at the top of the sheet. A fixed-amount template saves in one tap, and a variable one fills everything except the amount.
- Transfer shows From and To accounts, with the last used pair preselected. When currencies differ, it shows both amounts.
- Skip the payment method and location fields.

**Needs Review.** A short list of incomplete entries. Each row has category chips, so one tap finishes it, and the list shows a satisfying empty state when cleared.

**Monthly close.** A guided routine of about two minutes, offered at the end of each financial month: check account balances, clear Needs Review, confirm due bills, read a short summary, and optionally add a note.

**Transaction history.** Group by day, with a daily net in each group header. Provide sticky search and filter chips, and search also matches amounts. On phones, tapping a row opens its editable details, swiping deletes with Undo, and long-pressing starts multi-select with bulk actions. Details include Duplicate. Show receipt, split, my share, recurring, and refund indicators as small icons. On desktop, use a sortable, dense, read-only table with a details side panel.

**Analytics.** It opens on the current month with no setup. A shared date range selector and a clear comparison period stay at the top. Limit it to these eight views, across four sections:

- Overview: income and spending as grouped monthly bars, with a net line.
- Categories: donut limited to about six segments plus Other, always paired with a ranked list of values and changes. Selected categories as trend lines.
- Patterns: spending by weekday, largest transactions, fixed versus recurring versus variable costs.
- Progress: balance over time and savings rate.

Show each chart's question as its title, for example "Where did my money go?". Selecting any bar, slice, or point opens the exact transactions behind it. Insights must be computed from the sample data, and they show the figures they rely on.

**Calendar.** A month grid in which each day shows net amount and an activity marker. Spending intensity is a heat shade, always backed by a number or marker, never colour alone. Include markers for recurring items, for income, and for high-spending days, with a legend. Selecting a day shows totals, top category, transactions, a day note, and attachments: a bottom sheet on phones, a side panel on desktop. Add a Year heatmap.

**Budgets.** Monthly by default and following the chosen month start, with overall, category, and subcategory budgets, plus weekly budgets. Show limit, spent, remaining, percentage, a daily safe-to-spend figure, a marker for today's expected pace, and history. One warning state at 80% and one over-limit state at 100%.

**Accounts.** Prompt for a balance check regularly, especially for Cash. Show the drift from the last check as an "Untracked" amount.

**Notebook.** Light and quick: title, simple formatting, tags, search, attachments, and links to a transaction, category, account, date, budget, or goal. Calendar day notes are notebook entries linked to a date.

**Reports.** Last month is preselected, so a report takes one tap. The user can change the period and toggle sections, with a live preview. Output formats are PDF and CSV.

**Import.** Bank statement CSV import maps the columns, then compares the statement with existing entries and shows matched rows, missing rows to add, and likely duplicates.

**Backup and data.** One calm screen in Settings that feels trustworthy and simple. Backup, export, and transfer all use the same single file, a `.ledgerly` data file.

- Automatic backups: saved to a folder the user chooses outside the app, because uninstalling the app deletes its private data. Show last backup, what it contains (data, attachments, settings), size, verification status, and last restore test. Explain that a copy kept only on the phone will not survive losing the phone.
- Export all data: a clear primary action for keeping a safe copy or moving to another install. The user can include attachments, on by default, and add a password. The screen shows the estimated size, then saves through the system file picker or share sheet. The app then verifies the file by reading it back, and shows a result such as "2,418 transactions, 36 receipts, verified". A password needs a clear warning that it cannot be recovered.
- Import from a data file: available here and on first launch. Before anything changes, show a preview with the file's date, app version, and counts of transactions, accounts, and attachments, and ask for the password if there is one. Import replaces all current data, so it needs a typed or held confirmation, and the app takes a safety copy first and tells the user where it is.
- Import failures: a damaged file, a wrong password, or a file from a newer app version each get a plain message that says nothing was changed.
- Moving devices: after an import on a new device, explain that the new device is now the main one and the old copy will stop matching.
- Explain in one line that the file is an open format, and the data stays readable without Ledgerly unless a password is set.

**Security.** App lock is off by default and uses the phone's own device lock and biometrics. The automatic lock delay defaults to 5 minutes, so frequent use does not mean constant unlocking. One sentence explains that app lock hides the app and a password protects an exported file.

## Visual design

Calm, elegant, minimal, and information-rich without crowding. Avoid gradients as decoration, glassmorphism, oversized radii everywhere, and neon fintech styling.

**Light theme**

- Primary, deep forest green: #163D32
- Tint, soft mint: #E8F2EC
- Background, warm off-white: #F7F8F5
- Text, charcoal: #252C2A
- Warning, muted amber: #D9A441
- Expense and negative, soft coral: #D9685D

Adjust a colour only where it fails contrast, and darken text-sized uses of coral and amber to reach 4.5:1.

**Dark theme.** Design it separately, not as an inversion: deep green-tinted near-black background, layered surfaces, soft borders instead of shadows, off-white text, and slightly desaturated chart colours.

**Semantics.** Green is positive, coral is negative, amber is attention, neutral is transfers and supporting information. Always pair colour with a sign, icon, or label.

**Typography.** Inter throughout, with tabular numerals for all money. The balance is the largest element on the screen. Minimum text size is 12px, and 14px for body text.

**System.** Define and use consistent tokens for colour, type, an 8-point spacing scale, radii (8 to 16px), and elevation. Build reusable components: buttons, inputs, keypad, chips, cards, list rows, sheets, dialogs, navigation, progress bars, toasts, and chart containers. Touch targets are at least 44px, with main actions in thumb reach. Motion is subtle, short, and respects reduced-motion settings. Use one clean line icon set.

**Charts.** Use one consistent style with direct labels when possible, readable axes, tooltips, empty states, and text descriptions for screen readers. Use a categorical palette of up to six colours that stays distinct for colour-blind users. Avoid 3D, truncated bar axes, dual axes, and pie charts with many slices.

## Sample data

Generate one dataset and derive every figure from it, so that all totals, charts, calendar days, budgets, and reports agree. Never hard-code a figure that could contradict another screen.

- 14 months of history ending today, with realistic day-to-day variation and a few unusual months.
- Accounts: Main Bank (BAM), Euro Account (EUR), Savings (EUR), Cash (BAM), Credit Card (EUR, with a balance owed).
- Salary on the 28th of each month, occasional freelance income, rent, utilities, internet, phone, subscriptions, groceries, transport, dining, health, shopping, and travel.
- Include split transactions, refunds, transfers, ATM withdrawals, card payments, a dinner with a my-share amount still owed, recurring items in all three states, a few entries in Needs Review, an Untracked adjustment, several budgets with at least one over the limit, three goals, several notes, and a few receipts as placeholder images.
- Expense categories: Housing, Food, Transportation, Shopping, Health, Entertainment, Bills, Travel, Education, Personal Care, Gifts, Subscriptions, Other, with subcategories.
- Income categories: Salary, Freelance, Business, Investments, Rental Income, Gifts, Other.
- Use EUR and BAM formatted as €1,234.56 and 1,234.56 KM.

## Interactions that must work

1. Add an expense, then see the balance, history, budget, and calendar update.
2. Save an amount-only entry, then finish it from Needs Review.
3. Type a known merchant and see its category and account fill in.
4. Add income.
5. Add a transfer, and confirm that income and spending do not change.
6. Split a supermarket purchase of €85 into Groceries €60, Household €15, Personal Care €10.
7. Mark a €40 dinner with a €25 share, then record the €15 repayment.
8. Edit a transaction, and delete one with Undo.
9. Create a category while adding a transaction, without leaving the flow.
10. Attach a receipt (simulated).
11. Search and filter transactions.
12. Drill down from a chart segment to its transactions and then to one transaction's details.
13. Select a calendar date, then add a day note.
14. Create a budget.
15. Confirm a Due recurring payment.
16. Check an account balance and resolve the difference.
17. Complete a monthly close.
18. Import a bank statement CSV (simulated) and review the matches.
19. Export all data with a password (simulated), see the verified result, then import that file on the first launch screen and review its preview.
20. Try to import a damaged file (simulated) and see that nothing changed.
21. Configure and preview a report.
22. Switch light and dark mode, and resize across phone, tablet, and desktop layouts.

State changes may last for the session only. Actions that cannot really run in a prototype, such as file export, encryption, biometrics, widgets, and backup, must be simulated and clearly noted as simulated. Never present them as working.

## Deliverables

1. The clickable responsive prototype, in light and dark mode, starting on Home with demo data.
2. A short visual design system page.
3. A sitemap.
4. Closing notes: what is interactive, what is simulated, and any place where you recommend changing this brief.

Before finishing, check: can a common expense be saved in two taps plus the digits, can any account balance be seen in one tap from Home, can the data be exported and imported without confusion, does each Home section earn its place, do all figures agree across screens, are transfers and repaid shares excluded everywhere, is desktop clearly read-only, and does every chart lead to its transactions? Fix what fails.
