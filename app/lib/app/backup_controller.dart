// Keeps the list of backups current and runs the automatic backup when it is due.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup/backup_service.dart';
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
  BackupState build() => BackupState(files: ref.read(backupServiceProvider).list());

  /// Called when the app starts and whenever it comes back to the front.
  Future<void> runIfDue() async {
    if (!_service.isDue || state.working) return;
    await backUpNow();
  }

  Future<void> backUpNow() async {
    state = BackupState(files: state.files, working: true);
    try {
      await _service.backUpNow();
      state = BackupState(files: _service.list());
    } catch (e) {
      state = BackupState(
        files: _service.list(),
        lastError: 'The backup could not be written: $e. Your data is safe on this device.',
      );
    }
  }
}

final backupControllerProvider = NotifierProvider<BackupController, BackupState>(BackupController.new);

/// Replaces the data with a backup. Set up in main.dart, where the database is opened.
final restoreBackupProvider = Provider<Future<void> Function(BackupFile)>(
  (ref) => throw UnimplementedError('Overridden in main.dart'),
);
