import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/backup_controller.dart';
import 'package:ledgerly/app/providers.dart';
import 'package:ledgerly/core/clock.dart';
import 'package:ledgerly/data/backup/backup_service.dart';
import 'package:ledgerly/data/backup/backup_store.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/database/connection.dart';
import 'package:ledgerly/data/repositories/settings_repository.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('ledgerly_store_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a local folder store puts, lists, fetches and removes files', () async {
    final store = LocalFolderStore(Directory('${dir.path}/backups'));
    final source = File('${dir.path}/source.sqlite')..writeAsStringSync('data');
    await store.put('a.sqlite', source);
    await store.put('a.sqlite', source..writeAsStringSync('newer'));
    final list = await store.list();
    expect(list.single.name, 'a.sqlite');
    expect(list.single.sizeBytes, 5);
    final copy = await store.fetch('a.sqlite', Directory('${dir.path}/out'));
    expect(copy.readAsStringSync(), 'newer');
    await store.remove('a.sqlite');
    expect(await store.list(), isEmpty);
  });

  test('the chosen folder is saved as a setting and read back', () {
    const chosen = ChosenFolder(kind: ChosenFolder.tree, value: 'content://tree/abc', name: 'Backups');
    final back = ChosenFolder.fromJson(chosen.toJson())!;
    expect((back.kind, back.value, back.name), (chosen.kind, chosen.value, chosen.name));
    expect(ChosenFolder.fromJson(''), isNull);
    expect(ChosenFolder.fromJson('not json'), isNull);
  });

  test('without a chosen folder, backups go to the default one', () async {
    final r = await resolveBackupStore(null, Directory('${dir.path}/default'));
    expect(r.fallback, isFalse);
    expect(r.store.displayName, '${dir.path}/default');
  });

  test('a chosen folder that can be written is used', () async {
    final chosen = ChosenFolder(kind: ChosenFolder.path, value: '${dir.path}/mine', name: 'mine');
    final r = await resolveBackupStore(chosen.toJson(), Directory('${dir.path}/default'));
    expect(r.fallback, isFalse);
    expect(r.store.displayName, '${dir.path}/mine');
  });

  test('a chosen folder out of reach falls back to the default and says so', () async {
    // A file where the folder should be: nothing can be written inside it.
    File('${dir.path}/blocked').writeAsStringSync('x');
    final chosen = ChosenFolder(kind: ChosenFolder.path, value: '${dir.path}/blocked', name: 'blocked');
    final r = await resolveBackupStore(chosen.toJson(), Directory('${dir.path}/default'));
    expect(r.fallback, isTrue);
    expect(r.store.displayName, '${dir.path}/default');
  });

  test('choosing a folder copies the current backups there and remembers it', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final clock = FixedClock(DateTime(2026, 11, 1, 9));
    final defaultStore = LocalFolderStore(Directory('${dir.path}/default'));
    final service = BackupService(
      store: defaultStore,
      workDir: Directory('${dir.path}/work'),
      clock: clock,
      writeSnapshot: (path) async => File(path).writeAsStringSync('snapshot'),
    );
    await service.backUpNow();
    clock.value = clock.value.add(const Duration(days: 3));
    await service.backUpNow();

    final mine = ChosenFolder(kind: ChosenFolder.path, value: '${dir.path}/mine', name: 'My folder');
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        backupServiceProvider.overrideWithValue(service),
        pickBackupFolderProvider.overrideWithValue((_) async => mine),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final controller = container.read(backupControllerProvider.notifier);
    final message = await controller.chooseFolder();
    expect(message, 'Backups now go to My folder. 2 backups were copied there.');
    expect(service.store.displayName, '${dir.path}/mine');
    expect(await service.list(), hasLength(2));
    final saved = await SettingsRepository(db, clock).read(SettingKeys.backupFolder);
    expect(ChosenFolder.fromJson(saved)!.value, '${dir.path}/mine');

    clock.value = clock.value.add(const Duration(days: 3));
    await controller.backUpNow();
    expect(
      Directory('${dir.path}/mine').listSync(),
      hasLength(3),
      reason: 'new backups go to the chosen folder',
    );

    await controller.useDefaultFolder();
    expect(identical(service.store, defaultStore), isTrue);
    expect(await SettingsRepository(db, clock).read(SettingKeys.backupFolder), '');
  });
}
