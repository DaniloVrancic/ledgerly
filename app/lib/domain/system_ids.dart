// Fixed ids for records the app itself relies on. They are the same on every install.

abstract final class SystemIds {
  static const owedToMe = 'owed-to-me';
  static const uncategorised = 'uncategorised';
  static const untracked = 'untracked';

  static const hiddenCategories = {uncategorised, untracked};
}
