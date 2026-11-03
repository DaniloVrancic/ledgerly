// Starts Ledgerly: opens the database on this device, sets up backups, and shows the app.
// Restoring a backup reopens everything on the restored file, without restarting.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/backup_controller.dart';
import 'app/providers.dart';
import 'core/clock.dart';
import 'data/backup/backup_service.dart';
import 'data/backup/backup_store.dart';
import 'data/database/app_database.dart';
import 'data/database/connection.dart';
import 'data/repositories/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final clock = SystemClock();
  final file = await databaseFile();
  final folder = await backupFolder();
  final work = Directory(p.join((await getTemporaryDirectory()).path, 'ledgerly-work'));
  final db = openDatabase(file);
  // Backups go to the folder the person chose, or the default one when it is out of reach.
  final chosen = await SettingsRepository(db, clock).read(SettingKeys.backupFolder);
  final resolved = await resolveBackupStore(chosen, folder);
  // A restore opens a new database; backups always snapshot the one that is open.
  var live = db;
  runApp(
    AppRoot(
      databaseFile: file,
      database: db,
      clock: clock,
      onOpened: (opened) => live = opened,
      backups: BackupService(
        store: resolved.store,
        defaultStore: LocalFolderStore(folder),
        usingFallback: resolved.fallback,
        workDir: work,
        clock: clock,
        writeSnapshot: (path) => live.snapshotTo(path),
      ),
    ),
  );
}

class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.databaseFile,
    required this.database,
    required this.clock,
    required this.backups,
    required this.onOpened,
  });

  final File databaseFile;

  /// Opened in main, before the app is shown.
  final AppDatabase database;
  final SystemClock clock;
  final BackupService backups;

  /// Told about the database a restore opens.
  final ValueChanged<AppDatabase> onOpened;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late AppDatabase _db = widget.database;
  late final BackupService _backups = widget.backups;
  SystemClock get _clock => widget.clock;

  /// Changes after a restore, so every screen starts again on the restored data.
  int _generation = 0;

  void _open() {
    _db = openDatabase(widget.databaseFile);
    widget.onOpened(_db);
  }

  /// Saves the current data as a safety copy, then swaps in the backup.
  Future<void> _restore(BackupFile backup) async {
    final restored = await _backups.fetch(backup);
    await _backups.saveSafetyCopy('restore');
    await _db.close();
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final extra = File('${widget.databaseFile.path}$suffix');
      if (extra.existsSync()) extra.deleteSync();
    }
    await restored.copy(widget.databaseFile.path);
    await restored.delete();
    setState(() {
      _open();
      _generation += 1;
    });
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey(_generation),
    overrides: [
      databaseProvider.overrideWithValue(_db),
      clockProvider.overrideWithValue(_clock),
      backupServiceProvider.overrideWithValue(_backups),
      restoreBackupProvider.overrideWithValue(_restore),
    ],
    child: const LedgerlyApp(),
  );
}
