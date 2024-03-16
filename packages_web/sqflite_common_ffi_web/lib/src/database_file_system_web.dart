import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/platform.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart';
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

import 'import.dart';
import 'web/worker_message_utils.dart';

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
      var exists = fs.xAccess(path, 0) != 0;
      if (exists) {
        fs.xDelete(path, 0);
      }

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
      var exists = fs.xAccess(path, 0) != 0;
      if (exists) {
        fs.xDelete(path, 0);
      }
      if (fs is IndexedDbFileSystem) {
        await fs.flush();
      }
    } catch (_) {
      // Ignore errors
    }
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

/// Post message sender to worker.
class RawMessageSenderToWorker extends RawMessageSender {
  final web.Worker _worker;

  /// Post message sender to worker.
  RawMessageSenderToWorker(this._worker);

  @override
  void postMessage(Object message, web.MessagePort responsePort) {
    _worker.postMessage(
        message.jsify(), messagePortToPortMessageOption(responsePort));
  }

  StreamController<Object>? _errorController;

  @override
  Stream<Object> get onError {
    if (_errorController == null) {
      var zone = Zone.current;
      _errorController = StreamController<Object>.broadcast(onListen: () {
        _worker.onerror = (web.Event event) {
          zone.run(() {
            _errorController!.add(event);
          });
        }.toJS;
      }, onCancel: () {
        _errorController = null;
        _worker.onerror = null;
      });
    }
    return _errorController!.stream;
  }
}
