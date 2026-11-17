// The frame around the main screens. On phones: a bottom bar with a raised Add button in the
// middle. On wider screens: a rail on the side. Backups run when the app opens and returns.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/add_entry/add_entry_sheet.dart';
import '../features/categories/categories_screen.dart';
import '../features/entries/entries_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/more/more_screen.dart';
import '../features/onboarding/first_account_screen.dart';
import '../features/savings/goals_screen.dart';
import '../ui/icons/ledger_icon.dart';
import '../ui/theme/ledgerly_colors.dart';
import 'backup_controller.dart';
import 'providers.dart';
import 'shell_tabs.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(backupControllerProvider.notifier).runIfDue(),
    );
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(backupControllerProvider.notifier).runIfDue());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  static const _tabs = [
    (AppTab.home, 'Home', 'home'),
    (AppTab.entries, 'Entries', 'list'),
    (AppTab.insights, 'Insights', 'chart'),
    (AppTab.more, 'More', 'menu'),
  ];

  Widget _screen(AppTab tab) => switch (tab) {
    AppTab.home => const HomeScreen(),
    AppTab.entries => const EntriesScreen(),
    AppTab.insights => const InsightsScreen(),
    AppTab.more => const MoreScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allAccountsProvider);
    if (accounts.hasValue && accounts.value!.isEmpty) return const FirstAccountScreen();

    final tab = ref.watch(selectedTabProvider);
    final c = context.colors;
    final body = IndexedStack(index: tab.index, children: [for (final t in _tabs) _screen(t.$1)]);
    void select(AppTab t) => ref.read(selectedTabProvider.notifier).show(t);

    if (MediaQuery.sizeOf(context).width >= 720) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: tab.index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => select(AppTab.values[i]),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FloatingActionButton(
                  onPressed: () => openAddEntry(context),
                  tooltip: 'Add',
                  child: const LedgerIcon('plus', size: 24),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                          icon: const LedgerIcon('target'),
                          tooltip: 'Savings',
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                          ),
                          icon: const LedgerIcon('tag'),
                          tooltip: 'Categories',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final t in _tabs)
                  NavigationRailDestination(
                    icon: LedgerIcon(t.$3, size: 24),
                    selectedIcon: LedgerIcon(t.$3, size: 24, color: c.accent),
                    label: Text(t.$2),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: c.borderSubtle),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddEntry(context),
        tooltip: 'Add',
        child: const LedgerIcon('plus', size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: c.surface1,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            for (final (i, t) in _tabs.indexed) ...[
              if (i == 2) const SizedBox(width: 72),
              Expanded(
                child: _NavItem(label: t.$2, icon: t.$3, selected: tab == t.$1, onTap: () => select(t.$1)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accent : c.textSecondary;
    // The bar has a fixed height, so its labels grow only a little with large system text.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LedgerIcon(icon, size: 24, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
