// How the app's parts are wired together. Screens read data from these providers and call
// the repositories to change it. The database's live queries keep every screen up to date.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../core/period.dart';
import '../data/backup/backup_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/entry_repository.dart';
import '../data/repositories/entry_view.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/repeat_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/insights.dart';
import '../domain/title_memory.dart';
import '../ui/theme/ledgerly_colors.dart';
import 'category_book.dart';

// ---- Set up in main.dart ----

final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Overridden in main.dart'));
final backupServiceProvider = Provider<BackupService>(
  (ref) => throw UnimplementedError('Overridden in main.dart'),
);
final clockProvider = Provider<Clock>((ref) => SystemClock());

// ---- Repositories ----

final accountRepositoryProvider = Provider(
  (ref) => AccountRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);
final categoryRepositoryProvider = Provider(
  (ref) => CategoryRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);
final entryRepositoryProvider = Provider(
  (ref) => EntryRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);
final repeatRepositoryProvider = Provider(
  (ref) => RepeatRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(entryRepositoryProvider),
  ),
);
final goalRepositoryProvider = Provider(
  (ref) => GoalRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);
final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

// ---- Live data ----

final accountsProvider = StreamProvider((ref) => ref.watch(accountRepositoryProvider).watchAccounts());
final allAccountsProvider = StreamProvider(
  (ref) => ref.watch(accountRepositoryProvider).watchAccounts(includeArchived: true),
);
final owedToMeProvider = StreamProvider((ref) => ref.watch(accountRepositoryProvider).watchOwedToMe());

final _categoriesProvider = StreamProvider((ref) => ref.watch(categoryRepositoryProvider).watchAll());
final _categoryLimitsProvider = StreamProvider(
  (ref) => ref.watch(categoryRepositoryProvider).watchAccountLimits(),
);
final categoryBookProvider = Provider<CategoryBook>((ref) {
  final all = ref.watch(_categoriesProvider).value;
  final limits = ref.watch(_categoryLimitsProvider).value;
  if (all == null) return CategoryBook.empty;
  return CategoryBook(all, limits ?? const {});
});

final repeatsProvider = StreamProvider((ref) => ref.watch(repeatRepositoryProvider).watchAll());
final goalsProvider = StreamProvider((ref) => ref.watch(goalRepositoryProvider).watchGoals());
final setAsideProvider = StreamProvider((ref) => ref.watch(goalRepositoryProvider).watchSetAside());
final titleMemoryProvider = StreamProvider<List<TitleMemory>>(
  (ref) => ref.watch(entryRepositoryProvider).watchTitleMemory(),
);
final settingsProvider = StreamProvider((ref) => ref.watch(settingsRepositoryProvider).watchAll());

final entriesProvider = StreamProvider.autoDispose.family<List<EntryView>, EntryQuery>(
  (ref, q) => ref.watch(entryRepositoryProvider).watchEntries(q),
);
final entryProvider = StreamProvider.autoDispose.family<EntryView?, String>(
  (ref, id) => ref.watch(entryRepositoryProvider).watchOne(id),
);
final totalsProvider = StreamProvider.autoDispose.family<PeriodTotals, Period>(
  (ref, p) => ref.watch(entryRepositoryProvider).watchTotals(p.start, p.end),
);
final subcategoryTotalsProvider = StreamProvider.autoDispose.family<List<CategoryAmount>, (String, Period)>(
  (ref, arg) => ref.watch(entryRepositoryProvider).watchSubcategoryTotals(arg.$1, arg.$2.start, arg.$2.end),
);

// ---- Derived ----

final todayProvider = Provider<String>((ref) => ref.watch(clockProvider).today());

final monthStartProvider = Provider<int>(
  (ref) => int.tryParse(ref.watch(settingsProvider).value?[SettingKeys.monthStartDay] ?? '') ?? 1,
);

final currentPeriodProvider = Provider<Period>(
  (ref) => periodOf(ref.watch(todayProvider), startDay: ref.watch(monthStartProvider)),
);

/// Total balance in EUR: every account, a credit card owed counted as negative.
final totalBalanceProvider = Provider<int>(
  (ref) => (ref.watch(accountsProvider).value ?? const []).fold(0, (s, a) => s + a.baseMinor),
);

/// Total balance minus what is set aside for savings goals.
final freeToUseProvider = Provider<int>(
  (ref) => ref.watch(totalBalanceProvider) - (ref.watch(setAsideProvider).value ?? 0),
);

final themeModeSettingProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider).value?[SettingKeys.themeMode] ?? 'system',
);
final accentProvider = Provider<AccentChoice>((ref) {
  final name = ref.watch(settingsProvider).value?['accent'];
  return AccentChoice.values.where((a) => a.name == name).firstOrNull ?? AccentChoice.forest;
});

final dueRepeatsProvider = Provider((ref) {
  final today = ref.watch(todayProvider);
  return (ref.watch(repeatsProvider).value ?? const [])
      .where((r) => r.nextDay.compareTo(today) <= 0)
      .toList();
});
