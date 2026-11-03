// The quiet line under Home: "Backed up 2 days ago", or what needs attention.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/backup_controller.dart';
import '../../ui/theme/ledgerly_colors.dart';
import 'backups_screen.dart';

String backupAge(DateTime when, DateTime now) {
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(when.year, when.month, when.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}

class BackupStatusLine extends ConsumerWidget {
  const BackupStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final c = context.colors;
    final latest = state.latest;
    final text = state.lastError != null
        ? 'Backup failed. Your data is safe on this device.'
        : latest == null
        ? 'No backup yet'
        : 'Backed up ${backupAge(latest.createdAt, DateTime.now())}';
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(foregroundColor: state.lastError != null ? c.negative : c.textTertiary),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupsScreen())),
        child: Text(
          text,
          style: context.text.caption.copyWith(color: state.lastError != null ? c.negative : c.textTertiary),
        ),
      ),
    );
  }
}
