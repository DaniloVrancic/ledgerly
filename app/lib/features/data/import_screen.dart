// Import a .ledgerly file: it replaces all data on this device. Before anything changes the
// file is checked and previewed, the person types REPLACE, and a safety copy is saved.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/backup_controller.dart';
import '../../app/files.dart';
import '../../app/providers.dart';
import '../../data/export/age_passphrase.dart';
import '../../data/export/ledgerly_file.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  PickedFile? _file;
  LedgerlyPreview? _preview;
  String? _error;
  bool _working = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _needsPassword => _file != null && _preview == null && isEncryptedLedgerly(_file!.bytes);

  Future<void> _pick() async {
    final file = await ref.read(pickFileProvider)(const []);
    if (file == null || !mounted) return;
    setState(() {
      _file = file;
      _preview = null;
      _error = null;
      _password.clear();
      _confirm.clear();
    });
    if (!isEncryptedLedgerly(file.bytes)) await _check(file.bytes);
  }

  Future<void> _unlock() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final plain = await ref.read(passwordCryptoProvider).decrypt(_file!.bytes, _password.text);
      await _check(plain);
    } on AgeException catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = e.problem == AgeProblem.wrongPassphrase
            ? const LedgerlyFileException(LedgerlyProblem.wrongPassword).message
            : const LedgerlyFileException(LedgerlyProblem.damaged).message;
      });
    }
  }

  Future<void> _check(List<int> bytes) async {
    setState(() => _working = true);
    try {
      final preview = await readLedgerlyFile(
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        workDir: ref.read(appFoldersProvider).work,
        currentSchema: ref.read(databaseProvider).schemaVersion,
      );
      if (mounted) {
        setState(() {
          _working = false;
          _preview = preview;
        });
      }
    } on LedgerlyFileException catch (e) {
      if (mounted) {
        setState(() {
          _working = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _replace() async {
    setState(() => _working = true);
    try {
      await ref.read(replaceDataProvider)(_preview!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _working = false;
          _error = 'The data could not be replaced: $e. Your data is as it was.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final preview = _preview;
    final n = NumberFormat.decimalPattern();
    final backupFolder = ref.watch(backupServiceProvider).store.displayName;
    return Scaffold(
      appBar: AppBar(title: const Text('Import a Ledgerly file')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            'Importing replaces all data on this device with the data in the file. You see what is inside first, '
            'and nothing changes until you confirm.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _working ? null : _pick,
            icon: const LedgerIcon('upload', size: 16),
            label: Text(_file == null ? 'Choose a .ledgerly file' : 'Choose another file'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            LedgerCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LedgerIcon('alert', color: c.negative),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: context.text.bodySmall)),
                ],
              ),
            ),
          ],
          if (_needsPassword) ...[
            const SectionHeader('This file has a password'),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_working,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _working ? null : _unlock, child: const Text('Open')),
          ],
          if (preview != null) ...[
            const SectionHeader('In this file'),
            LedgerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Made ${DateFormat('d MMM y, HH:mm').format(preview.createdAt)} by Ledgerly ${preview.appVersion}',
                    style: context.text.label,
                  ),
                  const SizedBox(height: 8),
                  for (final (key, label) in const [
                    ('entries', 'Entries'),
                    ('accounts', 'Accounts'),
                    ('categories', 'Categories'),
                    ('repeats', 'Repeats'),
                    ('budgets', 'Budgets'),
                    ('goals', 'Savings goals'),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(label, style: context.text.bodySmall)),
                          Text(n.format(preview.counts[key] ?? 0), style: context.text.label),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      LedgerIcon('check', size: 16, color: c.positive),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Checked: complete and unchanged', style: context.text.caption)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Everything in Ledgerly on this device is replaced with this file. The current data is saved first as a '
              'safety copy in $backupFolder. Afterwards this device holds the data from the file, and a copy elsewhere '
              'no longer matches it.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              enabled: !_working,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Type REPLACE to confirm'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.negative, foregroundColor: c.onAccent),
              onPressed: _working || _confirm.text.trim() != 'REPLACE' ? null : _replace,
              child: const Text('Replace all data'),
            ),
          ],
        ],
      ),
    );
  }
}
