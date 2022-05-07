import 'package:http/http.dart' as http;

import 'package:sqlite3/wasm.dart';

const _dbName = 'sqflite_databases';

/// Opens the database using a wasm implementation
Future<CommonDatabase> handleOpenPlatform(Map argumentsMap) async {
  var path = argumentsMap['path'] as String;
  var readOnly = (argumentsMap['readOnly'] as bool?) ?? false;
  final response = await http.get(Uri.parse('sqlite3.wasm'));
  final fs = await IndexedDbFileSystem.open(dbName: _dbName);
  var sqlite = await WasmSqlite3.load(
      response.bodyBytes, SqliteEnvironment(fileSystem: fs));
  var mode = readOnly ? OpenMode.readOnly : OpenMode.readWriteCreate;
  var db = sqlite.open(path, mode: mode);
  return db;
}

/// Delete the database file.
Future<void> deleteDatabasePlatform(String path) async {
  final fs = await IndexedDbFileSystem.open(dbName: _dbName);
  try {
    fs.deleteFile(path);
    await fs.flush();
  } finally {
    await fs.close();
  }
}

/// Check if database file exists
Future<bool> handleDatabaseExistsPlatform(String path) async {
  // Ignore failure
  try {
    final fs = await IndexedDbFileSystem.open(dbName: _dbName);
    final exists = fs.exists(path);
    await fs.close();
    return exists;
  } catch (_) {
    return false;
  }
}

/// Default database path.
String getDatabasesPathPlatform() {
  return '/';
}