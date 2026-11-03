// What a new database starts with: the default categories and the hidden system records.
// People add, rename, archive or limit categories later in Categories.

import 'package:drift/drift.dart';

import 'app_database.dart';
import '../../domain/system_ids.dart';

typedef CategoryDefault = (String id, String name, String icon, int color);

const List<(CategoryDefault, List<(String, String, String)>)> defaultExpenseCategories = [
  (('housing', 'Housing', 'home', 1), [('rent', 'Rent', 'home'), ('repairs', 'Repairs', 'wrench'), ('furnishing', 'Furnishing', 'store')]),
  (('food', 'Food', 'basket', 2), [('groceries', 'Groceries', 'basket'), ('dining', 'Dining out', 'fork'), ('coffee', 'Coffee', 'coffee')]),
  (('transport', 'Transportation', 'bus', 3), [('fuel', 'Fuel', 'fuel'), ('transit', 'Public transport', 'bus'), ('parking', 'Parking', 'car'), ('carservice', 'Car service', 'wrench')]),
  (('shopping', 'Shopping', 'bag', 4), [('clothes', 'Clothes', 'shirt'), ('household', 'Household', 'home'), ('electronics', 'Electronics', 'phone')]),
  (('health', 'Health', 'pulse', 5), [('pharmacy', 'Pharmacy', 'pulse'), ('doctor', 'Doctor', 'heart'), ('fitness', 'Fitness', 'dumbbell')]),
  (('entertainment', 'Entertainment', 'ticket', 6), [('cinema', 'Cinema', 'ticket'), ('events', 'Events', 'music'), ('games', 'Games', 'game'), ('books', 'Books', 'book')]),
  (('bills', 'Bills', 'receipt', 7), [('electricity', 'Electricity', 'bolt'), ('utilities', 'Utilities', 'receipt'), ('internet', 'Internet', 'bolt'), ('mobile', 'Phone', 'phone')]),
  (('travel', 'Travel', 'plane', 8), [('stays', 'Stays', 'home'), ('trips', 'Trips', 'plane')]),
  (('education', 'Education', 'book', 9), [('courses', 'Courses', 'book')]),
  (('personal', 'Personal Care', 'sparkle', 10), [('haircut', 'Haircut', 'sparkle'), ('cosmetics', 'Cosmetics', 'leaf')]),
  (('gifts', 'Gifts', 'gift', 11), [('family', 'Family', 'gift'), ('friends', 'Friends', 'heart')]),
  (('subscriptions', 'Subscriptions', 'repeat', 12), [('streaming', 'Streaming', 'ticket'), ('musicapp', 'Music', 'music'), ('software', 'Software', 'laptop')]),
  (('other', 'Other', 'dots', 0), []),
];

const List<CategoryDefault> defaultIncomeCategories = [
  ('salary', 'Salary', 'briefcase', 3),
  ('freelance', 'Freelance', 'pen', 4),
  ('business', 'Business', 'store', 6),
  ('investments', 'Investments', 'trend', 5),
  ('rental', 'Rental income', 'key', 7),
  ('gifts-in', 'Gifts', 'gift', 11),
  ('other-in', 'Other', 'dots', 0),
];

Future<void> seedDefaults(AppDatabase db) async {
  final now = DateTime.now();
  var order = 0;

  CategoriesCompanion cat(String id, String name, String kind, String icon, int color, {String? parentId}) =>
      CategoriesCompanion.insert(
        id: id,
        name: name,
        kind: kind,
        icon: icon,
        colorSlot: Value(color),
        parentId: Value(parentId),
        sortOrder: Value(order++),
        createdAt: now,
        updatedAt: now,
      );

  await db.batch((b) {
    for (final (parent, subs) in defaultExpenseCategories) {
      b.insert(db.categories, cat(parent.$1, parent.$2, 'expense', parent.$3, parent.$4));
      for (final (id, name, icon) in subs) {
        b.insert(db.categories, cat(id, name, 'expense', icon, parent.$4, parentId: parent.$1));
      }
    }
    for (final c in defaultIncomeCategories) {
      b.insert(db.categories, cat(c.$1, c.$2, 'income', c.$3, c.$4));
    }
    // Counts as spending while an entry waits in Needs Review for its real category.
    b.insert(db.categories, cat(SystemIds.uncategorised, 'Needs a category', 'expense', 'flag', 0));
    // The difference found by a balance check. Never counts as income or spending.
    b.insert(db.categories, cat(SystemIds.untracked, 'Untracked', 'system', 'flag', 0));
    // Holds the part of a shared payment that someone else will pay back.
    b.insert(
      db.accounts,
      AccountsCompanion.insert(id: SystemIds.owedToMe, name: 'Owed to me', kind: 'system', currency: 'EUR', createdAt: now, updatedAt: now),
    );
  });
}
