// The .ledgerly data file: one open file for keeping a safe copy or moving to another device.
//
// It is a ZIP holding:
//   manifest.json          format and schema version, app version, date, counts, SHA-256 of every file
//   data/ledgerly.sqlite   a consistent snapshot of the database (VACUUM INTO)
//   data/<table>.csv       the same data in readable form
//   attachments/           pictures used as category icons
//   settings.json          this device's preferences
//
// Reading one never touches the live data. It is checked file by file and opened read-only
// first; only a file that passes every check can replace anything.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../database/app_database.dart';
import 'csv_tables.dart';

const ledgerlyFormat = 1;
const ledgerlyExtension = 'ledgerly';

/// Where a category picture is pointed to inside a data file, until import puts it back.
const _attachmentPrefix = 'attachments/';

/// Settings that belong to this device only and never travel in a data file.
const _deviceOnlySettings = {'backup_folder'};

/// The tables that are counted, so a reader can see what is inside before importing.
const _counted = ['entries', 'accounts', 'categories', 'repeats', 'goals', 'budgets'];

enum LedgerlyProblem {
  /// Not a Ledgerly file at all.
  notLedgerly,

  /// A Ledgerly file that is incomplete or changed since it was written.
  damaged,

  /// Written by a newer version of Ledgerly than this one.
  newerVersion,

  /// Protected with a password; it must be opened with one first.
  needsPassword,

  /// The password does not open it.
  wrongPassword,
}

class LedgerlyFileException implements Exception {
  const LedgerlyFileException(this.problem);

  final LedgerlyProblem problem;

  /// A plain message that also says nothing was changed.
  String get message => switch (problem) {
    LedgerlyProblem.notLedgerly => 'This is not a Ledgerly data file. Nothing was changed.',
    LedgerlyProblem.damaged => 'This file is damaged or incomplete. Nothing was changed.',
    LedgerlyProblem.newerVersion =>
      'This file comes from a newer version of Ledgerly. Update Ledgerly first. Nothing was changed.',
    LedgerlyProblem.needsPassword => 'This file is protected with a password.',
    LedgerlyProblem.wrongPassword => 'That password does not open this file. Nothing was changed.',
  };

  @override
  String toString() => message;
}

/// What a data file holds, after it passed every check. Nothing has been replaced yet.
class LedgerlyPreview {
  const LedgerlyPreview({
    required this.createdAt,
    required this.appVersion,
    required this.schemaVersion,
    required this.counts,
    required this.database,
    required this.attachments,
    required this.settings,
  });

  final DateTime createdAt;
  final String appVersion;
  final int schemaVersion;

  /// Entries, accounts, categories, repeats, goals and budgets.
  final Map<String, int> counts;

  /// The extracted database, already pointing its pictures at "attachments/".
  final File database;

  /// The extracted pictures.
  final Directory attachments;
  final Map<String, String> settings;
}

/// Builds a data file from the live database. [images] is the folder of category pictures.
Future<Uint8List> buildLedgerlyFile(
  AppDatabase db, {
  required Directory images,
  required Directory workDir,
  required String appVersion,
  required DateTime now,
  bool includeAttachments = true,
}) async {
  workDir.createSync(recursive: true);
  final snapshot = File(p.join(workDir.path, 'export-${now.millisecondsSinceEpoch}.sqlite'));
  if (snapshot.existsSync()) snapshot.deleteSync();
  await db.snapshotTo(snapshot.path);
  try {
    final files = <String, List<int>>{};
    final copy = sqlite3.open(snapshot.path);
    final Map<String, int> counts;
    final Map<String, String> settings;
    final int schema;
    try {
      // Pictures travel by name and are put back in place on import.
      final pictures = copy.select('SELECT DISTINCT image_path FROM categories WHERE image_path IS NOT NULL');
      for (final row in pictures) {
        final path = row.values.first! as String;
        final file = File(path);
        final keep = includeAttachments && file.existsSync();
        if (keep) files['$_attachmentPrefix${p.basename(path)}'] = file.readAsBytesSync();
        copy.execute('UPDATE categories SET image_path = ? WHERE image_path = ?', [
          keep ? '$_attachmentPrefix${p.basename(path)}' : null,
          path,
        ]);
      }
      for (final name in _deviceOnlySettings) {
        copy.execute('DELETE FROM settings WHERE key = ?', [name]);
      }
      counts = _counts(copy);
      settings = {
        for (final r in copy.select('SELECT key, value FROM settings'))
          r['key'] as String: r['value'] as String,
      };
      schema = copy.select('PRAGMA user_version').first.values.first! as int;
      for (final MapEntry(:key, :value) in tableCsvs(copy).entries) {
        files['data/$key'] = utf8.encode(value);
      }
    } finally {
      copy.close();
    }
    files['data/ledgerly.sqlite'] = snapshot.readAsBytesSync();
    files['settings.json'] = utf8.encode(const JsonEncoder.withIndent('  ').convert(settings));
    final manifest = {
      'format': ledgerlyFormat,
      'app': 'Ledgerly',
      'appVersion': appVersion,
      'schemaVersion': schema,
      'createdAt': now.toUtc().toIso8601String(),
      'counts': counts,
      'sha256': {for (final MapEntry(:key, :value) in files.entries) key: sha256.convert(value).toString()},
    };
    final archive = Archive()
      ..add(
        ArchiveFile.bytes('manifest.json', utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest))),
      );
    for (final MapEntry(:key, :value) in files.entries) {
      archive.add(ArchiveFile.bytes(key, value));
    }
    return ZipEncoder().encodeBytes(archive);
  } finally {
    if (snapshot.existsSync()) snapshot.deleteSync();
  }
}

/// Checks a data file and extracts it into [workDir], without touching the live data.
/// [currentSchema] is this app's database version; a newer file is refused.
Future<LedgerlyPreview> readLedgerlyFile(
  Uint8List bytes, {
  required Directory workDir,
  required int currentSchema,
}) async {
  if (isEncryptedLedgerly(bytes)) throw const LedgerlyFileException(LedgerlyProblem.needsPassword);
  if (!isZip(bytes)) throw const LedgerlyFileException(LedgerlyProblem.notLedgerly);

  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes, verify: true);
  } on Object {
    throw const LedgerlyFileException(LedgerlyProblem.damaged);
  }
  final manifestFile = archive.findFile('manifest.json');
  if (manifestFile == null) throw const LedgerlyFileException(LedgerlyProblem.notLedgerly);

  final Map<String, dynamic> manifest;
  try {
    manifest = jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
  } on Object {
    throw const LedgerlyFileException(LedgerlyProblem.damaged);
  }
  if (manifest['app'] != 'Ledgerly') throw const LedgerlyFileException(LedgerlyProblem.notLedgerly);
  final format = manifest['format'];
  final schema = manifest['schemaVersion'];
  if (format is! int || schema is! int) throw const LedgerlyFileException(LedgerlyProblem.damaged);
  if (format > ledgerlyFormat || schema > currentSchema) {
    throw const LedgerlyFileException(LedgerlyProblem.newerVersion);
  }

  final hashes = (manifest['sha256'] as Map?)?.cast<String, String>() ?? const {};
  if (!hashes.containsKey('data/ledgerly.sqlite')) throw const LedgerlyFileException(LedgerlyProblem.damaged);
  final out = Directory(p.join(workDir.path, 'import-${DateTime.now().microsecondsSinceEpoch}'))
    ..createSync(recursive: true);
  final attachments = Directory(p.join(out.path, 'attachments'))..createSync();
  for (final MapEntry(key: name, value: hash) in hashes.entries) {
    final f = archive.findFile(name);
    if (f == null || sha256.convert(f.content).toString() != hash) {
      throw const LedgerlyFileException(LedgerlyProblem.damaged);
    }
    if (name.startsWith(_attachmentPrefix)) {
      // Only a plain file name, never a path that could climb out of the folder.
      final base = p.basename(name);
      if (base != name.substring(_attachmentPrefix.length)) {
        throw const LedgerlyFileException(LedgerlyProblem.damaged);
      }
      File(p.join(attachments.path, base)).writeAsBytesSync(f.content);
    }
  }

  final database = File(p.join(out.path, 'ledgerly.sqlite'))
    ..writeAsBytesSync(archive.findFile('data/ledgerly.sqlite')!.content);
  final Map<String, int> counts;
  try {
    final db = sqlite3.open(database.path, mode: OpenMode.readOnly);
    try {
      final ok = db.select('PRAGMA integrity_check').first.values.first;
      final version = db.select('PRAGMA user_version').first.values.first;
      if (ok != 'ok' || version != schema) throw const LedgerlyFileException(LedgerlyProblem.damaged);
      counts = _counts(db);
    } finally {
      db.close();
    }
  } on LedgerlyFileException {
    rethrow;
  } on Object {
    throw const LedgerlyFileException(LedgerlyProblem.damaged);
  }
  final listed = (manifest['counts'] as Map?)?.cast<String, int>() ?? const {};
  for (final t in _counted) {
    if (listed[t] != counts[t]) throw const LedgerlyFileException(LedgerlyProblem.damaged);
  }

  Map<String, String> settings = const {};
  final settingsFile = archive.findFile('settings.json');
  if (settingsFile != null) {
    try {
      settings = (jsonDecode(utf8.decode(settingsFile.content)) as Map).cast<String, String>();
    } on Object {
      throw const LedgerlyFileException(LedgerlyProblem.damaged);
    }
  }

  return LedgerlyPreview(
    createdAt: DateTime.tryParse(manifest['createdAt'] as String? ?? '')?.toLocal() ?? DateTime(1970),
    appVersion: manifest['appVersion'] as String? ?? '',
    schemaVersion: schema,
    counts: counts,
    database: database,
    attachments: attachments,
    settings: settings,
  );
}

/// Points the extracted database's pictures at [images], where the pictures were copied.
/// Done just before the database replaces the live one.
void relinkAttachments(File database, Directory images) {
  final db = sqlite3.open(database.path);
  try {
    final prefix = images.path.endsWith(Platform.pathSeparator)
        ? images.path
        : '${images.path}${Platform.pathSeparator}';
    db.execute('UPDATE categories SET image_path = ? || substr(image_path, ?) WHERE image_path LIKE ?', [
      prefix,
      _attachmentPrefix.length + 1,
      '$_attachmentPrefix%',
    ]);
  } finally {
    db.close();
  }
}

bool isZip(List<int> bytes) =>
    bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;

/// A data file protected with a password starts with the age format's header line.
bool isEncryptedLedgerly(List<int> bytes) {
  const magic = 'age-encryption.org/v1\n';
  if (bytes.length < magic.length) return false;
  for (var i = 0; i < magic.length; i++) {
    if (bytes[i] != magic.codeUnitAt(i)) return false;
  }
  return true;
}

Map<String, int> _counts(Database db) => {
  for (final t in _counted)
    t: db.select('SELECT COUNT(*) FROM "$t" WHERE deleted_at IS NULL').first.values.first! as int,
};
