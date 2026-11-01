# Ledgerly: usability review

This review assumes 10 to 20 uses a day. Most of those are recording an expense or a glance at a balance, so one wasted tap costs about 5,000 taps a year. Tap counts are design estimates, not user test results.

## Tap counts

"Digits" means typing the amount. Each count starts on Home unless noted.

| Task | Previous brief | Now | What changed |
|---|---|---|---|
| Common expense | Add, digits, chip, Save | Add, digits, chip | The chip saves |
| Repeat purchase with a fixed amount | Add, template, Save | Add, template | The template saves |
| Expense from outside the app | Open app, Add, digits, chip, Save | Widget, digits, chip | Widget opens the keypad |
| Several expenses in a row | Save and Add Another button | "Add another" in the confirmation | One less button on the sheet |
| Expense yesterday | Add, digits, date, picker, chip, Save | Add, digits, "Yesterday" pill, chip | The date is one tap |
| See one account's balance | More, Accounts | Tap the balance | Expands in place |
| See a category's budget | More, Budgets, find it | 0 taps | Bar shown on the Home category row |
| Confirm a due bill | Open it, Confirm | Confirm on Home | Action sits in the row |
| Fix a transaction's category | Row, Edit, Category, pick, Save | Row, Category, pick | Details are directly editable and save themselves |
| Delete a transaction | Swipe, confirm dialog | Swipe | Undo replaces the dialog |
| See what's behind a category | Analytics, segment | Tap the Home category row | Filtered list opens directly |
| Finish an unreviewed entry | Open it, category, Save | Tap the chip in the row | Chips sit in the row |

## Removed

**Input fields**
- Save button on the Add sheet, unless More details is open
- Time, now recorded automatically
- Currency, now follows the account and only appears when different
- Separate subcategory step, because chips can be subcategories such as Groceries or Fuel
- Payment method and location

**Screens and transitions**
- The separate Edit screen, merged into transaction details
- The Accounts trip for a quick balance check
- Apply buttons on filters, which now apply instantly
- Setup before Analytics, which opens straight on the current month

**Dialogs**
- Single-delete confirmation, replaced with Undo. Dialogs stay only for actions Undo can't reverse, such as restore, reset, or deleting a category.

## Rules for the design

1. **Chips stay where they are.** The order refreshes at most once a week. A list that reorders on every use would defeat muscle memory, so being stable matters more than being perfectly ranked.
2. **Controls stay in thumb reach.** The type switch, chips, and account and date pills sit directly above the keypad.
3. **A chip commits.** Undo stays visible for 5 seconds, and a chip can't be tapped until an amount is entered, to prevent saving by accident. Once More details is open, chips only select and a Save button appears.
4. **Later is a chip.** It saves the entry to Needs Review, which keeps amount-only saving within the same two-tap pattern.
5. **A whole number needs no decimals.** Typing 12 means 12.00.
6. **Search finds amounts too.** Typing 12.50 matches amounts, so a transaction can be found from a receipt.
7. **Back keeps your place.** Scroll position and filters survive drilling down and returning.
8. **Lock delay defaults to 5 minutes** when app lock is on, so frequent use doesn't mean constant unlocking.
9. **The widget shows no balance.** It's a one-tap entry point, so nothing private sits on the home screen.

## Accepted trade-offs

- A mistaken chip tap saves the wrong category. That costs one Undo or one correction, and it's rare next to the saving on every entry.
- Income takes one extra tap, because Expense is the default. Income is a few entries a month.
- Adding a description before saving takes one extra tap. Merchant memory only helps when a merchant is entered, so some history will have no merchant. That's acceptable for speed, and Needs Review doesn't ask for one.
