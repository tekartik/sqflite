import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/database/database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/wasm.dart';

const _dbName = 'sqflite_databases';

class _PlatformHandlerWeb extends PlatformHandler {
  /// delete the db, create the folder and returnes its path
  @override
  Future<String> initDeleteDb(String dbName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);
    if (await databaseExists(path)) {
      await deleteDatabase(path);
    }
    return path;
  }

  /// Write the db file directly to the file system
  @override
  Future<void> writeFileAsBytes(String path, List<int> bytes,
      {bool flush = false}) async {
    final fs = await IndexedDbFileSystem.open(dbName: _dbName);
    if (fs.xAccess(path, 0) != 0) fs.xDelete(path, 0);

    final openResult =
        fs.xOpen(Sqlite3Filename(path), SqlFlag.SQLITE_OPEN_CREATE);
    openResult.file
      ..xWrite(Uint8List.fromList(bytes), 0)
      ..xClose();

    if (flush) await fs.flush();
  }

  /// Read a file as bytes
  @override
  Future<Uint8List> readFileAsBytes(String path) async {
    final fs = await IndexedDbFileSystem.open(dbName: _dbName);
    final openResult =
        fs.xOpen(Sqlite3Filename(path), SqlFlag.SQLITE_OPEN_CREATE);

    var target = Uint8List(openResult.file.xFileSize());
    openResult.file.xRead(target, 0);
    openResult.file.xClose();

    return target;
  }

  /// Write a file as a string
  @override
  Future<void> writeFileAsString(String path, String text,
      {bool flush = false}) async {
    var bytes = const Utf8Encoder().convert(text);
    await writeFileAsBytes(path, bytes, flush: flush);
  }

  /// Read a file as a string
  @override
  Future<String> readFileAsString(String path) async {
    var bytes = await readFileAsBytes(path);
    var text = const Utf8Decoder().convert(bytes);
    return text;
  }

  /// Check if a path exists.
  @override
  Future<bool> pathExists(String path) async {
    final fs = await IndexedDbFileSystem.open(dbName: _dbName);
    return fs.xAccess(path, 0) != 0;
  }

  /// Create a directory, on the web this is a noop since files are referred to directly by path
  @override
  Future<void> createDirectory(String path) async {}

  /// Delete a directory, on the web this is a noop since files are referred to directly by path
  @override
  Future<void> deleteDirectory(String path) async {}

  /// Check if a directory exists, all directories potentially exist on the web since files are referred to directly by path
  @override
  Future<bool> existsDirectory(String path) async {
    return true;
  }
}

/// Web platform handler.
PlatformHandler platformHandlerWeb = _PlatformHandlerWeb();
