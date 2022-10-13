import 'package:http/http.dart' as http;
import 'package:sqlite3/wasm.dart';

/// Default indexedDB name is /sqflite
Future<WasmSqlite3> loadSqlite({Uri? uri, String? indexedDbName}) async {
  uri ??= Uri.parse('packages/sqflite_web_exp/src/web/sqlite3.wasm');
  indexedDbName ??= 'sqflite_common_ffi_web';
  final response = await http.get(uri);
  final fs = await IndexedDbFileSystem.open(dbName: indexedDbName);
  var wasmSqlite3 = await WasmSqlite3.load(
      response.bodyBytes, SqliteEnvironment(fileSystem: fs));
  return wasmSqlite3;
}
