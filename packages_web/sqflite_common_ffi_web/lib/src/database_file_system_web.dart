import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/platform.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/web/js_converter.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart';
import 'package:sqlite3/wasm.dart';

import 'import.dart';

/// Database file system on sqlite virtual file system.
class SqfliteDatabaseFileSystemFfiWeb implements DatabaseFileSystem {
  ///  sqlite virtual file system.
  final VirtualFileSystem fs;

  /// Database file system on sqlite virtual file system.
  SqfliteDatabaseFileSystemFfiWeb(this.fs);
  @override
  Future<bool> databaseExists(String path) async {
    var fs = this.fs;
    // Ignore failure
    try {
      final canAccess = fs.xAccess(path, 0);
      return canAccess != 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteDatabase(String path) async {
    var fs = this.fs;
    // Ignore failure
    try {
      fs.xDelete(path, 0);
      if (fs is IndexedDbFileSystem) {
        await fs.flush();
      }
    } finally {}
  }

  @override
  Future<Uint8List> readDatabaseBytes(String path) async {
    await _flush();
    var fs = this.fs;
    final file =
        fs.xOpen(Sqlite3Filename(path), SqlFlag.SQLITE_OPEN_READONLY).file;
    try {
      var size = file.xFileSize();
      var target = Uint8List(size);
      file.xRead(target, 0);
      return target;
    } finally {
      file.xClose();
    }
  }

  Future<void> _flush() async {
    var fs = this.fs;

    if (fs is IndexedDbFileSystem) {
      try {
        await fs.flush();
      } catch (_) {}
    }
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async {
    await _flush();
    final file = fs
        .xOpen(Sqlite3Filename(path),
            SqlFlag.SQLITE_OPEN_READWRITE | SqlFlag.SQLITE_OPEN_CREATE)
        .file;
    try {
      file.xTruncate(0);
      file.xWrite(bytes, 0);

      await _flush();
    } finally {
      file.xClose();
    }
  }
}

bool get _debug => sqliteFfiWebDebugWebWorker;

/// Worker client log prefix for debug mode.
var workerClientLogPrefix = '/sw_client'; // Log prefix
var _swc = workerClientLogPrefix; // Log prefix

/// Ffi web handler for custom open/delete operation
class SqfliteFfiHandlerWeb extends SqfliteFfiHandler
    with SqfliteFfiHandlerNonImplementedMixin {
  /// Global context
  final SqfliteFfiWebContext context;

  WasmSqlite3? _sqlite3;
  VirtualFileSystem? _fs;

  /// Web handler for common sqlite3 web env
  SqfliteFfiHandlerWeb(this.context);

  /// Init file system.
  Future<VirtualFileSystem> initFs() async {
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
      fs.xDelete(path, 0);
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
      final canAccess = fs.xAccess(path, 0);
      return canAccess != 0;
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
  var _firstMessage = true;

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
    // Let's handle initialization error on the first message.
    if (_firstMessage) {
      _firstMessage = false;
      onError.listen((event) {
        if (_debug) {
          print('$_swc error ${jsObjectAsMap(event)}');
        }

        if (!completer.isCompleted) {
          completer.completeError(SqfliteFfiWebWorkerException());
        }
      });
    }

    // This sends the message data as well as transferring messageChannel.port2 to the shared worker.
    // The shared worker can then use the transferred port to reply via postMessage(), which
    // will in turn trigger the onmessage handler on messageChannel.port1.
    // See https://html.spec.whatwg.org/multipage/workers.html#dom-worker-postmessage
    postMessage(message, [messageChannel.port2]);
    return completer.future;
  }

  /// Basic error handling, likely at initialization.
  Stream<Object> get onError;
}

/// Post message sender to shared worker.
class RawMessageSenderSharedWorker extends RawMessageSender {
  final html.SharedWorker _sharedWorker;

  html.MessagePort get _port => _sharedWorker.port as html.MessagePort;

  /// Post message sender to shared worker.
  RawMessageSenderSharedWorker(this._sharedWorker);

  @override
  void postMessage(Object message, List<Object> transfer) {
    _port.postMessage(message, transfer);
  }

  @override
  Stream<Object> get onError => _sharedWorker.onError;
}

/// Post message sender to worker.
class RawMessageSenderToWorker extends RawMessageSender {
  final html.Worker _worker;

  @override
  Stream<Object> get onError => _worker.onError;

  /// Post message sender to worker.
  RawMessageSenderToWorker(this._worker);

  @override
  void postMessage(Object message, List<Object> transfer) {
    _worker.postMessage(message, transfer);
  }
}
