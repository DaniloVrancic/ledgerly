> **Implementation brief.** Add split payments to the Flutter app in `app/`: one expense divided across several
> expense categories on one account, saved as one entry with one categorised posting per part. Add `splitPostings`,
> `splitRefundPostings` and `allocate` in `domain/postings.dart`, `addSplit` and `changeSplit` in `EntryRepository`,
> the query fixes for statement matching, amount search and title memory, then the Add sheet switch, the details card
> and the list rows. No schema change. Keep the two-tap add flow and the money rules in `CLAUDE.md`. Follow Steps in
> order (2 PRs from `develop`), run Verification commands, and do not commit.

# Ledgerly: split payments, in 2 pull requests

## Status

approved

## Goal

Let one expense be divided across several categories or subcategories, such as a Mercator receipt split between
Groceries, Household and Cosmetics. Each part counts as spending in its own category everywhere: Insights, Budgets,
the calendar and the payday forecast. `app/README.md` lists this under "Not built yet". The postings model already
allows several categorised postings per entry, so the work is a domain builder, the repository write path, fixes in
the queries that assume one posting per entry and account, and the screens.

## Non-goals

- Splitting income, transfers, refunds or balance checks. Only an expense can be split.
- Combining a split with "My share" in one entry. While a split is on, the My share field is hidden.
- Split repeats. A repeat keeps one category. While a split is on, Repeat is set to Never and disabled.
- Changing the account of a split entry in place. As today for entries with several postings, delete and add again.
- Purchases in a third currency (the other half of the README line). That line stays, reworded.
- Any schema change or migration. `Entries` and `Postings` stay as they are.

## Requirements and acceptance criteria

| # | Requirement | Acceptance criterion |
| --- | --- | --- |
| R1 | A split expense is saved as one entry, with one categorised posting per part on the same account | `addSplit` with parts 30.00 Groceries + 12.50 Household on Main Bank creates 1 entry and 2 postings. The balance drops by 42.50. October spending is 42.50, with Food 30.00 and Shopping 12.50 |
| R2 | The parts' EUR values are frozen and always add up exactly to the whole payment's EUR value | A 10.00 KM split into 3.33 + 3.33 + 3.34 KM stores base values that add up to `toBase(1000, 'BAM')`. Each part is within 1 cent of `toBase(part)` |
| R3 | Invalid splits are refused with a plain message | Parts that don't add up to the amount, a part at zero or below, a missing category, the same category twice, or a non-expense category throw `RuleException` and write nothing |
| R4 | Add sheet: "Split across categories" under More details, expense only | Turning it on shows part rows (category + amount + remove), a Remaining / Fully split / Over by line and "Add a part". Save is enabled only when the parts are fully split and each has a category. The saved title defaults to "Split purchase" |
| R5 | The two-tap flow is unchanged | Add, digits and a chip still save at once with More details closed. The existing `flows_test.dart` passes unchanged |
| R6 | Lists show a split as one row | `EntryTile` shows the `split` icon on a neutral tile and "Split across N categories · <account>" in Home Recent, Entries and the calendar day sheet |
| R7 | Entry details shows the parts and edits them | A split shows "Split across N categories" with each part's category and amount instead of the single category picker. "Edit split" opens the same editor. A simple expense offers "Split this". Saving replaces the parts, the total may change, and Undo brings the old parts back exactly |
| R8 | A split or a split's refund can't be collapsed by accident | `changeCategory` on any entry with more than one categorised posting throws `RuleException('Edit the parts of this split instead.')`. A split's refund shows its parts read-only in details, with no category picker, and its row says "Refund across N categories". Editing a split down to one part turns it back into a simple entry |
| R9 | A refund of a split lowers each part's category in proportion | Refunding 10.00 of a 30.00 Groceries + 10.00 Household split gives postings +7.50 Groceries and +2.50 Household. The parts add up exactly to the refund, using the largest remainder |
| R10 | Statement matching sees an entry's whole amount on an account | `signedAmountsOnAccount` returns one row per entry and account, with the postings summed. A 42.50 split matches a −42.50 statement row. This also fixes shared expenses, which today return two partial rows |
| R11 | Searching for an amount finds a split by its total or by a part | Searching "42.50" and "12.50" both find the split above |
| R12 | Title memory ignores split entries | A split titled "Mercator" adds no `TitleUse` rows, so typing "Mercator" never brings back one part's category or amount |
| R13 | In the Entries list filtered by a category, day totals count only that category's parts | Filtered by Food, the day header for the split above shows −30.00, not −42.50 |
| R14 | Export and import keep splits | A `.ledgerly` file built from a ledger with a split reads back with the same posting count, and after import the split's totals are unchanged |
| R15 | Docs | `app/README.md` Features gains split payments. "Not built yet" keeps only "Purchases in a third currency. The postings model supports it; only the screens are missing." |

## Design overview

### Domain (`app/lib/domain/postings.dart`)

```dart
/// One part of a split expense, in the account's currency.
class SplitPart {
  const SplitPart(this.categoryId, this.amountMinor);
  final String categoryId;
  final int amountMinor;
}

/// Divides [total] in proportion to [weights] so the results add up exactly to [total].
/// Largest remainder; ties go to the earlier weight. Weights must be positive.
List<int> allocate(int total, List<int> weights);

/// An expense divided across categories, all on one account. The EUR value of the whole
/// payment is frozen once and divided over the parts, so nothing is lost to rounding.
List<PostingDraft> splitPostings({
  required String accountId,
  required String currency,
  required int amountMinor,
  required List<SplitPart> parts,
});

/// Money back for a split expense, divided over its categories like the parts.
List<PostingDraft> splitRefundPostings({
  required String accountId,
  required String currency,
  required int amountMinor,
  required List<SplitPart> parts,
});
```

- `splitPostings` checks that `parts` isn't empty, each part is above zero, there are no duplicate categories, and the
  parts add up to `amountMinor`. Otherwise it throws `RuleException` with "Each part needs an amount above zero.",
  "Each part needs a different category." or "The parts must add up to the amount.". Each part's base is
  `-allocate(toBase(amountMinor, currency), amounts)[i]`. With one part it returns the same as `entryPostings`.
- `splitRefundPostings` allocates `amountMinor` over the parts' amounts, then sets each posting's base to
  `allocate(toBase(amountMinor), refundParts)`. Postings are positive, one per category.
- The category kind check (expense only) stays in the repository, which reads categories. The domain stays without
  database imports.
- Update the header comment with `Split           Bank −30 on Groceries, Bank −12.50 on Household`.

### Entry view (`app/lib/data/repositories/entry_view.dart`)

```dart
/// Postings with a category: one for a simple entry, one per part for a split.
List<Posting> get parts;           // postings.where(categoryId != null)
/// An expense whose amount is divided over more than one category, without "Owed to me".
bool get isSplit;                  // type == expense && parts.length > 1 && no owedToMe posting
/// More than one categorised posting: a split, or the refund of one.
bool get hasParts;                 // parts.length > 1
/// What counts in the categories [include] accepts, in EUR. For filtered lists.
int countedBaseMinorWhere(bool Function(String categoryId) include);
```

`isSimple`, `categoryId` and `shareMinor` stay as they are. For a split, `shareMinor` is null because there is no
"Owed to me" posting.

### Repository (`app/lib/data/repositories/entry_repository.dart`)

- `Future<(String, Undo)> addSplit({required String accountId, required List<SplitPart> parts, String? title,
  String? merchant, String? note, String? day})`. The amount is the sum of the parts. It checks every category exists
  with kind `expense` and isn't deleted (`_expenseCategories(ids)`), builds `splitPostings`, and calls `_insert` with
  `type: expense` and a title that defaults to `'Split purchase'`.
- `splitPostings` takes an optional `int? baseMinor`. When given, that frozen EUR value is divided instead of
  `toBase(amountMinor, currency)`.
- `Future<Undo> changeSplit(String id, List<SplitPart> parts)`. Only for an expense that isn't in Needs Review and has
  no "Owed to me" posting (otherwise `RuleException('Only an expense can be split.')`). In one transaction it
  soft-deletes the entry's current postings (`deletedAt = now`), inserts the new ones from `splitPostings` on the same
  account and currency, and touches the entry. When the new parts add up to the old amount, it passes the entry's old
  frozen base (the sum of the old categorised postings' `baseMinor`) as `baseMinor`, so history isn't recalculated.
  Only a changed total is frozen again, as `changeAmountOrAccount` does today. Undo is one transaction: it hard-deletes the new posting ids (they never
  existed before, like `purge`), then `_restore(before)`, which writes the old postings back with `deletedAt` null.
  Soft-deleting keeps a sync able to send the change.
- `changeCategory`: if `before.hasParts`, throw `RuleException('Edit the parts of this split instead.')`.
- `addRefund`: if `of.isSplit`, use `splitRefundPostings` with the parts taken from `of.parts` (amounts as positive
  numbers). Otherwise unchanged.
- `signedAmountsOnAccount`: `SELECT e.id, e.day, SUM(p.amount_minor) AS amount ... GROUP BY e.id`. The account filter
  already limits it to one account per entry.
- `watchEntries` amount search: match one posting (as today) or the entry's sum on one account. Pass `[amount, amount]`
  to `add(...)`:

  ```sql
  (EXISTS (SELECT 1 FROM postings p WHERE p.entry_id = e.id AND p.deleted_at IS NULL AND ABS(p.amount_minor) = ?)
   OR EXISTS (SELECT 1 FROM postings p WHERE p.entry_id = e.id AND p.deleted_at IS NULL
              GROUP BY p.account_id HAVING ABS(SUM(p.amount_minor)) = ?))
  ```
- `watchTitleMemory`: add `AND (SELECT COUNT(*) FROM postings q WHERE q.entry_id = e.id AND q.category_id IS NOT NULL
  AND q.deleted_at IS NULL) = 1` to the `WHERE`.
- `duplicate` copies postings as they are and already works for splits. Add a test.
- `watchTotals`, `watchDayTotals`, `watchSubcategoryTotals`, `watchEverydaySpending`, the budget spending query and
  the category delete in `category_repository.dart` all work per posting and need no change. Tests prove it (below).

### Screens

- **`app/lib/features/entries/split_editor.dart` (new).** `class SplitEditor extends StatelessWidget` with
  `parts` (a `List<SplitDraft>`, each holding a `categoryId` and a `TextEditingController`), `totalMinor`, `currency`,
  `accountId` and `onChanged`. Each row has a category button (opens `pickCategory(context, kind: 'expense',
  accountId: accountId)`), an amount field (`TextInputType.numberWithOptions(decimal: true)`, parsed with
  `parseAmount`) and an `x` icon button to remove it ("Remove part N"). Below: the Remaining / Fully split / Over by
  line in `c.positive` when fully split and `c.warning` otherwise, and an `OutlinedButton.icon` "Add a part". It also
  exports `List<SplitPart>? splitPartsOf(List<SplitDraft>, int totalMinor)`, which returns null unless every part has
  a category and an amount above zero and the parts add up to `totalMinor`.
  It also exports `Future<List<SplitPart>?> showSplitSheet(BuildContext context, {required EntryView entry})`, a modal
  bottom sheet with the editor, an amount field for the new total (starts at the entry's amount) and Save. On opening
  it merges parts that share a category, which happens after a category delete moves postings, so the result always
  passes `splitPostings`. For a simple expense it starts with the entry's category and amount plus one empty part.
- **Add sheet (`add_entry_sheet.dart`).** State `List<SplitDraft>? _split`. In `_moreDetails()`, for an expense, a
  `SwitchListTile` "Split across categories". Turning it on creates two parts: the chosen chip's category (or none)
  with the whole amount, and an empty one. It sets `_repeat = null`, disables the Repeat segments and hides the
  My share field and the Later chip. Switching the kind away from expense or turning the switch off sets
  `_split = null`. Parts don't follow the keypad after the switch is turned on; the Remaining line shows what's left.
  `_needsSave` becomes `_more || _remembered || _kind == EntryKind.transfer || _split != null`, so closing More
  details while split is on never lets a chip tap save a single-category entry. `_remember` leaves `_repeat` alone
  while split is on, including in its async `findByTitle` callback. `_canSave` becomes
  `_split != null ? splitPartsOf(_split!, _minor) != null && !_saving : <today's rule>`. `_save()` gets a branch
  before the category check: when `_split != null`, call `entries.addSplit(...)` and finish with
  `'Saved ${formatMoney(_minor, account.currency)}, $title, split across ${parts.length}'`. Picking a chip while
  split is on sets the first part's category instead of saving. Dispose the part controllers.
- **Entry details (`entry_details_screen.dart`).** When `v.hasParts`, replace the category card with a `LedgerCard`
  titled "Split across N categories". It lists each part with `CategoryAvatar.of(book[p.categoryId], size: 24)`,
  `book.fullName` and `formatMoney(-p.amountMinor, p.currency)`, plus an "Edit split" button only when `v.isSplit` (a refund's parts are read-only). For a simple expense
  that isn't in Needs Review, add an `OutlinedButton.icon` "Split this" next to Duplicate. Both open `showSplitSheet`
  and on a result call `_run(() => repo.changeSplit(v.id, parts), 'Split saved')`. The refund dialog text for a split
  becomes "It lowers spending in each of its categories and is never income."
- **`EntryTile` (`app/lib/ui/widgets/entry_tile.dart`).** Before the `shareMinor` branch: `else if (view.hasParts)
  meta = '${view.type == EntryType.refund ? 'Refund' : 'Split'} across ${view.parts.length} categories · $account'`.
  The amount stays the whole payment, also in a category-filtered list, because the row stands for the whole entry. Lead, when `view.hasParts`: a neutral 40×40 tile with
  `LedgerIcon('split', color: c.neutral, semanticLabel: 'Split')`, built like the transfer tile.
- **Entries list (`entries_screen.dart`).** When the query has a `categoryId`, the day header uses
  `v.countedBaseMinorWhere((id) => id == q.categoryId || book.topOf(id) == q.categoryId)`, using the existing
  `CategoryBook.topOf(id)`, which returns the parent or the id itself. `category_insight_screen.dart` embeds this list
  with a `categoryId` query, so its day totals match its category figure through the same change.

## Steps (one PR each, in order)

Each PR branches from `develop`, targets `develop` and is merged with a merge commit.

### PR 1 `feat/split-core`: split postings, repository and query fixes (6 files)

1. `app/lib/domain/postings.dart`: `SplitPart`, `allocate`, `splitPostings`, `splitRefundPostings` and the header
   line.
2. `app/lib/data/repositories/entry_view.dart`: `parts`, `isSplit`, `countedBaseMinorWhere`.
3. `app/lib/data/repositories/entry_repository.dart`: `addSplit`, `changeSplit`, `_expenseCategories`, and the guards
   and fixes in `changeCategory`, `addRefund`, `signedAmountsOnAccount`, the `watchEntries` amount search and
   `watchTitleMemory`.
4. `app/test/domain/postings_test.dart`: tests for `allocate`, `splitPostings` and `splitRefundPostings` (below).
5. `app/test/data/entry_repository_test.dart`: repository tests (below).
6. `app/test/data/ledgerly_file_test.dart`: a split survives the file (R14).

Verify: `dart analyze` is clean, and `flutter test test/domain test/data` passes.

### PR 2 `feat/split-screens`: split on the Add sheet, in details and in lists (7 files)

1. `app/lib/features/entries/split_editor.dart` (new): `SplitDraft`, `SplitEditor`, `splitPartsOf`, `showSplitSheet`.
2. `app/lib/features/add_entry/add_entry_sheet.dart`: the switch, state, save branch and the Repeat and My share
   rules.
3. `app/lib/features/entries/entry_details_screen.dart`: the parts card, Edit split, Split this, the refund text.
4. `app/lib/ui/widgets/entry_tile.dart`: the split meta and icon.
5. `app/lib/features/entries/entries_screen.dart`: filtered day totals (R13).
6. `app/test/ui/split_test.dart` (new): widget tests (below), using `app_harness.dart`.
7. `app/README.md`: Features and "Not built yet" (R15).

Verify: `dart analyze` is clean, `flutter test` passes, including the existing `flows_test.dart` and
`small_screen_test.dart`, and a manual run on Windows (`flutter run -d windows`) saves, edits, refunds and deletes a
split.

## Tests

`app/test/domain/postings_test.dart`:

- `allocate(1000, [1, 1, 1])` is `[334, 333, 333]`; `allocate(511, [3000, 1250])` adds up to 511; zero total gives
  zeros.
- A EUR split: the bases equal the parts.
- A BAM split of 1000 into 333 + 333 + 334: the bases add up to `toBase(1000, 'BAM')`.
- It refuses parts that don't add up, a part at zero, and a duplicate category. `checkBalanced` passes on the result.
- A refund of 1000 over parts 3000 + 1000 gives +750 and +250.

`app/test/data/entry_repository_test.dart`:

- R1: `addSplit` balance, spending, spending by category, and one entry with two postings.
- R3: an income category in a part is refused, and nothing is written (count entries before and after).
- R7: `changeSplit` replaces the parts and can change the total. Undo restores the original postings and totals, and
  leaves no extra postings (count all postings, deleted included).
- R7: `changeSplit` to one part makes `isSplit` false and `isSimple` true.
- R8: `changeCategory` on a split throws, and so does it on a split's refund.
- `changeSplit` with the same total keeps the old frozen base values. Insert a BAM split through `l.db` directly with a stored base one
  cent off `toBase`, re-split it, and check that the sum of bases is unchanged.
- R9: a refund of a split lowers each category in proportion, and income stays zero.
- R10: `signedAmountsOnAccount` returns one row of −4250 for the split, and one row of the full amount for a shared
  expense.
- R11: `watchEntries(EntryQuery(search: '42.50'))` and `'12.50'` both find it.
- R12: `watchTitleMemory` has no "Mercator" after a split titled "Mercator".
- Budgets: a Food monthly budget's spent equals the Groceries part only (through `BudgetRepository` as in
  `budget_repository_test.dart`).
- `watchDayTotals` for the day: spent equals the whole split and the count is 1.
- `duplicate` of a split gives a split with the same parts, dated today.

`app/test/data/ledgerly_file_test.dart`: add a split to the seeded ledger, build and read the file. The manifest
`counts` don't include postings, so open `preview.extractedDb` with `sqlite3.open(path, mode: OpenMode.readOnly)`, as
the file reader already does, and check that the split's entry still has 2 postings with the same `base_minor` values.

`app/test/ui/split_test.dart`:

- Add sheet: type 42.50, open More details, turn on Split, set Groceries 30.00 and Household 12.50. Save is disabled
  until it's fully split. After Save, Entries shows one row "Split across 2 categories".
- With Split on, Repeat is disabled, and My share and Later are hidden. Closing More details and tapping a chip
  doesn't save.
- Entry details of a split shows both parts. Choosing "Edit split", removing a part and saving makes it a simple entry.
- The two-tap flow test in `flows_test.dart` is unchanged and still passes.

## Verification commands

Run from `app/`, with Flutter at `E:\SDK\flutter-3.47.9`:

```bash
dart analyze
flutter test
flutter run -d windows
```

## Risks, migration, compatibility, security

- **No schema change.** Old databases and `.ledgerly` files from 1.0 read as before. A file with splits opened by 1.0
  shows the entry with its first category in lists and in correct totals, because totals are per posting. Nothing
  breaks.
- **Statement matching change (R10)** changes behaviour for shared expenses: they now match on the amount paid. That
  is the correct amount, and it fixes a bug.
- **Undo of `changeSplit`** must remove the new postings, or totals would double. Test it with a count that includes
  deleted rows.
- **Rounding.** Only `allocate` divides money. Every caller checks the sum in tests.
- **Small screens.** Part rows on a 360 px phone with large text: the amount field is a fixed 110 px, and the
  category button is `Expanded` with ellipsis. `small_screen_test.dart` covers the Add sheet, so extend it if it
  overflows.
- **Security.** No new permissions, network or files.

## Open questions

- None blocking. Whether "Split this" belongs in the action row or under the category card is a visual choice. The
  spec puts it next to Duplicate.

## Decision log

- **D1. No schema change.** Parts are categorised postings on the entry's account, which the table already allows.
- **D2. Proportional refunds (R9).** The rule says refunds lower spending in their category, and a split has several.
  Asking which part was refunded adds a step for a rare case. Proportional is exact and needs no choice. A person can
  still record a refund and then edit it, which isn't covered here.
- **D3. No split with My share or Repeat.** Both carry one category today (the share posting, `Repeats.categoryId`).
  Combining them needs new data, so it's left out, and the UI makes it impossible.
- **D4. Title memory skips splits (R12).** Otherwise it would suggest one part's category and amount for the title.
- **D5. Soft-delete old postings in `changeSplit`.** That keeps the sync rule (soft `deletedAt`, `updatedAt`).
  Undo hard-deletes only the postings it just created, as `purge` does for a fresh save.
- **D6. Two PRs.** Core with tests first, then screens. This matches the repo's PR size, about 10 files at most.

## Review trail

| Round | Critic | Verdict | Issues |
| --- | --- | --- | --- |
| 1 | self (fallback). The NVIDIA models failed twice: kimi-k2.6 and deepseek-v4.1-flash have reached end of life (HTTP 410), and nemotron-3-ultra returned an empty answer | REQUEST_CHANGES | 7 blocking, all fixed: a split's refund could be collapsed by the category picker (added `hasParts`, R8); closing More details let a chip save a single-category entry (`_needsSave`); title memory's async repeat could re-enable Repeat; the Later chip was reachable while split was on; `changeSplit` re-froze the EUR value of an unchanged total (old base kept); the R14 test relied on posting counts the manifest doesn't have; duplicate categories after a category delete would block editing (merged on open). 1 minor: the keypad-follow rule was ambiguous, so it was removed |
| 2 | self (fallback) | APPROVE | 0 blocking. 1 minor, fixed: the category insight screen gets the R13 day totals through the shared list |

