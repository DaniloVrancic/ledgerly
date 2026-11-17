// A backup folder chosen with Android's folder picker. Android gives a content URI instead
// of a path, so the file work happens in MainActivity.kt, over the "ledgerly/folder" channel.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'backup_store.dart';

class AndroidFolderStore implements BackupStore {
  AndroidFolderStore({required this.uri, required this.name});

  final String uri;
  final String name;

  static const _channel = MethodChannel('ledgerly/folder');

  /// Opens the system folder picker. [previous] is released once a new folder is chosen.
  static Future<({String uri, String name})?> pick({String? previous}) async {
    final r = await _channel.invokeMapMethod<String, String>('pick', {'previous': previous});
    return r == null ? null : (uri: r['uri']!, name: r['name']!);
  }

  /// Whether Ledgerly still holds permission and the folder still exists.
  Future<bool> canAccess() async {
    try {
      return await _call<bool>('canAccess') ?? false;
    } on FileSystemException {
      return false;
    }
  }

  @override
  String get displayName => name;

  @override
  Future<List<StoredFile>> list() async {
    final List<Map<Object?, Object?>>? rows;
    try {
      rows = await _channel.invokeListMethod<Map<Object?, Object?>>('list', {'uri': uri});
    } catch (e) {
      throw _problem(e);
    }
    return [
      for (final r in rows ?? const <Map<Object?, Object?>>[])
        if (!(r['name'] as String).endsWith('.part'))
          StoredFile(
            name: r['name'] as String,
            sizeBytes: (r['size'] as num?)?.toInt() ?? 0,
            modified: DateTime.fromMillisecondsSinceEpoch((r['modified'] as num?)?.toInt() ?? 0),
          ),
    ];
  }

  @override
  Future<void> put(String name, File source) => _call<void>('put', {'name': name, 'path': source.path});

  @override
  Future<void> remove(String name) => _call<void>('remove', {'name': name});

  @override
  Future<File> fetch(String name, Directory temp) async {
    temp.createSync(recursive: true);
    final target = File(p.join(temp.path, name));
    await _call<void>('fetch', {'name': name, 'path': target.path});
    return target;
  }

  Future<T?> _call<T>(String method, [Map<String, Object?> args = const {}]) async {
    try {
      return await _channel.invokeMethod<T>(method, {'uri': uri, ...args});
    } catch (e) {
      throw _problem(e);
    }
  }

  static FileSystemException _problem(Object e) =>
      FileSystemException(e is PlatformException ? e.message ?? e.code : e.toString());
}
