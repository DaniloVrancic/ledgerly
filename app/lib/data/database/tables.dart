// The database tables. Run `dart run build_runner build` after changing this file.
//
// Every synced record has a UUID id, created and updated times, and a soft delete time.
// A later sync only needs to send rows whose updatedAt changed, deletions included.

import 'package:drift/drift.dart';

mixin SyncColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A bank account, cash, a card or savings. Its balance is always calculated from postings.
class Accounts extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// bank, cash, card, savings, or system for the hidden "Owed to me" account.
  TextColumn get kind => text()();

  /// EUR or BAM.
  TextColumn get currency => text()();
  IntColumn get openingMinor => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// The day of the last balance check.
  TextColumn get checkedOn => text().nullable()();
}

/// A category or, when [parentId] is set, a subcategory. One level of subcategories only.
/// Named LedgerCategory in Dart, because Flutter already has a class called Category.
@DataClassName('LedgerCategory')
class Categories extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 32)();

  /// expense, income, or system for Untracked, which reports leave out.
  TextColumn get kind => text()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  /// A name from the line icon set.
  TextColumn get icon => text()();

  /// A person's own image, stored as a file in the app's folder.
  TextColumn get imagePath => text().nullable()();

  /// 1 to 12 from the curated colours, 0 for neutral.
  IntColumn get colorSlot => integer().withDefault(const Constant(0))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Limits a category to some accounts on the Add sheet. No rows means every account.
/// History and reports never read this, so changing it never hides past entries.
class CategoryAccounts extends Table with SyncColumns {
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
}

/// An entry the person recorded: an expense, income, transfer, refund or balance check.
class Entries extends Table with SyncColumns {
  /// expense, income, transfer, refund, adjustment.
  TextColumn get type => text()();

  /// The local calendar day, "YYYY-MM-DD".
  TextColumn get day => text()();

  /// What the entry was, such as "Groceries" or "Netflix". Remembered and suggested later.
  TextColumn get title => text().nullable()();

  /// Optional, such as "Konzum".
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Title, merchant and note in lower case without diacritics, so "cevapi" finds "Ćevapi".
  TextColumn get searchText => text().withDefault(const Constant(''))();

  /// Saved with only an amount, waiting in Needs Review for a category.
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
  TextColumn get refundOfId => text().nullable()();

  /// Set when the entry is a paid repeat. One entry per repeat and date.
  TextColumn get repeatId => text().nullable()();
  TextColumn get repeatDay => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {repeatId, repeatDay},
  ];
}

/// The money movements of an entry. Income and spending only ever come from postings with a
/// category, so transfers are excluded by construction.
class Postings extends Table with SyncColumns {
  TextColumn get entryId => text().references(Entries, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// In the account's currency. Negative leaves the account.
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();

  /// The EUR value, frozen when recorded and never recalculated.
  IntColumn get baseMinor => integer()();
}

/// Something that comes back, such as rent or Netflix. It turns Due on [nextDay] and waits.
class Repeats extends Table with SyncColumns {
  TextColumn get title => text().withLength(min: 1, max: 60)();

  /// expense or income.
  TextColumn get kind => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  IntColumn get amountMinor => integer()();

  /// daily, weekly, monthly, yearly.
  TextColumn get every => text()();
  TextColumn get nextDay => text()();

  /// Keeps monthly repeats on the 31st even after a shorter month.
  IntColumn get anchorDay => integer()();

  /// The amount changes each time, like electricity. Mark paid asks for this time's amount.
  BoolColumn get varies => boolean().withDefault(const Constant(false))();
}

/// Something the person is saving for. Money set aside stays in its account but is no longer
/// free to use.
class Goals extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get icon => text()();
  IntColumn get colorSlot => integer().withDefault(const Constant(0))();
  IntColumn get targetMinor => integer()();

  /// Optional deadline. With it, the app shows how much to set aside each month.
  TextColumn get targetDay => text().nullable()();

  /// Where the money is kept, such as Savings. Only for information.
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// Set when the goal is finished or given up. Its money is free again.
  DateTimeColumn get closedAt => dateTime().nullable()();
}

/// Money set aside for a goal, or taken back out when negative. Amounts are in EUR.
class GoalMoves extends Table with SyncColumns {
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get day => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get note => text().nullable()();
}

/// A spending limit for every month (following the chosen month start) or every week
/// (Monday to Sunday). Without a category it covers all spending. Amounts are in EUR.
class Budgets extends Table with SyncColumns {
  /// A category or subcategory, or null for all spending.
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get limitMinor => integer()();

  /// monthly or weekly.
  TextColumn get every => text()();
}

/// Preferences on this device. Not synced.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
