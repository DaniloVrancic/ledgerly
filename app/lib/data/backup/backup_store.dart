// Where backup files are kept. The backup rules live in BackupService; a store only lists,
// writes, removes and reads files, so a folder the person chooses can replace the default.

import 'dart:io';

import 'package:path/path.dart' as p;

/// A file in a store.
class StoredFile {
  const StoredFile({required this.name, required this.sizeBytes, required this.modified});

  final String name;
  final int sizeBytes;
  final DateTime modified;
}

abstract interface class BackupStore {
  /// Shown to the person, such as "Documents\Ledgerly\Backups" or a chosen folder's name.
  String get displayName;

  /// Every file in the store, in no particular order.
  Future<List<StoredFile>> list();

  /// Copies [source] into the store as [name], replacing a file with that name. The copy is
  /// complete or absent, never half written.
  Future<void> put(String name, File source);

  Future<void> remove(String name);

  /// Copies [name] out of the store into [temp] and returns the copy.
  Future<File> fetch(String name, Directory temp);
}

/// A folder on this device's file system.
///
/// File work is synchronous: the files are small, and it keeps the widget tests' fake clock
/// from waiting on real file time.
class LocalFolderStore implements BackupStore {
  LocalFolderStore(this.folder);

  final Directory folder;

  @override
  String get displayName => folder.path;

  @override
  Future<List<StoredFile>> list() async {
    if (!folder.existsSync()) return const [];
    return [
      for (final f in folder.listSync().whereType<File>())
        if (!f.path.endsWith('.part'))
          StoredFile(name: p.basename(f.path), sizeBytes: f.lengthSync(), modified: f.lastModifiedSync()),
    ];
  }

  @override
  Future<void> put(String name, File source) async {
    folder.createSync(recursive: true);
    _removeUnfinished();
    final target = File(p.join(folder.path, name));
    final temp = File('${target.path}.part');
    source.copySync(temp.path);
    if (target.existsSync()) target.deleteSync();
    await _moveIntoPlace(temp, target);
  }

  @override
  Future<void> remove(String name) async {
    final f = File(p.join(folder.path, name));
    if (f.existsSync()) f.deleteSync();
  }

  @override
  Future<File> fetch(String name, Directory temp) async {
    temp.createSync(recursive: true);
    return File(p.join(folder.path, name)).copySync(p.join(temp.path, name));
  }

  /// Windows can hold a new file for a moment, for example while a virus scanner reads it.
  /// The move is retried for about two seconds, then done as a copy.
  static Future<void> _moveIntoPlace(File temp, File target) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        temp.renameSync(target.path);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    temp.copySync(target.path);
    try {
      temp.deleteSync();
    } on FileSystemException {
      // Removed by the next backup.
    }
  }

  /// Removes copies left behind by a write that was interrupted.
  void _removeUnfinished() {
    for (final f in folder.listSync().whereType<File>()) {
      if (f.path.endsWith('.part')) {
        try {
          f.deleteSync();
        } on FileSystemException {
          // Still in use; try again next time.
        }
      }
    }
  }
}
