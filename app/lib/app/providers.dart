// How the app's parts are wired together. Screens read data from these providers and call
// the repositories to change it. The database's live queries keep every screen up to date.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../core/day.dart';
import '../core/money.dart';
import '../core/period.dart';
import '../data/backup/backup_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/entry_repository.dart';
import '../data/repositories/entry_view.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/repeat_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/budget_plan.dart';
import '../domain/insights.dart';
import '../domain/payday_forecast.dart';
import '../domain/repeat_schedule.dart';
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
final budgetRepositoryProvider = Provider(
  (ref) => BudgetRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
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
final budgetsProvider = StreamProvider((ref) => ref.watch(budgetRepositoryProvider).watchBudgets());

/// Spending in a period per category, subcategory and overall, for budgets.
final budgetSpendingProvider = StreamProvider.autoDispose.family<Map<String, int>, Period>(
  (ref, p) => ref.watch(budgetRepositoryProvider).watchSpending(p.start, p.end),
);

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

/// Spending from start to end without monthly and yearly repeats, and the first entry's day.
final everydaySpendingProvider = StreamProvider.autoDispose.family<EverydaySpending, (String, String)>(
  (ref, range) => ref.watch(entryRepositoryProvider).watchEverydaySpending(range.$1, range.$2),
);

/// Each day's figures from start to end, for the calendar.
final dayTotalsProvider = StreamProvider.autoDispose.family<Map<String, DayTotals>, (String, String)>(
  (ref, range) => ref.watch(entryRepositoryProvider).watchDayTotals(range.$1, range.$2),
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

/// A budget with how it stands in its current month or week.
typedef BudgetLine = ({Budget budget, BudgetView view});

/// The period a budget covers on [today]: the financial month, or the week.
Period budgetPeriod(Budget b, String today, int monthStart) =>
    b.every == BudgetEvery.weekly ? weekOf(today) : periodOf(today, startDay: monthStart);

/// Every budget as it stands now: all spending first, then the fullest first.
final budgetLinesProvider = Provider<List<BudgetLine>>((ref) {
  final today = ref.watch(todayProvider);
  final monthStart = ref.watch(monthStartProvider);
  final lines = <BudgetLine>[
    for (final b in ref.watch(budgetsProvider).value ?? const <Budget>[])
      (
        budget: b,
        view: () {
          final period = budgetPeriod(b, today, monthStart);
          final spent = ref.watch(budgetSpendingProvider(period)).value ?? const {};
          return viewBudget(
            limitMinor: b.limitMinor,
            spentMinor: spent[b.categoryId ?? BudgetRepository.overall] ?? 0,
            period: period,
            today: today,
          );
        }(),
      ),
  ];
  lines.sort((a, b) {
    final overall = (a.budget.categoryId == null ? 0 : 1).compareTo(b.budget.categoryId == null ? 0 : 1);
    return overall != 0 ? overall : b.view.ratio.compareTo(a.view.ratio);
  });
  return lines;
});

final dueRepeatsProvider = Provider((ref) {
  final today = ref.watch(todayProvider);
  return (ref.watch(repeatsProvider).value ?? const [])
      .where((r) => r.nextDay.compareTo(today) <= 0)
      .toList();
});

/// Home's "Lowest before payday". Null while its data is still loading.
final paydayForecastProvider = Provider.autoDispose<ForecastOutcome?>((ref) {
  final today = ref.watch(todayProvider);
  final accounts = ref.watch(accountsProvider).value;
  final repeats = ref.watch(repeatsProvider).value;
  final setAside = ref.watch(setAsideProvider).value;
  final everyday = ref
      .watch(everydaySpendingProvider((Day.add(today, -(forecastWindowDays - 1)), today)))
      .value;
  if (accounts == null || repeats == null || setAside == null || everyday == null) return null;

  // Goal money is taken from Savings accounts first, then from the rest.
  final savings = AccountKind.savings.name;
  final nonSavings = accounts.where((a) => a.account.kind != savings).fold(0, (s, a) => s + a.baseMinor);
  final spendable = min(nonSavings, ref.watch(freeToUseProvider));

  // Repeats on archived accounts are left out, as their balances are.
  final byId = {for (final a in accounts) a.id: a.account};
  return forecastToPayday(
    today: today,
    spendableMinor: spendable,
    repeats: [
      for (final r in repeats)
        if (byId[r.accountId] case final account?)
          ForecastRepeat(
            title: r.title,
            isIncome: r.kind == 'income',
            every: Every.parse(r.every),
            nextDay: r.nextDay,
            anchorDay: r.anchorDay,
            baseMinor: toBase(r.amountMinor, account.currency),
            onSavings: account.kind == savings,
          ),
    ],
    everydaySpendingMinor: everyday.spentMinor,
    firstEntryDay: everyday.firstDay,
  );
});
