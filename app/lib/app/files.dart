// Opening files through the system's own picker. Behind providers, so the tests can stand in
// for a person choosing a file.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PickedFile = ({String name, Uint8List bytes});

/// Asks for one file with one of [extensions], such as `['csv']`. Null when cancelled.
typedef PickFile = Future<PickedFile?> Function(List<String> extensions);

final pickFileProvider = Provider<PickFile>(
  (ref) => (extensions) async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: extensions);
    if (file == null) return null;
    return (name: file.name, bytes: await file.xFile.readAsBytes());
  },
);
