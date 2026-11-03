// More: everything that is not used every day.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/repositories/entry_repository.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../accounts/accounts_screen.dart';
import '../categories/categories_screen.dart';
import '../entries/needs_review_screen.dart';
import '../repeats/repeats_screen.dart';
import '../savings/goals_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueRepeatsProvider).length;
    final review =
        (ref.watch(entriesProvider(const EntryQuery(needsReview: true, limit: 50))).value ?? const []).length;
    final setAside = ref.watch(setAsideProvider).value ?? 0;
    final goals = (ref.watch(goalsProvider).value ?? const []).where((g) => g.isOpen).length;
    final customCount = ref.watch(categoryBookProvider).topLevel('expense').where((c) => c.isCustom).length;

    Widget item(String icon, String title, String subtitle, Widget screen) => ListTile(
      leading: LedgerIcon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const LedgerIcon('chevron'),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: Column(
              children: [
                item(
                  'target',
                  'Savings',
                  goals == 0
                      ? 'Plan for something you want'
                      : '$goals ${goals == 1 ? 'goal' : 'goals'}, ${formatMoney(setAside, 'EUR')} set aside',
                  const GoalsScreen(),
                ),
                item(
                  'repeat',
                  'Repeats',
                  due == 0 ? 'Bills and subscriptions that come back' : '$due due now',
                  const RepeatsScreen(),
                ),
                item(
                  'tag',
                  'Categories',
                  customCount == 0 ? 'Add your own categories and subcategories' : '$customCount of your own',
                  const CategoriesScreen(),
                ),
                item('wallet', 'Accounts', 'Balances and balance checks', const AccountsScreen()),
                item(
                  'flag',
                  'Needs review',
                  review == 0 ? 'All reviewed' : '$review waiting for a category',
                  const NeedsReviewScreen(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(child: item('gear', 'Settings', 'Appearance, months and backups', const SettingsScreen())),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Ledgerly works offline. Your data stays on this device.',
              style: context.text.caption,
            ),
          ),
        ],
      ),
    );
  }
}
