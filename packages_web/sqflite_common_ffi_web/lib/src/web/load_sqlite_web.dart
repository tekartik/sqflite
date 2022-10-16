import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:service_worker/window.dart' as sw;
import 'package:service_worker/worker.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqlite3/wasm.dart';

import 'load_sqlite.dart';

bool get _debug => sqliteFfiWebDebugWebWorker;

/// Load base file system
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3FileSystem(
    SqfliteFfiWebOptions options) async {
  // devPrint('options');
  var indexedDbName = options.indexedDbName ?? 'sqflite_databases';
  final fs = await IndexedDbFileSystem.open(dbName: indexedDbName);
  return SqfliteFfiWebContextImpl(options: options, fs: fs);
}

// var _defaultSqlite3WasmUri = Uri.parse('sqflite/sqlite3.wasm');
// var _defaultServiceWorkerUri = Uri.parse('sqflite/sqflite_sw.dart.js');
var _defaultSqlite3WasmUri = Uri.parse('sqlite3.wasm');
var _defaultServiceWorkerUri = Uri.parse(sqfliteSwJsFile);
//var uri = options.sqlite3WasmUri ?? _defaultSqlite3WasmUri;
/// Default indexedDB name is /sqflite
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3Wasm(
    SqfliteFfiWebOptions options,
    {SqfliteFfiWebContext? context,
    bool? fromServiceWorker}) async {
  context ??= await sqfliteFfiWebLoadSqlite3FileSystem(options);
  var uri = options.sqlite3WasmUri ?? _defaultSqlite3WasmUri;
  Uint8List bodyBytes;
  if (_debug) {
    print('Loading sqlite3.wasm from $uri');
  }
  if (fromServiceWorker ?? false) {
    var self = ServiceWorkerGlobalScope.globalScope;
    final response = await self.fetch(uri.toString());
    bodyBytes = (await response.arrayBuffer()).asUint8List();
  } else {
    // regular http
    final response = await http.get(uri);
    bodyBytes = response.bodyBytes;
  }
  var webContext = (context as SqfliteFfiWebContextImpl);
  final fs = webContext.fs;
  var wasmSqlite3 =
      await WasmSqlite3.load(bodyBytes, SqliteEnvironment(fileSystem: fs));
  return SqfliteFfiWebContextImpl(
      options: options, fs: fs, wasmSqlite3: wasmSqlite3);
}

/// Start web worker (from client)
Future<SqfliteFfiWebContext> sqfliteFfiWebStartWebWorker(
    SqfliteFfiWebOptions options) async {
  try {
    var serviceWorkerUri = options.serviceWorkerUri ?? _defaultServiceWorkerUri;
    if (_debug) {
      print('/sw_client registering $serviceWorkerUri');
    }
    var registered = sw.register(serviceWorkerUri.toString());
    if (_debug) {
      print('/sw_client registered');
    }
    Future<sw.ServiceWorker> registerAndReady() async {
      await registered;
      if (_debug) {
        print('/sw_client waiting for ready');
      }
      var registration = await sw.ready;
      if (_debug) {
        print('/sw_client ready!');
      }
      var serviceWorker = registration.active!;
      return serviceWorker;
    }

    var serviceWorker = await registerAndReady();
    return SqfliteFfiWebContextImpl(
        options: options, serviceWorker: serviceWorker);
  } catch (e, st) {
    if (_debug) {
      print(e);
      print(st);
    }
    rethrow;
  }
}

/// Web implementation with service worker
class SqfliteFfiWebContextImpl extends SqfliteFfiWebContext {
  /// Null when using service worker
  final FileSystem? fs;

  /// Null when using service worker
  final WasmSqlite3? wasmSqlite3;

  /// Optional Client service worker
  final sw.ServiceWorker? serviceWorker;

  /// Web implementation with service worker
  SqfliteFfiWebContextImpl(
      {required SqfliteFfiWebOptions options,
      this.fs,
      this.wasmSqlite3,
      this.serviceWorker})
      : super(options: options);
}

/// Web context extension for web only
extension SqfliteFfiWebContextExt on SqfliteFfiWebContext {
  SqfliteFfiWebContextImpl get _context => this as SqfliteFfiWebContextImpl;

  /// File system if any
  FileSystem? get fs => _context.fs;

  /// Service worker if any
  sw.ServiceWorker? get serviceWorker => _context.serviceWorker;

  /// Loaded wasm if any
  WasmSqlite3? get wasmSqlite3 => _context.wasmSqlite3;
}
