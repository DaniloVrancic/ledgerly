// The one database. Every read and write goes through it, through the repositories in
// lib/data/repositories. Nothing else touches SQLite.

import 'package:drift/drift.dart';

import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

const databaseFileName = 'ledgerly';

@DriftDatabase(
  tables: [Accounts, Categories, CategoryAccounts, Entries, Postings, Repeats, Goals, GoalMoves, Settings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump this and add a step in [migration] whenever a table changes.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX entries_day ON entries (day)');
      await customStatement('CREATE INDEX postings_entry ON postings (entry_id)');
      await customStatement('CREATE INDEX postings_account ON postings (account_id)');
      await customStatement('CREATE INDEX postings_category ON postings (category_id)');
      await seedDefaults(this);
    },
    onUpgrade: (m, from, to) async {
      // Add one step per schema version here, for example:
      // if (from < 2) await m.addColumn(entries, entries.someNewColumn);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Writes a consistent copy of the whole database to [path]. Safe while the app is in use.
  Future<void> snapshotTo(String path) => customStatement('VACUUM INTO ?', [path]);
}
