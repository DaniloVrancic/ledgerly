// Bank statement import in three steps: choose a CSV file, check which columns hold what,
// then review what matches existing entries and pick what to add.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/files.dart';
import '../../app/providers.dart';
import '../../data/repositories/account_repository.dart';
import '../../domain/statement/cp1250.dart';
import '../../domain/statement/csv_reader.dart';
import '../../domain/statement/statement_mapping.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/undo.dart';
import 'mapping_step.dart';
import 'review_step.dart';

class StatementImportScreen extends ConsumerStatefulWidget {
  const StatementImportScreen({super.key});

  @override
  ConsumerState<StatementImportScreen> createState() => _StatementImportScreenState();
}

enum _Step { pick, map, review }

class _StatementImportScreenState extends ConsumerState<StatementImportScreen> {
  _Step _step = _Step.pick;
  String _fileName = '';
  List<List<String>> _rows = const [];
  late StatementMapping _mapping;
  String? _accountId;

  Future<void> _pick() async {
    final file = await ref.read(pickFileProvider)(['csv']);
    if (file == null || !mounted) return;
    final rows = readCsv(decodeStatement(file.bytes));
    if (rows.length < 2) {
      showProblem(context, 'That file has no rows to import.');
      return;
    }
    final accounts = ref.read(accountsProvider).value ?? const <AccountWithBalance>[];
    setState(() {
      _fileName = file.name;
      _rows = rows;
      _mapping = guessMapping(rows);
      _accountId ??= accounts.isEmpty ? null : accounts.first.id;
      _step = _Step.map;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _Step.pick => 'Import bank statement',
      _Step.map => 'Check the columns',
      _Step.review => 'Review',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: _step == _Step.pick
            ? null
            : IconButton(
                onPressed: () => setState(() => _step = _step == _Step.review ? _Step.map : _Step.pick),
                icon: Transform.flip(flipX: true, child: const LedgerIcon('chevron')),
                tooltip: 'Back',
              ),
      ),
      body: switch (_step) {
        _Step.pick => _PickStep(onPick: _pick),
        _Step.map => MappingStep(
          fileName: _fileName,
          rows: _rows,
          mapping: _mapping,
          accountId: _accountId,
          onMapping: (m) => setState(() => _mapping = m),
          onAccount: (id) => setState(() => _accountId = id),
          onNext: () => setState(() => _step = _Step.review),
        ),
        _Step.review => ReviewStep(
          rows: applyMapping(_rows, _mapping),
          accountId: _accountId!,
          onDone: () => Navigator.pop(context),
        ),
      },
    );
  }
}

class _PickStep extends StatelessWidget {
  const _PickStep({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      EmptyState(
        icon: 'upload',
        title: 'Bring in a statement',
        message: 'Export a CSV file from your bank, then choose it here. Ledgerly shows what is already recorded, what is missing and what looks like a duplicate before anything is added.',
        action: 'Choose a CSV file',
        onAction: onPick,
      ),
      Text(
        'The file is read on this device and is not kept. Nothing is added until you confirm.',
        style: context.text.caption,
        textAlign: TextAlign.center,
      ),
    ],
  );
}
