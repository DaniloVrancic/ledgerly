// Runs the real app on an in-memory database with a fixed date, for the widget tests.
//
// Everything stays inside the test's own clock: database calls are started, then the test
// pumps frames until they finish. Mixing in real time (runAsync) would deadlock with the
// app's live queries, which only move when the test pumps.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/backup_controller.dart';
import 'package:ledgerly/app/providers.dart';
import 'package:ledgerly/core/clock.dart';
import 'package:ledgerly/data/backup/backup_service.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';

class AppHarness {
  AppHarness._(this.tester, this.db, this.clock, this.backupDir);

  final WidgetTester tester;
  final AppDatabase db;
  final FixedClock clock;
  final Directory backupDir;
  late String bank;
  late String cash;

  /// A database with two accounts, before the app is shown.
  static Future<AppHarness> create(WidgetTester tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final h = AppHarness._(
      tester,
      AppDatabase(NativeDatabase.memory()),
      FixedClock(DateTime(2026, 10, 29, 12)),
      Directory.systemTemp.createTempSync('ledgerly_ui'),
    );
    final accounts = AccountRepository(h.db, h.clock);
    h.bank = await h.read(
      () => accounts.create(name: 'Main Bank', kind: AccountKind.bank, currency: 'EUR', openingMinor: 100000),
    );
    h.cash = await h.read(
      () => accounts.create(name: 'Cash', kind: AccountKind.cash, currency: 'BAM', openingMinor: 20000),
    );
    return h;
  }

  Future<void> show() async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    // Writes synchronously, so a backup never waits on real file time inside the test clock.
    final backups = BackupService(
      folder: backupDir,
      clock: clock,
      writeSnapshot: (path) async => File(path).writeAsStringSync('test'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
          backupServiceProvider.overrideWithValue(backups),
          restoreBackupProvider.overrideWithValue((_) async {}),
        ],
        child: const LedgerlyApp(),
      ),
    );
    await settle();
  }

  /// Pumps frames so database streams deliver and animations finish.
  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Runs a database call and pumps until it has finished.
  Future<T> read<T>(Future<T> Function() call) async {
    late T result;
    Object? error;
    var done = false;
    call().then(
      (v) {
        result = v;
        done = true;
      },
      onError: (Object e) {
        error = e;
        done = true;
      },
    );
    for (var i = 0; i < 200 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    if (error != null) throw error!;
    if (!done) throw StateError('A database call did not finish.');
    return result;
  }

  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox());
    await settle();
    await read(() => db.close());
    backupDir.deleteSync(recursive: true);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}
