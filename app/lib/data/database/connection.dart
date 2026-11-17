// Where the database and backups live on this device, and how the database is opened.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../backup/android_folder_store.dart';
import '../backup/backup_store.dart';
import 'app_database.dart';

/// The live database file, in the app's private folder.
Future<File> databaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, '$databaseFileName.sqlite'));
}

/// The backup folder. On Android it is the app's folder in shared storage
/// (Android/data/app.ledgerly.ledgerly/files/backups), which a file manager or a computer can
/// reach. Uninstalling the app removes it, so copy a backup elsewhere now and then.
/// On Windows it is Documents\Ledgerly\Backups.
Future<Directory> backupFolder() async {
  if (Platform.isAndroid) {
    final external = await getExternalStorageDirectory();
    if (external != null) return Directory(p.join(external.path, 'backups'));
  }
  final docs = await getApplicationDocumentsDirectory();
  return Directory(p.join(docs.path, 'Ledgerly', 'Backups'));
}

/// Opens the database on a background isolate, so the screens never wait on it.
AppDatabase openDatabase(File file) => AppDatabase(NativeDatabase.createInBackground(file));

/// A backup folder the person chose: an Android folder reached by its content URI, or a path.
class ChosenFolder {
  const ChosenFolder({required this.kind, required this.value, required this.name});

  static const tree = 'tree';
  static const path = 'path';

  /// [tree] or [path].
  final String kind;

  /// The tree URI or the folder path.
  final String value;
  final String name;

  String toJson() => jsonEncode({'kind': kind, 'value': value, 'name': name});

  /// Null for an empty or unreadable setting, which means the default folder.
  static ChosenFolder? fromJson(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return ChosenFolder(kind: m['kind'] as String, value: m['value'] as String, name: m['name'] as String);
    } on Object {
      return null;
    }
  }

  BackupStore get store =>
      kind == tree ? AndroidFolderStore(uri: value, name: name) : LocalFolderStore(Directory(value));
}

/// Whether backups can be written to [store] now.
Future<bool> canUse(BackupStore store) async {
  if (store is AndroidFolderStore) return store.canAccess();
  if (store is LocalFolderStore) {
    try {
      store.folder.createSync(recursive: true);
      final probe = File(p.join(store.folder.path, '.ledgerly-write-check'));
      probe.writeAsStringSync('ok');
      probe.deleteSync();
      return true;
    } on FileSystemException {
      return false;
    }
  }
  return true;
}

/// The store for the saved setting, or the default folder when nothing was chosen. When the
/// chosen folder cannot be reached, backups go to the default folder and [fallback] says so.
Future<({BackupStore store, bool fallback})> resolveBackupStore(
  String? setting,
  Directory defaultFolder,
) async {
  final chosen = ChosenFolder.fromJson(setting);
  if (chosen != null) {
    final store = chosen.store;
    if (await canUse(store)) return (store: store, fallback: false);
  }
  return (store: LocalFolderStore(defaultFolder), fallback: chosen != null);
}

/// Opens the system's folder picker: Android's document tree picker, or the folder dialog.
Future<ChosenFolder?> pickBackupFolder({ChosenFolder? previous}) async {
  if (Platform.isAndroid) {
    final picked = await AndroidFolderStore.pick(
      previous: previous?.kind == ChosenFolder.tree ? previous!.value : null,
    );
    return picked == null
        ? null
        : ChosenFolder(kind: ChosenFolder.tree, value: picked.uri, name: picked.name);
  }
  final path = await FilePicker.getDirectoryPath(dialogTitle: 'Choose a folder for Ledgerly backups');
  return path == null ? null : ChosenFolder(kind: ChosenFolder.path, value: path, name: path);
}
