import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/clock.dart';
import 'package:ledgerly/data/backup/backup_service.dart';
import 'package:ledgerly/data/backup/backup_store.dart';

/// A store whose writes always fail, like a full or removed folder.
class _FailingStore implements BackupStore {
  _FailingStore(this.inner);

  final BackupStore inner;

  @override
  String get displayName => inner.displayName;
  @override
  Future<List<StoredFile>> list() => inner.list();
  @override
  Future<void> put(String name, File source) async => throw const FileSystemException('disk full');
  @override
  Future<void> remove(String name) => inner.remove(name);
  @override
  Future<File> fetch(String name, Directory temp) => inner.fetch(name, temp);
}

void main() {
  late Directory dir;
  late Directory folder;
  late FixedClock clock;
  late BackupService service;
  var written = 0;

  BackupService make(BackupStore store, {Future<void> Function(String)? write}) => BackupService(
    store: store,
    workDir: Directory('${dir.path}/work'),
    clock: clock,
    writeSnapshot:
        write ??
        (path) async {
          written += 1;
          await File(path).writeAsString('snapshot $written');
        },
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ledgerly_backup_test');
    folder = Directory('${dir.path}/backups');
    clock = FixedClock(DateTime(2026, 11, 1, 9));
    written = 0;
    service = make(LocalFolderStore(folder));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the first backup is made straight away', () async {
    expect(await service.isDue(), isTrue);
    final b = await service.runIfDue();
    expect(b, isNotNull);
    expect(await service.list(), hasLength(1));
  });

  test('a new backup only every 3 days', () async {
    await service.runIfDue();
    clock.value = clock.value.add(const Duration(days: 2, hours: 23));
    expect(await service.runIfDue(), isNull);
    clock.value = clock.value.add(const Duration(hours: 1));
    expect(await service.runIfDue(), isNotNull);
    expect(await service.list(), hasLength(2));
  });

  test('at most 3 files: the newest replaces the oldest', () async {
    final made = <String>[];
    for (var i = 0; i < 5; i++) {
      made.add((await service.backUpNow()).name);
      clock.value = clock.value.add(const Duration(days: 3));
    }
    final kept = await service.list();
    expect(kept, hasLength(3));
    expect(kept.map((b) => b.name), made.reversed.take(3));
    final newest = await service.fetch(kept.first);
    expect(newest.readAsStringSync(), 'snapshot 5');
  });

  test('a failed snapshot keeps the existing backups', () async {
    for (var i = 0; i < 3; i++) {
      await service.backUpNow();
      clock.value = clock.value.add(const Duration(days: 3));
    }
    final failing = make(
      LocalFolderStore(folder),
      write: (_) async => throw const FileSystemException('disk full'),
    );
    await expectLater(failing.backUpNow(), throwsA(isA<FileSystemException>()));
    expect(await service.list(), hasLength(3));
  });

  test('a store that cannot be written keeps the existing backups and leaves no snapshot behind', () async {
    for (var i = 0; i < 3; i++) {
      await service.backUpNow();
      clock.value = clock.value.add(const Duration(days: 3));
    }
    final failing = make(_FailingStore(LocalFolderStore(folder)));
    await expectLater(failing.backUpNow(), throwsA(isA<FileSystemException>()));
    expect(await service.list(), hasLength(3));
    expect(Directory('${dir.path}/work').listSync(), isEmpty);
  });

  test('a backup left unfinished is cleaned up and never counted', () async {
    folder.createSync(recursive: true);
    File('${folder.path}/ledgerly-backup-20261020-090000.sqlite.part').writeAsStringSync('half');
    expect(await service.list(), isEmpty);
    await service.backUpNow();
    expect(await service.list(), hasLength(1));
    expect(folder.listSync().where((f) => f.path.endsWith('.part')), isEmpty);
  });

  test('other files in the folder are left alone', () async {
    await service.backUpNow();
    File('${folder.path}/notes.txt').writeAsStringSync('mine');
    expect(await service.list(), hasLength(1));
    expect(File('${folder.path}/notes.txt').existsSync(), isTrue);
  });

  test('a safety copy sits next to the backups and is never counted or removed', () async {
    final where = await service.saveSafetyCopy('restore');
    expect(where, contains('ledgerly-before-restore-'));
    for (var i = 0; i < 4; i++) {
      await service.backUpNow();
      clock.value = clock.value.add(const Duration(days: 3));
    }
    expect(await service.list(), hasLength(3));
    expect(folder.listSync().where((f) => f.path.contains('ledgerly-before-restore-')), hasLength(1));
  });

  test('fetching copies a backup out without moving it', () async {
    final b = await service.backUpNow();
    final copy = await service.fetch(b);
    expect(copy.readAsStringSync(), 'snapshot 1');
    expect(copy.path, isNot(startsWith(folder.path)));
    expect(await service.list(), hasLength(1));
  });
}
