// Export all data to one .ledgerly file, for keeping a safe copy or moving to another device.
// The file is read back and checked before it is saved, and a password is optional.

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/files.dart';
import '../../app/providers.dart';
import '../../core/day.dart';
import '../../data/export/ledgerly_file.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _pictures = true;
  bool _working = false;
  String? _result;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final password = _password.text;
    if (password.isNotEmpty && password.length < 8) return showProblem(context, 'Use at least 8 characters.');
    if (password != _confirm.text) return showProblem(context, 'The two passwords are not the same.');

    setState(() {
      _working = true;
      _result = null;
    });
    try {
      final folders = ref.read(appFoldersProvider);
      final db = ref.read(databaseProvider);
      final crypto = ref.read(passwordCryptoProvider);
      final now = ref.read(clockProvider).now();
      final plain = await buildLedgerlyFile(
        db,
        images: folders.images,
        workDir: folders.work,
        appVersion: appVersion,
        now: now,
        includeAttachments: _pictures,
      );
      // Read it back before saving: the password opens it and every check passes.
      final bytes = password.isEmpty ? plain : await crypto.encrypt(plain, password);
      if (password.isNotEmpty && !listEquals(await crypto.decrypt(bytes, password), plain)) {
        throw const LedgerlyFileException(LedgerlyProblem.damaged);
      }
      final preview = await readLedgerlyFile(plain, workDir: folders.work, currentSchema: db.schemaVersion);
      preview.database.parent.deleteSync(recursive: true);

      final name = 'ledgerly-${Day.of(now).replaceAll('-', '')}.$ledgerlyExtension';
      final where = await ref.read(saveFileProvider)(name, bytes);
      if (!mounted) return;
      if (where == null) {
        setState(() => _working = false);
        return;
      }
      // Where the saved file can be read, it is compared with what was written.
      final saved = File(where);
      if (saved.existsSync() && sha256.convert(saved.readAsBytesSync()) != sha256.convert(bytes)) {
        throw const LedgerlyFileException(LedgerlyProblem.damaged);
      }
      final n = NumberFormat.decimalPattern();
      final c = preview.counts;
      setState(() {
        _working = false;
        _result =
            '${n.format(c['entries'])} entries, ${n.format(c['accounts'])} accounts, '
            '${n.format(c['budgets'])} budgets and ${n.format(c['goals'])} goals, verified. '
            '${_size(bytes)}${password.isEmpty ? '' : ', protected with a password'}. Saved as $where.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      showProblem(context, e is LedgerlyFileException ? e.message : 'The export failed: $e');
    }
  }

  static String _size(Uint8List bytes) => bytes.length >= 1024 * 1024
      ? '${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB'
      : '${(bytes.length / 1024).ceil()} KB';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Export all data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            'One .ledgerly file with all your entries, accounts, categories, repeats, budgets and goals. '
            'Keep it somewhere safe, or open it in Ledgerly on another device. It is an open format: a ZIP with an '
            'SQLite database and CSV files.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include category pictures'),
            value: _pictures,
            onChanged: _working ? null : (v) => setState(() => _pictures = v),
          ),
          const SectionHeader('Password, optional'),
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_working,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            enabled: !_working,
            decoration: const InputDecoration(labelText: 'The same password again'),
          ),
          const SizedBox(height: 8),
          LedgerCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LedgerIcon('alert', color: c.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A forgotten password cannot be recovered, and without it the file cannot be opened. '
                    'The file can also be opened with the standard age tool.',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _working ? null : _export,
            icon: const LedgerIcon('download', size: 16),
            label: Text(_working ? 'Exporting and checking' : 'Export'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            LedgerCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LedgerIcon('check', color: c.positive),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_result!, style: context.text.bodySmall)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
