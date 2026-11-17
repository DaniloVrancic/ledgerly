// Keeps the list of backups current and runs the automatic backup when it is due.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup/backup_service.dart';
import '../data/database/connection.dart';
import '../data/export/ledgerly_file.dart';
import '../data/repositories/settings_repository.dart';
import 'providers.dart';

class BackupState {
  const BackupState({required this.files, this.lastError, this.working = false});

  /// Newest first, at most three.
  final List<BackupFile> files;
  final String? lastError;
  final bool working;

  BackupFile? get latest => files.isEmpty ? null : files.first;
}

class BackupController extends Notifier<BackupState> {
  BackupService get _service => ref.read(backupServiceProvider);

  @override
  BackupState build() {
    Future.microtask(refresh);
    return const BackupState(files: []);
  }

  /// Reads the list of backups again.
  Future<void> refresh() async {
    final files = await _service.list();
    state = BackupState(files: files, lastError: state.lastError, working: state.working);
  }

  /// Called when the app starts and whenever it comes back to the front.
  Future<void> runIfDue() async {
    if (state.working || !await _service.isDue()) return;
    await backUpNow();
  }

  Future<void> backUpNow() async {
    state = BackupState(files: state.files, working: true);
    try {
      await _service.backUpNow();
      state = BackupState(files: await _service.list());
    } catch (e) {
      state = BackupState(
        files: await _service.list(),
        lastError: 'The backup could not be written: $e. Your data is safe on this device.',
      );
    }
  }

  /// Asks for a folder and makes it the backup folder. The current backups are copied there,
  /// so the 3-file rule carries on. Returns what happened, or null when nothing was chosen.
  Future<String?> chooseFolder() async {
    final settings = ref.read(settingsRepositoryProvider);
    final previous = ChosenFolder.fromJson(await settings.read(SettingKeys.backupFolder));
    final chosen = await ref.read(pickBackupFolderProvider)(previous);
    if (chosen == null) return null;
    final store = chosen.store;
    if (!await canUse(store)) {
      throw const FileSystemException('Ledgerly cannot write to that folder. Choose another one.');
    }
    var copied = 0;
    if (store.displayName != _service.store.displayName) {
      for (final b in await _service.list()) {
        final file = await _service.fetch(b);
        await store.put(b.name, file);
        await file.delete();
        copied += 1;
      }
    }
    await settings.write(SettingKeys.backupFolder, chosen.toJson());
    _service
      ..store = store
      ..usingFallback = false;
    await refresh();
    return copied == 0
        ? 'Backups now go to ${chosen.name}'
        : 'Backups now go to ${chosen.name}. $copied ${copied == 1 ? 'backup was' : 'backups were'} copied there.';
  }

  /// Goes back to Ledgerly's own backup folder. Files in the chosen folder stay where they are.
  Future<void> useDefaultFolder() async {
    await ref.read(settingsRepositoryProvider).write(SettingKeys.backupFolder, '');
    _service
      ..store = _service.defaultStore
      ..usingFallback = false;
    await refresh();
  }
}

final backupControllerProvider = NotifierProvider<BackupController, BackupState>(BackupController.new);

/// Opens the system's folder picker. A provider, so tests can choose a folder.
final pickBackupFolderProvider = Provider<Future<ChosenFolder?> Function(ChosenFolder? previous)>(
  (ref) =>
      (previous) => pickBackupFolder(previous: previous),
);

/// Replaces the data with a backup. Set up in main.dart, where the database is opened.
final restoreBackupProvider = Provider<Future<void> Function(BackupFile)>(
  (ref) => throw UnimplementedError('Overridden in main.dart'),
);

/// Replaces all data with a checked data file, after saving a safety copy. Returns where the
/// safety copy went. Set up in main.dart.
final replaceDataProvider = Provider<Future<String> Function(LedgerlyPreview)>(
  (ref) => throw UnimplementedError('Overridden in main.dart'),
);
