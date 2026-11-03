// The year at a glance: twelve small months, each day shaded by how much was spent compared
// with the year's other spending days. A month's total sits under it, and tapping a month
// opens it in the month grid, where each day can be opened.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/repositories/entry_view.dart';
import '../../domain/calendar_month.dart';
import '../../ui/theme/ledgerly_colors.dart';
import 'month_calendar.dart';

class YearHeatmap extends ConsumerWidget {
  const YearHeatmap({super.key, required this.year, required this.onMonth});

  final int year;
  final ValueChanged<int> onMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final totals =
        ref.watch(dayTotalsProvider(('$year-01-01', '$year-12-31'))).value ?? const <String, DayTotals>{};
    final spends = [for (final t in totals.values) t.spentMinor];
    final columns = MediaQuery.sizeOf(context).width >= 720 ? 4 : 3;

    Widget month(int m) {
      final days = monthGrid(year, m);
      final spent = days.where((d) => Day.month(d) == m).fold(0, (s, d) => s + (totals[d]?.spentMinor ?? 0));
      return Semantics(
        button: true,
        label: '${Day.monthName(m)} $year, spent ${formatMoney(spent, 'EUR')}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onMonth(m),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Day.shortMonth(m), style: context.text.label),
                const SizedBox(height: 4),
                for (var w = 0; w < days.length; w += 7)
                  Row(
                    children: [
                      for (final d in days.sublist(w, w + 7))
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Day.month(d) != m || d.compareTo(today) > 0
                                    ? Colors.transparent
                                    : heatColor(c, heatStep(totals[d]?.spentMinor ?? 0, spends)),
                                border: d == today ? Border.all(color: c.accent, width: 1.5) : null,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(formatMoney(spent, 'EUR'), style: context.text.caption),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var row = 0; row < 12; row += columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var m = row + 1; m <= row + columns; m++)
                Expanded(child: m <= 12 ? month(m) : const SizedBox()),
            ],
          ),
      ],
    );
  }
}
