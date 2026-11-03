// Titles the person typed before come back as suggestions. Choosing one brings back the
// subcategory and account it is usually saved with.

import '../core/text.dart';

/// One title as it was used: one row per title, category and account combination.
class TitleUse {
  const TitleUse({
    required this.title,
    required this.kind,
    required this.categoryId,
    required this.accountId,
    required this.count,
    required this.recentCount,
    required this.lastAmountMinor,
  });

  final String title;
  final String kind;
  final String categoryId;
  final String accountId;
  final int count;

  /// Uses in the last 90 days.
  final int recentCount;
  final int lastAmountMinor;
}

/// A remembered title with its usual category and account.
class TitleMemory {
  const TitleMemory({
    required this.title,
    required this.kind,
    required this.categoryId,
    required this.accountId,
    required this.count,
    required this.recentCount,
    required this.lastAmountMinor,
  });

  final String title;
  final String kind;
  final String categoryId;
  final String accountId;
  final int count;
  final int recentCount;
  final int lastAmountMinor;
}

/// Groups uses by title, ignoring case and diacritics, and keeps each title's most used
/// category and account. Most used lately comes first.
List<TitleMemory> rememberTitles(List<TitleUse> uses) {
  final byTitle = <String, List<TitleUse>>{};
  for (final u in uses) {
    byTitle.putIfAbsent('${u.kind}|${fold(u.title)}', () => []).add(u);
  }
  final out = byTitle.values.map((group) {
    group.sort((a, b) => b.count.compareTo(a.count));
    final best = group.first;
    return TitleMemory(
      title: best.title,
      kind: best.kind,
      categoryId: best.categoryId,
      accountId: best.accountId,
      count: group.fold(0, (s, u) => s + u.count),
      recentCount: group.fold(0, (s, u) => s + u.recentCount),
      lastAmountMinor: best.lastAmountMinor,
    );
  }).toList();
  out.sort((a, b) {
    final r = b.recentCount.compareTo(a.recentCount);
    return r != 0 ? r : b.count.compareTo(a.count);
  });
  return out;
}

/// Titles that match what is being typed. An empty query matches nothing.
List<TitleMemory> suggestTitles(List<TitleMemory> memory, String query, String kind, {int limit = 4}) {
  final q = fold(query);
  if (q.isEmpty) return const [];
  return memory
      .where((m) => m.kind == kind && fold(m.title).contains(q) && fold(m.title) != q)
      .take(limit)
      .toList();
}

/// The remembered title that is exactly what was typed, if any.
TitleMemory? exactTitle(List<TitleMemory> memory, String query, String kind) {
  final q = fold(query);
  if (q.isEmpty) return null;
  for (final m in memory) {
    if (m.kind == kind && fold(m.title) == q) return m;
  }
  return null;
}
