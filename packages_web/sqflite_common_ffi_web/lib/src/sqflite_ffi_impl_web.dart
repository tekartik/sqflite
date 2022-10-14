import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi_web/src/constant.dart';
import 'package:sqlite3/wasm.dart';

import 'import.dart';

const _dbName = 'sqflite_databases';

/// Ffi web handler for custom open/delete operation
class SqfliteFfiHandlerWeb extends SqfliteFfiHandler {
  /// Wasm url can overriden in options
  var _sqlite3WasmUrl = Uri.parse('sqlite3.wasm');

  WasmSqlite3? _sqlite3;
  IndexedDbFileSystem? _fs;

  /// Opens the database using a wasm implementation
  @override
  Future<void> handleOptionsPlatform(Map argumentMap) async {
    var sqlite3WasmUrlOverriden = argumentMap[optionsKeySqlite3WasmUrl];
    if (sqlite3WasmUrlOverriden != null) {
      _sqlite3WasmUrl =
          Uri.tryParse(sqlite3WasmUrlOverriden.toString()) ?? _sqlite3WasmUrl;
    }
  }

  /// Init file system.
  Future<IndexedDbFileSystem> initFs() async {
    _fs ??= await IndexedDbFileSystem.open(dbName: _dbName);
    return _fs!;
  }

  /// Init sqlite3 for the web
  Future<void> initSqlite3() async {
    try {
      if (_sqlite3 == null) {
        final response = await http.get(_sqlite3WasmUrl);
        final fs = await initFs();
        _sqlite3 = await WasmSqlite3.load(
            response.bodyBytes, SqliteEnvironment(fileSystem: fs));
      }
    } catch (e) {
      throw StateError(
          'Web initialization fail, make sure sqlite3.wasm is available at $_sqlite3WasmUrl');
    }
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
    final fs = await initFs();
    try {
      fs.deleteFile(path);
      await fs.flush();
    } finally {}
  }

  /// Check if database file exists
  @override
  Future<bool> handleDatabaseExistsPlatform(String path) async {
    // Ignore failure
    try {
      final fs = await initFs();
      final exists = fs.exists(path);
      return exists;
    } catch (_) {
      return false;
    }
  }

  /// Default database path.
  @override
  String getDatabasesPathPlatform() {
    return '/';
  }
}
