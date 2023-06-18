import 'dart:html';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart';
import 'package:sqlite3/wasm.dart';

bool get _debug => sqliteFfiWebDebugWebWorker;

var _swc = workerClientLogPrefix; // Log prefix

/// Load base file system
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3FileSystem(
    SqfliteFfiWebOptions options) async {
  // devPrint('options');
  var indexedDbName = options.indexedDbName ?? 'sqflite_databases';
  final fs = await IndexedDbFileSystem.open(dbName: indexedDbName);
  return SqfliteFfiWebContextImpl(options: options, fs: fs);
}

var _defaultSqlite3WasmUri = Uri.parse('sqlite3.wasm');

/// Default shared worker Uri.
var defaultSharedWorkerUri = Uri.parse(sqfliteSharedWorkerJsFile);

/// Default indexedDB name is /sqflite
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3Wasm(
    SqfliteFfiWebOptions options,
    {SqfliteFfiWebContext? context,
    bool? fromWebWorker}) async {
  context ??= await sqfliteFfiWebLoadSqlite3FileSystem(options);
  var uri = options.sqlite3WasmUri ?? _defaultSqlite3WasmUri;
  if (_debug) {
    print('Loading sqlite3.wasm from $uri');
  }

  var webContext = (context as SqfliteFfiWebContextImpl);
  final fs = webContext.fs ?? InMemoryFileSystem();
  var wasmSqlite3 = await WasmSqlite3.loadFromUrl(uri);
  wasmSqlite3.registerVirtualFileSystem(fs, makeDefault: true);

  return SqfliteFfiWebContextImpl(
      options: options, fs: fs, wasmSqlite3: wasmSqlite3);
}

/// Start web worker (from client)
Future<SqfliteFfiWebContext> sqfliteFfiWebStartSharedWorker(
    SqfliteFfiWebOptions options) async {
  try {
    var name = 'sqflite_common_ffi_web';
    var sharedWorkerUri = options.sharedWorkerUri ?? defaultSharedWorkerUri;
    SharedWorker? sharedWorker;
    Worker? worker;
    try {
      if (!(options.forceAsBasicWorker ?? false)) {
        if (_debug) {
          print(
              '$_swc registering shared worker $sharedWorkerUri (name: $name)');
        }
        sharedWorker = SharedWorker(sharedWorkerUri.toString(), name);
      }
    } catch (e) {
      if (_debug) {
        print('SharedWorker creation failed $e');
      }
    }
    if (sharedWorker == null) {
      if (_debug) {
        print('$_swc registering worker $sharedWorkerUri');
      }
      worker = Worker(sharedWorkerUri.toString());
    }
    return SqfliteFfiWebContextImpl(
        options: options, sharedWorker: sharedWorker, worker: worker);
  } catch (e, st) {
    if (_debug) {
      print('sqfliteFfiWebLoadSqlite3Wasm failed: $e');
      print(st);
    }
    rethrow;
  }
}

/// Web implementation with shared worker
class SqfliteFfiWebContextImpl extends SqfliteFfiWebContext {
  /// Null when using shared worker
  final VirtualFileSystem? fs;

  /// Null when using shared worker
  final WasmSqlite3? wasmSqlite3;

  /// Optional Client shared worker
  final SharedWorker? sharedWorker;

  /// Optional Client basic worker (if sharedWorker not working)
  final Worker? worker;

  /// Raw message sender to either shared worker or basic worker
  late final RawMessageSender rawMessageSender;

  /// Web implementation with shared worker
  SqfliteFfiWebContextImpl(
      {required SqfliteFfiWebOptions options,
      this.fs,
      this.wasmSqlite3,
      this.sharedWorker,
      this.worker})
      : super(options: options) {
    if (sharedWorker != null) {
      rawMessageSender = RawMessageSenderSharedWorker(sharedWorker!);
    }
    if (worker != null) {
      rawMessageSender = RawMessageSenderToWorker(worker!);
    }
  }
}

/// Web context extension for web only
extension SqfliteFfiWebContextExt on SqfliteFfiWebContext {
  SqfliteFfiWebContextImpl get _context => this as SqfliteFfiWebContextImpl;

  /// File system if any
  VirtualFileSystem? get fs => _context.fs;

  /// Shared worker if any
  SharedWorker? get sharedWorker => _context.sharedWorker;

  /// Web worker if any
  SharedWorker? get webWorker => _context.sharedWorker;

  /// Loaded wasm if any
  WasmSqlite3? get wasmSqlite3 => _context.wasmSqlite3;

  /// Send raw message to worker
  Future<Object?> sendRawMessage(Object message) =>
      _context.rawMessageSender.sendRawMessage(message);
}

/// Web specific exception. For now only sent when catching a web worker error.
class SqfliteFfiWebWorkerException implements Exception {
  @override
  String toString() => 'SqfliteFfiWebException()';
}
