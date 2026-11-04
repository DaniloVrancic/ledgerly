// Budgets: a limit for all spending, a category or a subcategory, per month or per week.
// Each row shows what is spent of the limit, a marker for how far the period has gone, and
// a label for the warning and over-limit states, so colour is never the only signal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/category_book.dart';
import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/budget_plan.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/common.dart';
import 'budget_form.dart';
import 'budget_screen.dart';

/// "All spending", "Food" or "Food · Groceries", with "weekly" for weekly budgets.
String budgetName(Budget b, CategoryBook book) {
  final name = b.categoryId == null ? 'All spending' : book.fullName(b.categoryId);
  return b.every == BudgetEvery.weekly ? '$name, weekly' : name;
}

/// "€300.00 left", "At 85%" or "€10.00 over".
String budgetStateText(BudgetView v) => switch (v.state) {
  BudgetState.over => '${formatMoney(-v.leftMinor, 'EUR')} over',
  BudgetState.warning => 'At ${(v.ratio * 100).floor()}%',
  BudgetState.normal => '${formatMoney(v.leftMinor, 'EUR')} left',
};

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(budgetLinesProvider);
    final loaded = ref.watch(budgetsProvider).hasValue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            onPressed: () => openBudgetForm(context),
            icon: const LedgerIcon('plus'),
            tooltip: 'New budget',
          ),
        ],
      ),
      body: !loaded
          ? const SizedBox()
          : lines.isEmpty
          ? Center(
              child: EmptyState(
                icon: 'pie',
                title: 'No budgets yet',
                message: 'Set a monthly or weekly limit for all spending or one category. Ledgerly warns you at 80%.',
                action: 'New budget',
                onAction: () => openBudgetForm(context),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final line in lines)
                        BudgetRow(
                          line: line,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BudgetScreen(budgetId: line.budget.id)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Monthly budgets follow your month start. Weekly ones run Monday to Sunday. Transfers never count, and refunds lower what is spent.',
                  style: context.text.caption,
                ),
              ],
            ),
    );
  }
}

/// One budget: name, spent of limit, the bar with today's pace marker, and its state.
class BudgetRow extends ConsumerWidget {
  const BudgetRow({super.key, required this.line, this.onTap, this.showName = true});

  final BudgetLine line;
  final VoidCallback? onTap;

  /// Off where the category is already named, such as a Home category row.
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(categoryBookProvider);
    final v = line.view;
    final b = line.budget;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showName)
          Row(
            children: [
              b.categoryId == null
                  ? const SizedBox(width: 32, height: 32, child: Center(child: LedgerIcon('pie')))
                  : CategoryAvatar.of(book[b.categoryId], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(budgetName(b, book), style: context.text.label, overflow: TextOverflow.ellipsis),
              ),
              BudgetStateLabel(view: v),
            ],
          ),
        Padding(
          padding: EdgeInsets.only(left: showName ? 44 : 0, top: 6),
          child: BudgetBar(view: v),
        ),
        Padding(
          padding: EdgeInsets.only(left: showName ? 44 : 0, top: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMoney(v.spentMinor, 'EUR')} of ${formatMoney(v.limitMinor, 'EUR')}',
                  style: context.text.caption,
                ),
              ),
              if (!showName) BudgetStateLabel(view: v),
            ],
          ),
        ),
      ],
    );
    if (!showName) return body;
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 10), child: body),
    );
  }
}

/// The bar coloured by state, with a marker where spending would be at an even pace.
class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.view});

  final BudgetView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: '${(view.ratio * 100).floor()}% of the limit, ${(view.pace * 100).round()}% of the period gone',
      child: LedgerBar(
        value: view.ratio,
        marker: view.pace,
        color: switch (view.state) {
          BudgetState.over => c.negativeFill,
          BudgetState.warning => c.warningFill,
          BudgetState.normal => c.accent,
        },
      ),
    );
  }
}

/// The state in words, with an icon once it needs attention.
class BudgetStateLabel extends StatelessWidget {
  const BudgetStateLabel({super.key, required this.view});

  final BudgetView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (view.state) {
      BudgetState.over => c.negative,
      BudgetState.warning => c.warning,
      BudgetState.normal => c.textSecondary,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.state != BudgetState.normal) ...[
          LedgerIcon('alert', size: 16, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(budgetStateText(view), style: context.text.caption.copyWith(color: color)),
        ),
      ],
    );
  }
}
