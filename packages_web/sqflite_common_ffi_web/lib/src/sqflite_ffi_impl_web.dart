import 'dart:async';
import 'dart:html' as html;

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart';
import 'package:sqlite3/wasm.dart';

import 'import.dart';

bool get _debug => sqliteFfiWebDebugWebWorker;

/// Worker client log prefix for debug mode.
var workerClientLogPrefix = '/sw_client'; // Log prefix
var _swc = workerClientLogPrefix; // Log prefix

/// Ffi web handler for custom open/delete operation
class SqfliteFfiHandlerWeb extends SqfliteFfiHandler {
  /// Global context
  final SqfliteFfiWebContext context;

  WasmSqlite3? _sqlite3;
  FileSystem? _fs;

  /// Web handler for common sqlite3 web env
  SqfliteFfiHandlerWeb(this.context);

  /// Init file system.
  Future<FileSystem> initFs() async {
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
    final fs = await initFs();
    try {
      fs.deleteFile(path);
      if (fs is IndexedDbFileSystem) {
        await fs.flush();
      }
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

  @override
  Future<void> handleOptionsPlatform(Map argumentMap) async {
    // No op
  }
}

/// Genereric Post message handler
abstract class RawMessageSender {
  /// Post message to implement
  void postMessage(Object message, List<Object> transfer);

  /// Returns response
  Future<Object?> sendRawMessage(Object message) {
    var completer = Completer<Object?>();
    // This wraps the message posting/response in a promise, which will resolve if the response doesn't
    // contain an error, and reject with the error if it does. If you'd prefer, it's possible to call
    // controller.postMessage() and set up the onmessage handler independently of a promise, but this is
    // a convenient wrapper.
    var messageChannel = html.MessageChannel();
    //var receivePort =ReceivePort();

    if (_debug) {
      print('$_swc sending $message');
    }
    messageChannel.port1.onMessage.listen((event) {
      if (_debug) {
        print('$_swc recv ${event.data}');
      }
      completer.complete(event.data);
    });

    // This sends the message data as well as transferring messageChannel.port2 to the shared worker.
    // The shared worker can then use the transferred port to reply via postMessage(), which
    // will in turn trigger the onmessage handler on messageChannel.port1.
    // See https://html.spec.whatwg.org/multipage/workers.html#dom-worker-postmessage
    postMessage(message, [messageChannel.port2]);
    return completer.future;
  }
}

/// Post message sender to shared worker.
class RawMessageSenderSharedWorker extends RawMessageSender {
  final html.SharedWorker _sharedWorker;

  /// Post message sender to shared worker.
  RawMessageSenderSharedWorker(this._sharedWorker);

  @override
  void postMessage(Object message, List<Object> transfer) {
    (_sharedWorker.port as html.MessagePort).postMessage(message, transfer);
  }
}

/// Post message sender to worker.
class RawMessageSenderToWorker extends RawMessageSender {
  final html.Worker _worker;

  /// Post message sender to worker.
  RawMessageSenderToWorker(this._worker);

  @override
  void postMessage(Object message, List<Object> transfer) {
    _worker.postMessage(message, transfer);
  }
}
