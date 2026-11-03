// Where the database and backups live on this device, and how the database is opened.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
