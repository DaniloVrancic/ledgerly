// Settings: appearance, when a month starts, and backups.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/backup_controller.dart';
import '../../app/lock_controller.dart';
import '../../app/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/repeat_schedule.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../data/export_screen.dart';
import '../data/import_screen.dart';
import '../statement_import/statement_import_screen.dart';
import 'backup_status.dart';
import 'backups_screen.dart';
import 'security_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsRepositoryProvider);
    final theme = ref.watch(themeModeSettingProvider);
    final accent = ref.watch(accentProvider);
    final monthStart = ref.watch(monthStartProvider);
    final period = ref.watch(currentPeriodProvider);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SectionHeader('Appearance'),
          LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('System')),
                    ButtonSegment(value: 'light', label: Text('Light')),
                    ButtonSegment(value: 'dark', label: Text('Dark')),
                  ],
                  selected: {theme},
                  onSelectionChanged: (s) => settings.write(SettingKeys.themeMode, s.first),
                ),
                const SizedBox(height: 16),
                Text('Accent colour', style: context.text.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in AccentChoice.values)
                      ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? a.dark : a.light,
                          radius: 8,
                        ),
                        label: Text(a.label),
                        selected: a == accent,
                        onSelected: (_) => settings.write('accent', a.name),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Used for buttons and selection. Income, spending and warnings keep their own colours.',
                  style: context.text.caption,
                ),
              ],
            ),
          ),
          const SectionHeader('Months'),
          LedgerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: monthStart,
                  decoration: const InputDecoration(labelText: 'A month starts on'),
                  items: [
                    for (var d = 1; d <= 28; d++)
                      DropdownMenuItem(
                        value: d,
                        child: Text('The ${ordinal(d)}${d == 1 ? ' (calendar months)' : ''}'),
                      ),
                  ],
                  onChanged: (d) {
                    if (d != null) settings.setMonthStartDay(d);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Set it to your payday to see each pay period as a month. Home and Insights follow it. Now: ${period.label}.',
                  style: context.text.caption,
                ),
              ],
            ),
          ),
          const SectionHeader('Security'),
          Card(
            child: ListTile(
              leading: const LedgerIcon('lock'),
              title: const Text('App lock'),
              subtitle: Text(ref.watch(lockControllerProvider).enabled ? 'On' : 'Off'),
              trailing: const LedgerIcon('chevron'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
            ),
          ),
          const SectionHeader('Your data'),
          Card(
            child: ListTile(
              leading: const LedgerIcon('shield'),
              title: const Text('Backups'),
              subtitle: const _BackupSubtitle(),
              trailing: const LedgerIcon('chevron'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupsScreen())),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const LedgerIcon('download'),
                  title: const Text('Export all data'),
                  subtitle: const Text('One .ledgerly file, with an optional password'),
                  trailing: const LedgerIcon('chevron'),
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
                ),
                ListTile(
                  leading: const LedgerIcon('inbox'),
                  title: const Text('Import a Ledgerly file'),
                  subtitle: const Text('Replaces the data on this device'),
                  trailing: const LedgerIcon('chevron'),
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const LedgerIcon('upload'),
              title: const Text('Import bank statement'),
              subtitle: const Text('Add what is missing from a CSV file'),
              trailing: const LedgerIcon('chevron'),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StatementImportScreen())),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ledgerly works fully offline. Your data stays in one database on this device, and nothing is sent anywhere.',
            style: context.text.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _BackupSubtitle extends ConsumerWidget {
  const _BackupSubtitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final latest = state.latest;
    if (state.lastError != null) return const Text('The last backup failed');
    return Text(
      latest == null
          ? 'No backup yet'
          : 'Backed up ${backupAge(latest.createdAt, DateTime.now())}. A new one every 3 days.',
    );
  }
}
