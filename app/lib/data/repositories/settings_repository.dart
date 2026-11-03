// Preferences on this device, stored as text.

import '../database/app_database.dart';
import 'repository.dart';

abstract final class SettingKeys {
  static const monthStartDay = 'month_start_day';
  static const themeMode = 'theme_mode';
  static const lastAccountId = 'last_account_id';
  static const lastTransfer = 'last_transfer';
  static const onboarded = 'onboarded';

  /// The backup folder the person chose, as ChosenFolder JSON. Empty for the default.
  static const backupFolder = 'backup_folder';
}

class SettingsRepository extends Repository {
  SettingsRepository(super.db, super.clock);

  Stream<Map<String, String>> watchAll() =>
      db.select(db.settings).watch().map((rows) => {for (final r in rows) r.key: r.value});

  Future<String?> read(String key) async =>
      (await (db.select(db.settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> write(String key, String value) =>
      db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  /// The day a financial month starts, 1 to 28. Budgets, Home and Insights follow it.
  Future<int> monthStartDay() async => int.tryParse(await read(SettingKeys.monthStartDay) ?? '') ?? 1;

  Future<void> setMonthStartDay(int day) => write(SettingKeys.monthStartDay, '${day.clamp(1, 28)}');
}
