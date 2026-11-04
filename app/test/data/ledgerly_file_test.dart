import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/export/ledgerly_file.dart';
import 'package:ledgerly/data/repositories/settings_repository.dart';
import 'package:sqlite3/sqlite3.dart';

import 'test_ledger.dart';

void main() {
  late TestLedger l;
  late Directory dir;
  late Directory images;
  setUp(() async {
    l = await TestLedger.create();
    dir = Directory.systemTemp.createTempSync('ledgerly_file_test');
    images = Directory('${dir.path}/category_images')..createSync();
    await l.entries.addEntry(isExpense: true, accountId: l.bank, amountMinor: 1250, categoryId: 'groceries');
    await l.entries.addEntry(isExpense: false, accountId: l.bank, amountMinor: 200000, categoryId: 'salary');
    final picture = File('${images.path}/dog.png')..writeAsBytesSync([1, 2, 3, 4]);
    await l.db.customStatement("UPDATE categories SET image_path = ? WHERE id = 'groceries'", [picture.path]);
    final settings = SettingsRepository(l.db, l.clock);
    await settings.write(SettingKeys.themeMode, 'dark');
    await settings.write(SettingKeys.backupFolder, '{"kind":"path","value":"D:/Backups","name":"D"}');
  });
  tearDown(() async {
    await l.dispose();
    dir.deleteSync(recursive: true);
  });

  Future<Uint8List> build({bool pictures = true}) => buildLedgerlyFile(
    l.db,
    images: images,
    workDir: Directory('${dir.path}/work'),
    appVersion: '1.0.0+1',
    now: DateTime(2026, 11, 4, 10),
    includeAttachments: pictures,
  );

  Future<LedgerlyPreview> read(Uint8List bytes) =>
      readLedgerlyFile(bytes, workDir: Directory('${dir.path}/in'), currentSchema: l.db.schemaVersion);

  Matcher problem(LedgerlyProblem p) =>
      throwsA(isA<LedgerlyFileException>().having((e) => e.problem, 'problem', p));

  test('a data file reads back with its counts, settings and pictures', () async {
    final bytes = await build();
    expect(isZip(bytes), isTrue);
    final preview = await read(bytes);
    expect(preview.counts['entries'], 2);
    expect(preview.counts['accounts'], greaterThanOrEqualTo(2));
    expect(preview.schemaVersion, l.db.schemaVersion);
    expect(preview.appVersion, '1.0.0+1');
    expect(preview.createdAt, DateTime(2026, 11, 4, 10));
    expect(preview.settings['theme_mode'], 'dark');
    expect(
      preview.settings.containsKey('backup_folder'),
      isFalse,
      reason: 'the backup folder belongs to the device',
    );
    expect(File('${preview.attachments.path}/dog.png').readAsBytesSync(), [1, 2, 3, 4]);

    final db = sqlite3.open(preview.database.path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    expect(
      db.select("SELECT image_path FROM categories WHERE id = 'groceries'").first.values.first,
      'attachments/dog.png',
    );
    expect(db.select("SELECT COUNT(*) FROM settings WHERE key = 'backup_folder'").first.values.first, 0);
  });

  test('pictures are put back in place before the data is used', () async {
    final preview = await read(await build());
    final target = Directory('${dir.path}/new_images')..createSync();
    relinkAttachments(preview.database, target);
    final db = sqlite3.open(preview.database.path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    final path =
        db.select("SELECT image_path FROM categories WHERE id = 'groceries'").first.values.first! as String;
    expect(path, endsWith('dog.png'));
    expect(path, startsWith(target.path));
  });

  test('without pictures, categories fall back to their icon', () async {
    final preview = await read(await build(pictures: false));
    expect(preview.attachments.listSync(), isEmpty);
    final db = sqlite3.open(preview.database.path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    expect(db.select("SELECT image_path FROM categories WHERE id = 'groceries'").first.values.first, isNull);
  });

  test('every table is also inside as readable CSV', () async {
    final archive = ZipDecoder().decodeBytes(await build());
    final entries = utf8.decode(archive.findFile('data/entries.csv')!.content);
    expect(entries.split('\r\n').first, contains('id'));
    expect(entries.split('\r\n').where((l) => l.isNotEmpty), hasLength(3));
    expect(archive.findFile('data/postings.csv'), isNotNull);
    expect(archive.findFile('data/budgets.csv'), isNotNull);
  });

  test('a changed byte inside is found, and nothing is extracted as valid', () async {
    final archive = ZipDecoder().decodeBytes(await build());
    final db = archive.findFile('data/ledgerly.sqlite')!;
    final changed = Uint8List.fromList(db.content)..[100] ^= 0xFF;
    final tampered = Archive();
    for (final f in archive.files) {
      tampered.add(
        f.name == db.name ? ArchiveFile.bytes(f.name, changed) : ArchiveFile.bytes(f.name, f.content),
      );
    }
    await expectLater(read(ZipEncoder().encodeBytes(tampered)), problem(LedgerlyProblem.damaged));
  });

  test('a file from a newer Ledgerly is refused', () async {
    final archive = ZipDecoder().decodeBytes(await build());
    final manifest =
        jsonDecode(utf8.decode(archive.findFile('manifest.json')!.content)) as Map<String, dynamic>;
    manifest['schemaVersion'] = 99;
    final newer = Archive();
    for (final f in archive.files) {
      newer.add(
        f.name == 'manifest.json'
            ? ArchiveFile.bytes(f.name, utf8.encode(jsonEncode(manifest)))
            : ArchiveFile.bytes(f.name, f.content),
      );
    }
    await expectLater(read(ZipEncoder().encodeBytes(newer)), problem(LedgerlyProblem.newerVersion));
  });

  test('other files are not Ledgerly files, and a protected one asks for its password', () async {
    await expectLater(
      read(Uint8List.fromList(utf8.encode('date,amount\n'))),
      problem(LedgerlyProblem.notLedgerly),
    );
    final otherZip = Archive()..add(ArchiveFile.string('readme.txt', 'hello'));
    await expectLater(read(ZipEncoder().encodeBytes(otherZip)), problem(LedgerlyProblem.notLedgerly));
    final protected = Uint8List.fromList(utf8.encode('age-encryption.org/v1\n-> scrypt abc 16\n'));
    await expectLater(read(protected), problem(LedgerlyProblem.needsPassword));
  });
}
