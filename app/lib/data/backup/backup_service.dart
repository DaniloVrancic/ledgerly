// Automatic backups: a new one every 3 days, at most 3 files. Once there are 3, the newest
// replaces the oldest. Each backup is a complete, consistent copy of the database.
//
// The new file is written first and the oldest one is removed only after that succeeded,
// so a failed backup never costs an existing one. Where the files live is the store's job.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/clock.dart';
import 'backup_store.dart';

class BackupFile {
  const BackupFile({required this.name, required this.createdAt, required this.sizeBytes});

  final String name;
  final DateTime createdAt;
  final int sizeBytes;
}

class BackupService {
  BackupService({
    required this.store,
    BackupStore? defaultStore,
    this.usingFallback = false,
    required this.workDir,
    required this.clock,
    required this.writeSnapshot,
    this.every = const Duration(days: 3),
    this.keep = 3,
  }) : defaultStore = defaultStore ?? store;

  /// Where backups are kept now: the default folder or one the person chose.
  BackupStore store;

  /// The app's own backup folder, used when no folder is chosen or a chosen one is out of reach.
  final BackupStore defaultStore;

  /// A folder was chosen but could not be reached, so backups go to [defaultStore].
  bool usingFallback;

  /// A private folder for the snapshot before it goes into the store.
  final Directory workDir;
  final Clock clock;

  /// Writes a consistent copy of the database to the given path, which does not exist yet.
  final Future<void> Function(String path) writeSnapshot;

  final Duration every;
  final int keep;

  static const _prefix = 'ledgerly-backup-';
  static const _extension = '.sqlite';
  static final _name = RegExp(r'^ledgerly-backup-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.sqlite$');

  /// Existing backups, newest first. Other files in the store are left alone.
  Future<List<BackupFile>> list() async {
    final out = <BackupFile>[];
    for (final f in await store.list()) {
      final created = _timeFromName(f.name);
      if (created != null) out.add(BackupFile(name: f.name, createdAt: created, sizeBytes: f.sizeBytes));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<BackupFile?> latest() async {
    final all = await list();
    return all.isEmpty ? null : all.first;
  }

  /// True when there is no backup yet or the newest is [every] old or older.
  Future<bool> isDue() async {
    final last = await latest();
    return last == null || !clock.now().isBefore(last.createdAt.add(every));
  }

  /// Makes a backup if one is due. Called when the app starts and when it comes back to the front.
  Future<BackupFile?> runIfDue() async => await isDue() ? backUpNow() : null;

  /// Makes a backup now, then removes the oldest ones beyond [keep].
  Future<BackupFile> backUpNow() async {
    workDir.createSync(recursive: true);
    final created = clock.now();
    final name = _fileName(created);
    final temp = File(p.join(workDir.path, '$name.part'));
    if (temp.existsSync()) temp.deleteSync();
    try {
      await writeSnapshot(temp.path);
      if (!temp.existsSync() || temp.lengthSync() == 0) {
        throw const FileSystemException('The backup could not be written.');
      }
      final size = temp.lengthSync();
      await store.put(name, temp);
      for (final old in (await list()).skip(keep)) {
        await store.remove(old.name);
      }
      return BackupFile(name: name, createdAt: created, sizeBytes: size);
    } finally {
      if (temp.existsSync()) temp.deleteSync();
    }
  }

  /// Copies a backup out of the store, for restoring it.
  Future<File> fetch(BackupFile backup) => store.fetch(backup.name, workDir);

  /// Saves a copy of the current data next to the backups, under a name the 3-file rule never
  /// counts or removes. Returns where it went.
  Future<String> saveSafetyCopy(String label) async {
    workDir.createSync(recursive: true);
    final name = 'ledgerly-before-$label-${clock.now().millisecondsSinceEpoch}$_extension';
    final temp = File(p.join(workDir.path, name));
    if (temp.existsSync()) temp.deleteSync();
    await writeSnapshot(temp.path);
    try {
      await store.put(name, temp);
    } finally {
      temp.deleteSync();
    }
    return '${store.displayName}${Platform.pathSeparator}$name';
  }

  static String _fileName(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$_prefix${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}$_extension';
  }

  static DateTime? _timeFromName(String name) {
    final m = _name.firstMatch(name);
    if (m == null) return null;
    final v = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    return DateTime(v[0], v[1], v[2], v[3], v[4], v[5]);
  }
}
