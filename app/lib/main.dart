// Starts Ledgerly: opens the database on this device, sets up backups, and shows the app.
// Restoring a backup reopens everything on the restored file, without restarting.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'app/app.dart';
import 'app/backup_controller.dart';
import 'app/providers.dart';
import 'core/clock.dart';
import 'data/backup/backup_service.dart';
import 'data/database/app_database.dart';
import 'data/database/connection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final file = await databaseFile();
  final folder = await backupFolder();
  runApp(AppRoot(databaseFile: file, backupFolder: folder));
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.databaseFile, required this.backupFolder});

  final File databaseFile;
  final Directory backupFolder;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _clock = SystemClock();
  late AppDatabase _db;
  late BackupService _backups;

  /// Changes after a restore, so every screen starts again on the restored data.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  void _open() {
    _db = openDatabase(widget.databaseFile);
    _backups = BackupService(folder: widget.backupFolder, clock: _clock, writeSnapshot: _db.snapshotTo);
  }

  /// Saves the current data as a safety copy, then swaps in the backup.
  Future<void> _restore(BackupFile backup) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safety = p.join(widget.backupFolder.path, 'ledgerly-before-restore-$stamp.sqlite');
    await widget.backupFolder.create(recursive: true);
    await _db.snapshotTo(safety);
    await _db.close();
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final extra = File('${widget.databaseFile.path}$suffix');
      if (extra.existsSync()) extra.deleteSync();
    }
    await backup.file.copy(widget.databaseFile.path);
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
