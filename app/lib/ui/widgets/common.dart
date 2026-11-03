// Small building blocks shared by the screens.

import 'package:flutter/material.dart';

import '../icons/ledger_icon.dart';
import '../theme/ledgerly_colors.dart';

/// A short heading above a group, with one optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 0, 4),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.text.title)),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

/// A white card with a hairline border, holding rows without extra padding.
class LedgerCard extends StatelessWidget {
  const LedgerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    clipBehavior: Clip.antiAlias,
    child: onTap == null
        ? Padding(padding: padding, child: child)
        : InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
  );
}

/// The ledger line art with one icon rising out of it, a heading, a sentence and one action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final String icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LedgerIcon(icon, size: 24, color: c.textSecondary),
          const SizedBox(height: 2),
          LedgerIcon('ledger', size: 48, color: c.textSecondary),
          const SizedBox(height: 12),
          Text(title, style: context.text.title, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(message, style: context.text.bodySmall, textAlign: TextAlign.center),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

/// A term with its definition one tap away, such as "Net: income minus spending."
class InfoTerm extends StatelessWidget {
  const InfoTerm(this.term, {super.key, this.style});

  final String term;
  final TextStyle? style;

  static const definitions = {
    'Total balance': 'All accounts added up. A credit card owed counts as negative. Marks are converted at the fixed rate.',
    'Income': 'Income entries only. Transfers between your accounts never count.',
    'Spending':
        'Expenses minus refunds. Transfers never count, and only your own share of a shared payment does.',
    'Net': 'Income minus spending.',
    'Savings rate': 'Net divided by income: how much of what you earned you kept.',
    'Saved for goals':
        'Money you set aside for your goals. It stays in your accounts, but it is not free to spend.',
    'Free to use': 'Total balance minus what is saved for goals.',
    'Owed to me': 'The part of shared payments that others will pay back. A repayment is not income.',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: definitions[term] ?? term,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(term, style: style ?? context.text.label.copyWith(color: c.textSecondary)),
          ),
          const SizedBox(width: 4),
          LedgerIcon('info', size: 16, color: c.textTertiary, semanticLabel: 'What is $term?'),
        ],
      ),
    );
  }
}

/// A thin progress bar. The optional marker shows where it should be by today.
class LedgerBar extends StatelessWidget {
  const LedgerBar({super.key, required this.value, this.color, this.marker});

  final double value;
  final Color? color;
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, box) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(4)),
              ),
              Container(
                height: 8,
                width: box.maxWidth * value.clamp(0, 1),
                decoration: BoxDecoration(
                  color: color ?? c.positiveFill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: (box.maxWidth * marker!.clamp(0, 1)) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: c.textPrimary),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A figure with its label and a comparison underneath.
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.caption, this.onTap});

  final String label;
  final Widget value;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LedgerCard(
    padding: const EdgeInsets.all(12),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoTerm(label),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
        if (caption != null) Text(caption!, style: context.text.caption),
      ],
    ),
  );
}

/// Tiles in rows of two, or four on wide screens. Rows grow with their content, so large
/// system text never clips a figure.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width >= 720 ? 4 : 2;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (j, child) in slice.indexed) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(child: child),
              ],
              for (var k = slice.length; k < columns; k++) ...[
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final (i, r) in rows.indexed) ...[if (i > 0) const SizedBox(height: 8), r],
      ],
    );
  }
}

/// A small pill-shaped choice, such as an account or a date on the Add sheet.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    required this.onPressed,
  });

  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.surfaceTint : c.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: selected ? BorderSide(color: c.accent, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  LedgerIcon(icon!, size: 16, color: c.textSecondary),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(label, style: context.text.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a bottom sheet that scrolls and moves above the keyboard.
Future<T?> showLedgerSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: builder(context),
  ),
);

/// The usual sheet layout: a title, then content, padded and scrollable.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: context.text.title),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: context.text.bodySmall)],
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}
