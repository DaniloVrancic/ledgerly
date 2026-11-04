// Files leaving and entering the app: the system's own pickers, the app's folders, and the
// password work for data files. Behind providers, so the tests can stand in for a person
// choosing a file and run the slow password work quickly.

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/export/age_passphrase.dart';

/// Written into data files. Keep it in step with `version` in pubspec.yaml.
const appVersion = '1.0.0+1';

typedef PickedFile = ({String name, Uint8List bytes});

/// Asks for one file with one of [extensions], such as `['csv']`, or any file when empty.
/// Null when cancelled.
typedef PickFile = Future<PickedFile?> Function(List<String> extensions);

final pickFileProvider = Provider<PickFile>(
  (ref) => (extensions) async {
    final file = await FilePicker.pickFile(
      type: extensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: extensions.isEmpty ? null : extensions,
    );
    if (file == null) return null;
    return (name: file.name, bytes: await file.xFile.readAsBytes());
  },
);

/// Saves [bytes] where the person chooses, through the system's save dialog. Returns where
/// it went, or null when cancelled.
typedef SaveFile = Future<String?> Function(String fileName, Uint8List bytes);

final saveFileProvider = Provider<SaveFile>(
  (ref) => (fileName, bytes) async {
    final uri = await FilePicker.saveFile(fileName: fileName, bytes: bytes);
    if (uri == null) return null;
    return uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
  },
);

/// The app's own folders: category pictures, and a private place for work files.
typedef AppFolders = ({Directory images, Directory work});

final appFoldersProvider = Provider<AppFolders>((ref) => throw UnimplementedError('Overridden in main.dart'));

/// Password protection for data files. On a background isolate, as scrypt takes a moment.
typedef PasswordCrypto = ({
  Future<Uint8List> Function(Uint8List plain, String password) encrypt,
  Future<Uint8List> Function(Uint8List sealed, String password) decrypt,
});

final passwordCryptoProvider = Provider<PasswordCrypto>(
  (ref) => (encrypt: ageEncryptInBackground, decrypt: ageDecryptInBackground),
);
