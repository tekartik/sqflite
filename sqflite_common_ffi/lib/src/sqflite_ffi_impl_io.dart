import 'dart:io';

// import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite_common/src/mixin/constant.dart'; // ignore: implementation_imports
import 'package:sqflite_common_ffi/src/sqflite_ffi_impl.dart';
import 'package:sqlite3/common.dart' as common;
import 'package:sqlite3/sqlite3.dart' as ffi;

import 'database_tracker.dart';

/// Ffi handler.
class _SqfliteFfiHandlerIo extends SqfliteFfiHandler {
  /// Opens the database using an ffi implementation
  @override
  Future<common.CommonDatabase> openPlatform(Map argumentsMap) async {
    var path = argumentsMap['path'] as String;
    var singleInstance = (argumentsMap['singleInstance'] as bool?) ?? false;
    var readOnly = (argumentsMap['readOnly'] as bool?) ?? false;

    common.CommonDatabase? ffiDb;
    if (path == inMemoryDatabasePath) {
      ffiDb = ffi.sqlite3.openInMemory();
    } else {
      if (readOnly) {
        // ignore: avoid_slow_async_io
        if (!(await File(path).exists())) {
          throw StateError('file $path not found');
        }
      } else {
        // ignore: avoid_slow_async_io
        if (!(await File(path).exists())) {
          // Make sure its parent exists
          try {
            await Directory(dirname(path)).create(recursive: true);
          } catch (_) {}
        }
      }
      final mode =
          readOnly ? ffi.OpenMode.readOnly : ffi.OpenMode.readWriteCreate;
      ffiDb = ffi.sqlite3.open(path, mode: mode);

      // Handle hot-restart for single instance
      // The dart code is killed but the native code remains
      if (singleInstance) {
        if (ffiDb is ffi.Database) tracker.markOpened(ffiDb);
      }
    }

    return ffiDb;
  }

  /// Delete the database file.
  @override
  Future<void> deleteDatabasePlatform(String path) async {
    await File(path).delete();
  }

  /// Check if database file exists
  @override
  Future<bool> handleDatabaseExistsPlatform(String path) async {
    // Ignore failure
    try {
      return (File(path)).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Default database path.
  @override
  String getDatabasesPathPlatform() {
    return absolute(join('.dart_tool', 'sqflite_common_ffi', 'databases'));
  }

  @override
  Future<void> handleOptionsPlatform(Map argumentMap) async {
    // None yet, needed for the web
  }
}

/// Io handler
SqfliteFfiHandler sqfliteFfiHandlerIo = _SqfliteFfiHandlerIo();
