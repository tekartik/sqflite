import 'dart:async';
import 'dart:typed_data';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart';
import 'package:sqlite3/wasm.dart';

import 'database_file_system_web.dart';
import 'import.dart';

/// Ffi web handler for custom open/delete operation
class SqfliteFfiHandlerWeb extends SqfliteFfiHandler
    with SqfliteFfiHandlerNonImplementedMixin {
  /// Global context
  final SqfliteFfiWebContext context;

  late final SqfliteDatabaseFileSystemFfiWeb _dbFs =
      SqfliteDatabaseFileSystemFfiWeb(initFs());
  WasmSqlite3? _sqlite3;
  VirtualFileSystem? _fs;

  /// Web handler for common sqlite3 web env
  SqfliteFfiHandlerWeb(this.context);

  /// Init file system.
  VirtualFileSystem initFs() {
    _fs ??= context.fs;
    return _fs!;
  }

  /// Init sqlite3 for the web
  Future<void> initSqlite3() async {
    _sqlite3 ??= context.wasmSqlite3;
  }

  @override
  Future<CommonDatabase> openPlatform(Map argumentsMap) async {
    await initSqlite3();
    var path = argumentsMap['path'] as String;
    var readOnly = (argumentsMap['readOnly'] as bool?) ?? false;
    var mode = readOnly ? OpenMode.readOnly : OpenMode.readWriteCreate;
    var db = _sqlite3!.open(path, mode: mode);
    return db;
  }

  /// Delete the database file.
  @override
  Future<void> deleteDatabasePlatform(String path) async {
    await _dbFs.deleteDatabase(path);
  }

  /// Check if database file exists
  @override
  Future<bool> handleDatabaseExistsPlatform(String path) async {
    return await _dbFs.databaseExists(path);
  }

  @override
  Future<Uint8List> readDatabaseBytesPlatform(String path) async {
    return await _dbFs.readDatabaseBytes(path);
  }

  @override
  Future<void> writeDatabaseBytesPlatform(String path, Uint8List bytes) async {
    return await _dbFs.writeDatabaseBytes(path, bytes);
  }

  /// Default database path.
  @override
  String getDatabasesPathPlatform() {
    return '/';
  }

  @override
  Future<void> handleOptionsPlatform(Map argumentMap) async {
    // No op
  }
}
