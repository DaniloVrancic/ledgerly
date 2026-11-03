import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/clock.dart';
import 'package:ledgerly/data/backup/backup_service.dart';

void main() {
  late Directory dir;
  late FixedClock clock;
  late BackupService service;
  var written = 0;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ledgerly_backup_test');
    clock = FixedClock(DateTime(2026, 11, 1, 9));
    written = 0;
    service = BackupService(
      folder: Directory('${dir.path}/backups'),
      clock: clock,
      writeSnapshot: (path) async {
        written += 1;
        await File(path).writeAsString('snapshot $written');
      },
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the first backup is made straight away', () async {
    expect(service.isDue, isTrue);
    final b = await service.runIfDue();
    expect(b, isNotNull);
    expect(service.list(), hasLength(1));
  });

  test('a new backup only every 3 days', () async {
    await service.runIfDue();
    clock.value = clock.value.add(const Duration(days: 2, hours: 23));
    expect(await service.runIfDue(), isNull);
    clock.value = clock.value.add(const Duration(hours: 1));
    expect(await service.runIfDue(), isNotNull);
    expect(service.list(), hasLength(2));
  });

  test('at most 3 files: the newest replaces the oldest', () async {
    final made = <String>[];
    for (var i = 0; i < 5; i++) {
      made.add((await service.backUpNow()).name);
      clock.value = clock.value.add(const Duration(days: 3));
    }
    final kept = service.list();
    expect(kept, hasLength(3));
    expect(kept.map((b) => b.name), made.reversed.take(3));
    expect(kept.first.file.readAsStringSync(), 'snapshot 5');
  });

  test('a failed backup keeps the existing ones', () async {
    for (var i = 0; i < 3; i++) {
      await service.backUpNow();
      clock.value = clock.value.add(const Duration(days: 3));
    }
    final failing = BackupService(folder: service.folder, clock: clock, writeSnapshot: (_) async => throw const FileSystemException('disk full'));
    await expectLater(failing.backUpNow(), throwsA(isA<FileSystemException>()));
    expect(service.list(), hasLength(3));
  });

  test('other files in the folder are left alone', () async {
    await service.backUpNow();
    File('${service.folder.path}/notes.txt').writeAsStringSync('mine');
    expect(service.list(), hasLength(1));
    expect(File('${service.folder.path}/notes.txt').existsSync(), isTrue);
  });
}
