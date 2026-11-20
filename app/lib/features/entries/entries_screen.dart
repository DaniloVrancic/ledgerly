// All entries, grouped by day with each day's net, plus search and filters. Swipe an entry
// away to delete it, with Undo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/category_book.dart';
import '../../app/providers.dart';
import '../../core/day.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/entry_view.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/entry_tile.dart';
import '../../ui/widgets/money_text.dart';
import '../../ui/widgets/undo.dart';
import '../calendar/month_calendar.dart';
import '../categories/category_picker.dart';
import 'entry_details_screen.dart';
import 'needs_review_screen.dart';

class EntriesScreen extends ConsumerStatefulWidget {
  const EntriesScreen({super.key});

  @override
  ConsumerState<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends ConsumerState<EntriesScreen> {
  EntryQuery _query = const EntryQuery();
  bool _calendar = false;

  @override
  Widget build(BuildContext context) {
    final review =
        ref.watch(entriesProvider(const EntryQuery(needsReview: true, limit: 50))).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entries'),
        // Its own row under the title, so it fits small phones with large text.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('List')),
                    ButtonSegment(value: true, label: Text('Calendar')),
                  ],
                  selected: {_calendar},
                  onSelectionChanged: (s) => setState(() => _calendar = s.first),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _calendar
          ? ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), children: const [MonthCalendar()])
          : Column(
              children: [
                _Filters(query: _query, onChanged: (q) => setState(() => _query = q)),
                if (review.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: LedgerCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NeedsReviewScreen()),
                      ),
                      child: Row(
                        children: [
                          LedgerIcon('flag', color: context.colors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${review.length} ${review.length == 1 ? 'entry needs' : 'entries need'} a category',
                              style: context.text.label,
                            ),
                          ),
                          const LedgerIcon('chevron'),
                        ],
                      ),
                    ),
                  ),
                Expanded(child: EntryList(query: _query)),
              ],
            ),
    );
  }
}

/// Entries for one figure, such as a month's spending or a category, opened from Home or Insights.
class FilteredEntriesScreen extends StatelessWidget {
  const FilteredEntriesScreen({super.key, required this.title, required this.query});

  final String title;
  final EntryQuery query;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: EntryList(query: query),
  );
}

/// Entries grouped by day. Each day shows its net: income minus spending, transfers left out.
class EntryList extends ConsumerWidget {
  const EntryList({super.key, required this.query, this.embedded = false});

  final EntryQuery query;

  /// Inside another scrolling screen: the list grows to its full height instead of scrolling.
  final bool embedded;

  /// What an entry adds to its day. Filtered by a category, only that category's parts of a split.
  int _counted(EntryView v, CategoryBook book) {
    final category = query.categoryId;
    if (category == null) return v.countedBaseMinor;
    return v.countedBaseMinorWhere((id) => id == category || book.topOf(id) == category);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entriesProvider(query));
    final book = ref.watch(categoryBookProvider);
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <AccountWithBalance>[]) a.id: a,
    };
    final today = ref.watch(todayProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) {
          final filtered = query != const EntryQuery();
          return EmptyState(
            icon: filtered ? 'search' : 'plus',
            title: filtered ? 'No matches' : 'Nothing here yet',
            message: filtered
                ? 'Nothing matches. Try a shorter search or remove a filter.'
                : 'Entries you add will appear here, grouped by day.',
          );
        }
        final days = <String, List<EntryView>>{};
        for (final v in list) {
          days.putIfAbsent(v.day, () => []).add(v);
        }
        return ListView(
          shrinkWrap: embedded,
          physics: embedded ? const NeverScrollableScrollPhysics() : null,
          padding: embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            for (final MapEntry(key: day, value: entries) in days.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Day.label(day, today),
                        style: context.text.label.copyWith(color: context.colors.textSecondary),
                      ),
                    ),
                    MoneyText(
                      entries.fold(0, (s, v) => s + _counted(v, book)),
                      sign: true,
                      tone: MoneyTone.auto,
                      style: context.text.label,
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final v in entries)
                      Dismissible(
                        key: ValueKey(v.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: context.colors.negativeTint,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Delete', style: TextStyle(color: context.colors.negative)),
                        ),
                        onDismissed: (_) async {
                          final undo = await ref.read(entryRepositoryProvider).delete(v.id);
                          if (context.mounted) showUndo(context, '${v.displayTitle} deleted', undo: undo);
                        },
                        child: EntryTile(
                          view: v,
                          book: book,
                          accounts: accounts,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EntryDetailsScreen(entryId: v.id)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (list.length == query.limit)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Showing the latest ${query.limit}. Search or filter to find older entries.',
                  style: context.text.caption,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Search and filter chips. Filters take effect at once; there is no Apply button.
class _Filters extends ConsumerWidget {
  const _Filters({required this.query, required this.onChanged});

  final EntryQuery query;
  final ValueChanged<EntryQuery> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final book = ref.watch(categoryBookProvider);
    EntryQuery rebuild({
      EntryType? type,
      String? accountId,
      String? categoryId,
      bool clearType = false,
      bool clearAccount = false,
      bool clearCategory = false,
    }) => EntryQuery(
      search: query.search,
      type: clearType ? null : (type ?? query.type),
      accountId: clearAccount ? null : (accountId ?? query.accountId),
      categoryId: clearCategory ? null : (categoryId ?? query.categoryId),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search title, merchant or amount',
              prefixIcon: Padding(padding: EdgeInsets.all(12), child: LedgerIcon('search')),
            ),
            onChanged: (v) => onChanged(
              EntryQuery(
                search: v,
                type: query.type,
                accountId: query.accountId,
                categoryId: query.categoryId,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (type, label) in [
                  (EntryType.expense, 'Expenses'),
                  (EntryType.income, 'Income'),
                  (EntryType.transfer, 'Transfers'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(label),
                      selected: query.type == type,
                      onSelected: (on) => onChanged(on ? rebuild(type: type) : rebuild(clearType: true)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(query.categoryId == null ? 'Category' : book.nameOf(query.categoryId)),
                    selected: query.categoryId != null,
                    onSelected: (on) async {
                      if (!on) return onChanged(rebuild(clearCategory: true));
                      final id = await pickCategory(
                        context,
                        kind: query.type == EntryType.income ? 'income' : 'expense',
                      );
                      if (id != null) onChanged(rebuild(categoryId: id));
                    },
                  ),
                ),
                for (final a in accounts)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(a.name),
                      selected: query.accountId == a.id,
                      onSelected: (on) =>
                          onChanged(on ? rebuild(accountId: a.id) : rebuild(clearAccount: true)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
