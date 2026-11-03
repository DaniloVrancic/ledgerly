// An entry with its postings, and the figures the screens show for it.

import '../../domain/system_ids.dart';
import '../database/app_database.dart';

enum EntryType { expense, income, transfer, refund, adjustment }

class EntryView {
  EntryView(this.entry, List<Posting> postings) : postings = List.unmodifiable(postings);

  final Entry entry;
  final List<Posting> postings;

  String get id => entry.id;
  String get day => entry.day;
  EntryType get type => EntryType.values.byName(entry.type);
  bool get needsReview => entry.needsReview;

  /// Postings on the person's own accounts, leaving out "Owed to me".
  Iterable<Posting> get _own => postings.where((p) => p.accountId != SystemIds.owedToMe);

  Posting get _first => _own.isEmpty ? postings.first : _own.first;

  /// The account the money left or arrived in. For a transfer, the account it left.
  String get accountId => type == EntryType.transfer ? _own.firstWhere((p) => p.amountMinor < 0, orElse: () => _first).accountId : _first.accountId;

  /// The account a transfer arrived in.
  String? get toAccountId => type == EntryType.transfer ? _own.firstWhere((p) => p.amountMinor > 0, orElse: () => _first).accountId : null;

  String get currency => _own.firstWhere((p) => p.accountId == accountId, orElse: () => _first).currency;

  /// The category, or the first one for an entry with more than one.
  String? get categoryId => postings.where((p) => p.categoryId != null).map((p) => p.categoryId).firstOrNull;

  /// The amount on the account, signed: an expense is negative, income positive.
  /// A transfer shows what left the first account, as a positive number.
  int get amountMinor {
    if (type == EntryType.transfer) return -_own.where((p) => p.accountId == accountId).fold(0, (s, p) => s + p.amountMinor);
    return _own.where((p) => p.accountId == accountId).fold(0, (s, p) => s + p.amountMinor);
  }

  /// What counts toward income (positive) or spending (negative), in EUR.
  /// Transfers and balance checks count zero.
  int get countedBaseMinor {
    if (type == EntryType.transfer || type == EntryType.adjustment) return 0;
    return postings.where((p) => p.categoryId != null).fold(0, (s, p) => s + p.baseMinor);
  }

  /// The person's own part of a shared expense, when someone else owes the rest.
  int? get shareMinor {
    final owed = postings.where((p) => p.accountId == SystemIds.owedToMe).fold(0, (s, p) => s + p.amountMinor);
    if (owed <= 0) return null;
    return -postings.where((p) => p.categoryId != null).fold(0, (s, p) => s + p.amountMinor);
  }

  /// Only simple entries with one posting can change amount or account in place.
  bool get isSimple => postings.length == 1;

  /// The title, or the merchant when there is no title.
  String get displayTitle => entry.title ?? entry.merchant ?? 'No title';
}
