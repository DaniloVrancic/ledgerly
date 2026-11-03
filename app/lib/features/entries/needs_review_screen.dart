// Entries saved with Later wait here. One tap on a category chip finishes each one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../data/repositories/entry_repository.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import '../../ui/widgets/undo.dart';
import '../add_entry/chip_order.dart';
import '../categories/category_picker.dart';
import 'entry_details_screen.dart';

class NeedsReviewScreen extends ConsumerWidget {
  const NeedsReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list =
        ref.watch(entriesProvider(const EntryQuery(needsReview: true, limit: 200))).value ?? const [];
    final book = ref.watch(categoryBookProvider);
    final accounts = {for (final a in ref.watch(allAccountsProvider).value ?? const []) a.id: a.name};
    final today = ref.watch(todayProvider);
    final c = context.colors;

    Future<void> finish(String entryId, String categoryId) async {
      final undo = await ref.read(entryRepositoryProvider).changeCategory(entryId, categoryId);
      if (context.mounted) showUndo(context, 'Moved to ${book.nameOf(categoryId)}', undo: undo);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Needs review')),
      body: list.isEmpty
          ? const EmptyState(
              icon: 'check',
              title: 'All reviewed',
              message: 'Every entry has a category. Entries saved with Later will wait here.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final v in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LedgerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EntryDetailsScreen(entryId: v.id)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v.displayTitle, style: context.text.subtitle),
                                      Text(
                                        '${Day.label(v.day, today)} · ${accounts[v.accountId] ?? ''}',
                                        style: context.text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                MoneyText(v.amountMinor, currency: v.currency, tone: MoneyTone.negative),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Consumer(
                            builder: (context, ref, _) {
                              final order =
                                  ref.watch(chipOrderProvider((v.accountId, 'expense'))).value ??
                                  const <String>[];
                              final ids = chipsFor(
                                book: book,
                                mostUsed: order,
                                kind: 'expense',
                                accountId: v.accountId,
                                count: 4,
                              );
                              return Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final id in ids)
                                    ActionChip(
                                      avatar: LedgerIcon(
                                        book[id]?.icon ?? 'dots',
                                        size: 16,
                                        color: c.category(book[id]?.colorSlot ?? 0),
                                      ),
                                      label: Text(book.nameOf(id)),
                                      onPressed: () => finish(v.id, id),
                                    ),
                                  ActionChip(
                                    avatar: const LedgerIcon('search', size: 16),
                                    label: const Text('All'),
                                    onPressed: () async {
                                      final id = await pickCategory(
                                        context,
                                        kind: 'expense',
                                        accountId: v.accountId,
                                      );
                                      if (id != null) finish(v.id, id);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
