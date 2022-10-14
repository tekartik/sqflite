import 'package:http/http.dart' as http;
import 'package:service_worker/window.dart' as sw;
import 'package:sqlite3/wasm.dart';

import 'load_sqlite.dart';

/// Load base file system
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3FileSystem(
    SqfliteFfiWebOptions options) async {
  // devPrint('options');
  var indexedDbName = options.indexedDbName ?? 'sqflite_databases';
  final fs = await IndexedDbFileSystem.open(dbName: indexedDbName);
  return _SqfliteFfiWebContext(options: options, fs: fs);
}

/// Default indexedDB name is /sqflite
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3Wasm(
    SqfliteFfiWebOptions options,
    {SqfliteFfiWebContext? context}) async {
  context ??= await sqfliteFfiWebLoadSqlite3FileSystem(options);
  var uri = options.sqlite3WasmUri ??
      Uri.parse('packages/sqflite_common_ffi_web/src/web/sqlite3.wasm');
  final response = await http.get(uri);
  var webContext = (context as _SqfliteFfiWebContext);
  final fs = webContext.fs;
  var wasmSqlite3 = await WasmSqlite3.load(
      response.bodyBytes, SqliteEnvironment(fileSystem: fs));
  return _SqfliteFfiWebContext(
      options: options, fs: fs, wasmSqlite3: wasmSqlite3);
}

/// Start web worker (from client)
Future<SqfliteFfiWebContext> sqfliteFfiWebStartWebWorker(
    SqfliteFfiWebOptions options) async {
  var registered = sw.register(options.serviceWorkerUri.toString());

  Future<sw.ServiceWorker> registerAndReady() async {
    await registered;
    var registration = await sw.ready;
    var serviceWorker = registration.active!;
    return serviceWorker;
  }

  var serviceWorker = await registerAndReady();
  return _SqfliteFfiWebContext(options: options, serviceWorker: serviceWorker);
}

class _SqfliteFfiWebContext extends SqfliteFfiWebContext {
  /// Null when using service worker
  final FileSystem? fs;

  /// Null when using service worker
  final WasmSqlite3? wasmSqlite3;

  /// Optional Client service worker
  final sw.ServiceWorker? serviceWorker;

  _SqfliteFfiWebContext(
      {required SqfliteFfiWebOptions options,
      this.fs,
      this.wasmSqlite3,
      this.serviceWorker})
      : super(options: options);
}

/// Web context extension for web only
extension SqfliteFfiWebContextExt on SqfliteFfiWebContext {
  _SqfliteFfiWebContext get _context => this as _SqfliteFfiWebContext;

  /// File system if any
  FileSystem? get fs => _context.fs;

  /// Service worker if any
  sw.ServiceWorker? get serviceWorker => _context.serviceWorker;

  /// Loaded wasm if any
  WasmSqlite3? get wasmSqlite3 => _context.wasmSqlite3;
}
