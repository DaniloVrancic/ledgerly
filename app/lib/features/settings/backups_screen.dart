// Backups: a new one every 3 days, the newest 3 kept. Restore replaces everything with a
// backup, after saving the current data as a safety copy.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/backup_controller.dart';
import '../../app/providers.dart';
import '../../data/backup/backup_service.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';
import 'backup_status.dart';

class BackupsScreen extends ConsumerWidget {
  const BackupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final service = ref.watch(backupServiceProvider);
    final c = context.colors;
    final now = DateTime.now();
    final latest = state.latest;
    final next = latest?.createdAt.add(service.every);
    final chosen = !identical(service.store, service.defaultStore);

    return Scaffold(
      appBar: AppBar(title: const Text('Backups')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          LedgerCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LedgerIcon(
                  state.lastError != null ? 'alert' : 'shieldCheck',
                  size: 24,
                  color: state.lastError != null ? c.negative : c.positive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.lastError != null
                            ? 'Backup failed'
                            : (latest == null
                                  ? 'No backup yet'
                                  : 'Backed up ${backupAge(latest.createdAt, now)}'),
                        style: context.text.label,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.lastError ??
                            (next == null
                                ? 'The first backup is made when you open Ledgerly.'
                                : 'The next one is made on or after ${_date(next)}, when you open Ledgerly.'),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.working ? null : () => ref.read(backupControllerProvider.notifier).backUpNow(),
            icon: const LedgerIcon('shield', size: 16),
            label: Text(state.working ? 'Backing up' : 'Back up now'),
          ),
          const SectionHeader('Kept backups'),
          Text(
            'A backup is made every ${service.every.inDays} days and the newest ${service.keep} are kept. A new one replaces the oldest.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 8),
          if (state.files.isEmpty)
            const LedgerCard(child: Text('None yet.'))
          else
            Card(
              child: Column(
                children: [
                  for (final b in state.files)
                    ListTile(
                      leading: const LedgerIcon('archive'),
                      title: Text(_dateTime(b.createdAt)),
                      subtitle: Text('${_size(b.sizeBytes)} · ${b.name}'),
                      trailing: TextButton(
                        onPressed: () => _confirmRestore(context, ref, b),
                        child: const Text('Restore'),
                      ),
                    ),
                ],
              ),
            ),
          const SectionHeader('Backup folder'),
          if (service.usingFallback)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LedgerCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LedgerIcon('alert', color: c.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ledgerly cannot reach the folder you chose, so backups go to its own folder for now. '
                        'Choose the folder again to give Ledgerly access, or choose another one.',
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(chosen ? 'A folder you chose' : 'Ledgerly\'s own folder', style: context.text.label),
                const SizedBox(height: 2),
                SelectableText(service.store.displayName, style: context.text.bodySmall),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state.working ? null : () => _chooseFolder(context, ref),
                  icon: const LedgerIcon('archive', size: 16),
                  label: Text(chosen || service.usingFallback ? 'Choose another folder' : 'Choose a folder'),
                ),
                if (chosen || service.usingFallback)
                  TextButton(
                    onPressed: state.working
                        ? null
                        : () async {
                            await ref.read(backupControllerProvider.notifier).useDefaultFolder();
                            if (context.mounted) {
                              showUndo(context, 'Backups go to Ledgerly\'s own folder again');
                            }
                          },
                    child: const Text('Use Ledgerly\'s own folder'),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Each backup is a complete SQLite file of your data. Ledgerly\'s own folder is removed with the app, and a copy kept '
                  'only on the phone does not survive losing it. A folder you choose, such as one on an SD card or one a sync app '
                  'copies to your computer, keeps them safe. Changing the folder copies the current backups there.',
                  style: context.text.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseFolder(BuildContext context, WidgetRef ref) async {
    try {
      final message = await ref.read(backupControllerProvider.notifier).chooseFolder();
      if (message != null && context.mounted) showUndo(context, message);
    } catch (e) {
      if (context.mounted) showProblem(context, e is FileSystemException ? e.message : '$e');
    }
  }

  Future<void> _confirmRestore(BuildContext context, WidgetRef ref, BackupFile b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'Everything in Ledgerly is replaced with the backup from ${_dateTime(b.createdAt)}. '
          'Your current data is saved first as a safety copy in the backup folder.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(restoreBackupProvider)(b);
    } catch (e) {
      if (context.mounted) showProblem(context, 'The backup could not be restored: $e. Nothing was changed.');
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime t) => '${t.day}.${t.month}.${t.year}';
  static String _dateTime(DateTime t) => '${_date(t)} at ${_two(t.hour)}:${_two(t.minute)}';
  static String _size(int bytes) =>
      bytes >= 1024 * 1024 ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB' : '${(bytes / 1024).ceil()} KB';
}
