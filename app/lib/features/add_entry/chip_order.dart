// Which category chips the Add sheet shows for an account. The order is worked out once per
// app session and then stays put, so the same chip is always in the same place.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/category_book.dart';
import '../../app/providers.dart';

/// The categories used most on an account lately. Not auto-disposed: it stays for the session.
final chipOrderProvider = FutureProvider.family<List<String>, (String, String)>(
  (ref, key) => ref.read(entryRepositoryProvider).mostUsedCategories(key.$1, key.$2),
);

/// Up to six chips: the most used categories that the account offers, filled up with the
/// main categories. A chosen category that is not among them takes the last place.
List<String> chipsFor({
  required CategoryBook book,
  required List<String> mostUsed,
  required String kind,
  required String accountId,
  String? selected,
  int count = 6,
}) {
  bool usable(String id) {
    final c = book[id];
    return c != null && !c.archived && c.kind == kind && !book.isHidden(id) && book.appliesTo(id, accountId);
  }

  final out = <String>[];
  for (final id in mostUsed) {
    if (out.length < count && usable(id) && !out.contains(id)) out.add(id);
  }
  for (final top in book.topLevel(kind)) {
    final coveredByChild = out.any((id) => book.topOf(id) == top.id);
    if (out.length < count &&
        usable(top.id) &&
        !out.contains(top.id) &&
        !coveredByChild &&
        top.id != 'other' &&
        top.id != 'other-in') {
      out.add(top.id);
    }
  }
  if (selected != null && !out.contains(selected) && usable(selected)) {
    if (out.length >= count) out.removeLast();
    out.add(selected);
  }
  return out;
}
