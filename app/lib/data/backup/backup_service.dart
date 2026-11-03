// Automatic backups: a new one every 3 days, at most 3 files. Once there are 3, the newest
// replaces the oldest. Each backup is a complete, consistent copy of the database.
//
// The new file is written first and the oldest one is removed only after that succeeded,
// so a failed backup never costs an existing one.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/clock.dart';

class BackupFile {
  const BackupFile(this.file, this.createdAt);

  final File file;
  final DateTime createdAt;

  String get name => p.basename(file.path);
  int get sizeBytes => file.lengthSync();
}

class BackupService {
  BackupService({
    required this.folder,
    required this.clock,
    required this.writeSnapshot,
    this.every = const Duration(days: 3),
    this.keep = 3,
  });

  /// Where backups are kept.
  final Directory folder;
  final Clock clock;

  /// Writes a consistent copy of the database to the given path, which does not exist yet.
  final Future<void> Function(String path) writeSnapshot;

  final Duration every;
  final int keep;

  static const _prefix = 'ledgerly-backup-';
  static const _extension = '.sqlite';
  static final _name = RegExp(r'^ledgerly-backup-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.sqlite$');

  /// Existing backups, newest first.
  List<BackupFile> list() {
    if (!folder.existsSync()) return const [];
    final out = <BackupFile>[];
    for (final f in folder.listSync().whereType<File>()) {
      final created = _timeFromName(p.basename(f.path));
      if (created != null) out.add(BackupFile(f, created));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  BackupFile? get latest {
    final all = list();
    return all.isEmpty ? null : all.first;
  }

  /// True when there is no backup yet or the newest is [every] old or older.
  bool get isDue {
    final last = latest;
    return last == null || !clock.now().isBefore(last.createdAt.add(every));
  }

  /// Makes a backup if one is due. Called when the app starts and when it comes back to the front.
  Future<BackupFile?> runIfDue() async => isDue ? backUpNow() : null;

  /// Makes a backup now, then removes the oldest ones beyond [keep].
  Future<BackupFile> backUpNow() async {
    await folder.create(recursive: true);
    final created = clock.now();
    final target = File(p.join(folder.path, _fileName(created)));
    final temp = File('${target.path}.part');
    if (temp.existsSync()) temp.deleteSync();
    await writeSnapshot(temp.path);
    if (!temp.existsSync() || temp.lengthSync() == 0) {
      throw const FileSystemException('The backup could not be written.');
    }
    if (target.existsSync()) target.deleteSync();
    await temp.rename(target.path);
    final all = list();
    for (final old in all.skip(keep)) {
      old.file.deleteSync();
    }
    return BackupFile(target, created);
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
