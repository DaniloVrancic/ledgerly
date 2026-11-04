// The financial calendar: a month grid where each day shows its net, a shade for how much was
// spent, and markers for income, repeats and high-spending days. Future days show planned
// repeats. A shade is always paired with the number, never colour alone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/day.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/entry_view.dart';
import '../../domain/calendar_month.dart';
import '../../domain/repeat_schedule.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/money_text.dart';
import 'day_sheet.dart';
import 'year_heatmap.dart';

/// "42", "1.2k" or "12k", with a plus or a real minus. Empty for zero.
String compactMoney(int minor) {
  if (minor == 0) return '';
  final euros = minor.abs() / 100;
  final sign = minor > 0 ? '+' : '−';
  if (euros < 1000) return '$sign${euros.round()}';
  final k = euros / 1000;
  return '$sign${k < 10 ? k.toStringAsFixed(1) : k.round().toString()}k';
}

/// What a future day holds: repeats planned for it, in EUR.
typedef PlannedDay = ({int netMinor, List<Repeat> repeats});

/// Planned repeats from the day after [today] to [end], leaving out daily ones, so every day
/// does not carry a marker.
Map<String, PlannedDay> plannedRepeats(
  List<Repeat> repeats,
  Map<String, String> currencyOf,
  String today,
  String start,
  String end,
) {
  final from = Day.add(today, 1).compareTo(start) > 0 ? Day.add(today, 1) : start;
  if (from.compareTo(end) > 0) return const {};
  final out = <String, PlannedDay>{};
  for (final r in repeats) {
    final every = Every.values.byName(r.every);
    if (every == Every.daily) continue;
    final eur = toBase(r.amountMinor, currencyOf[r.accountId] ?? 'EUR') * (r.kind == 'income' ? 1 : -1);
    for (final d in occurrences(
      nextDay: r.nextDay,
      every: every,
      anchorDay: r.anchorDay,
      start: from,
      end: end,
    )) {
      final before = out[d];
      out[d] = (netMinor: (before?.netMinor ?? 0) + eur, repeats: [...?before?.repeats, r]);
    }
  }
  return out;
}

class MonthCalendar extends ConsumerStatefulWidget {
  const MonthCalendar({super.key});

  @override
  ConsumerState<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<MonthCalendar> {
  late int _year = Day.year(ref.read(todayProvider));
  late int _month = Day.month(ref.read(todayProvider));
  bool _yearView = false;

  void _shift(int by) => setState(() {
    final m = _month - 1 + by;
    _year += (m / 12).floor();
    _month = m % 12 + 1;
  });

  Widget _header(String title, String unit, VoidCallback back, VoidCallback forward) => Row(
    children: [
      IconButton(
        onPressed: back,
        icon: Transform.flip(flipX: true, child: const LedgerIcon('chevron')),
        tooltip: 'Previous $unit',
      ),
      Expanded(
        child: Text(title, style: context.text.title, textAlign: TextAlign.center),
      ),
      IconButton(onPressed: forward, icon: const LedgerIcon('chevron'), tooltip: 'Next $unit'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final switcher = SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: false, label: Text('Month')),
        ButtonSegment(value: true, label: Text('Year')),
      ],
      selected: {_yearView},
      onSelectionChanged: (s) => setState(() => _yearView = s.first),
    );
    if (_yearView) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switcher,
          _header('$_year', 'year', () => setState(() => _year -= 1), () => setState(() => _year += 1)),
          LedgerCard(
            padding: const EdgeInsets.all(4),
            child: YearHeatmap(
              year: _year,
              onMonth: (m) => setState(() {
                _month = m;
                _yearView = false;
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text('Each square is a day. Tap a month to open its days.', style: context.text.caption),
        ],
      );
    }
    return _monthView(switcher);
  }

  Widget _monthView(Widget switcher) {
    final today = ref.watch(todayProvider);
    final grid = monthGrid(_year, _month);
    final totals = ref.watch(dayTotalsProvider((grid.first, grid.last))).value ?? const <String, DayTotals>{};
    final repeats = ref.watch(repeatsProvider).value ?? const <Repeat>[];
    final currencyOf = <String, String>{
      for (final a in ref.watch(allAccountsProvider).value ?? const <AccountWithBalance>[]) a.id: a.currency,
    };
    final planned = plannedRepeats(repeats, currencyOf, today, grid.first, grid.last);
    final due = {for (final r in ref.watch(dueRepeatsProvider)) r.nextDay};
    final inMonth = [
      for (final d in grid)
        if (Day.month(d) == _month) d,
    ];
    final spends = [for (final d in inMonth) totals[d]?.spentMinor ?? 0];
    final spent = spends.fold(0, (s, v) => s + v);
    final income = inMonth.fold(0, (s, d) => s + (totals[d]?.incomeMinor ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switcher,
        _header('${Day.monthName(_month)} $_year', 'month', () => _shift(-1), () => _shift(1)),
        TileGrid(
          children: [
            MetricTile(
              label: 'Spending',
              value: MoneyText(spent, style: context.text.amount),
            ),
            MetricTile(
              label: 'Income',
              value: MoneyText(income, style: context.text.amount),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LedgerCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  for (final w in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(w, style: context.text.caption, textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
              for (var w = 0; w < grid.length; w += 7)
                Row(
                  children: [
                    for (final d in grid.sublist(w, w + 7))
                      Expanded(
                        child: _DayCell(
                          day: d,
                          today: today,
                          outside: Day.month(d) != _month,
                          totals: totals[d],
                          planned: planned[d],
                          due: due.contains(d),
                          step: heatStep(totals[d]?.spentMinor ?? 0, spends),
                          high: isHighSpending(totals[d]?.spentMinor ?? 0, spends),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const CalendarLegend(),
      ],
    );
  }
}

/// The background for a heat step, from no shade to the strongest.
Color heatColor(LedgerlyColors c, int step) =>
    Color.lerp(c.surface1, c.negativeFill, const [0.0, 0.1, 0.2, 0.32, 0.45][step])!;

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.outside,
    required this.totals,
    required this.planned,
    required this.due,
    required this.step,
    required this.high,
  });

  final String day;
  final String today;
  final bool outside;
  final DayTotals? totals;
  final PlannedDay? planned;
  final bool due;
  final int step;
  final bool high;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final future = day.compareTo(today) > 0;
    final net = future ? planned?.netMinor ?? 0 : totals?.netMinor ?? 0;
    final marks = <(String, Color, String)>[
      if (!future && (totals?.incomeMinor ?? 0) > 0) ('up', c.positive, 'income'),
      if (totals?.hasRepeat ?? false) ('repeat', c.textSecondary, 'a paid repeat'),
      if (due) ('clock', c.warning, 'a repeat due'),
      if (future && planned != null) ('calendar', c.textTertiary, 'planned repeats'),
      if (!future && high) ('alert', c.negative, 'high spending'),
    ];
    final label = future
        ? '${Day.long(day)}${planned == null ? '' : ', planned ${formatMoney(net, 'EUR', sign: true)}'}'
        : '${Day.long(day)}: spent ${formatMoney(totals?.spentMinor ?? 0, 'EUR')}, '
              'income ${formatMoney(totals?.incomeMinor ?? 0, 'EUR')}, net ${formatMoney(net, 'EUR', sign: true)}'
              '${marks.isEmpty ? '' : ', ${marks.map((m) => m.$3).join(', ')}'}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Material(
          color: outside || future ? c.surface1 : heatColor(c, step),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: day == today ? BorderSide(color: c.accent, width: 1.5) : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showDaySheet(context, day),
            child: Opacity(
              opacity: outside ? 0.45 : 1,
              child: SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Day.dayOfMonth(day)}',
                        style: context.text.caption.copyWith(
                          color: day == today ? c.accent : c.textSecondary,
                          fontWeight: day == today ? FontWeight.w700 : null,
                        ),
                      ),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          compactMoney(net),
                          style: context.text.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: future
                                ? c.textTertiary
                                : net > 0
                                ? c.positive
                                : c.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12,
                        child: Row(
                          children: [for (final m in marks.take(3)) LedgerIcon(m.$1, size: 12, color: m.$2)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the shade and each marker mean.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget mark(String icon, Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LedgerIcon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: context.text.caption),
      ],
    );
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var s = 1; s <= 4; s++)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(color: heatColor(c, s), borderRadius: BorderRadius.circular(3)),
              ),
            const SizedBox(width: 4),
            Text('Less to more spent', style: context.text.caption),
          ],
        ),
        mark('up', c.positive, 'Income'),
        mark('repeat', c.textSecondary, 'Repeat paid'),
        mark('clock', c.warning, 'Repeat due'),
        mark('calendar', c.textTertiary, 'Planned'),
        mark('alert', c.negative, 'High spending'),
      ],
    );
  }
}
