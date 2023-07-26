import 'dart:io';
import 'dart:typed_data';

import 'database_file_system.dart';

/// IO implementation of [DatabaseFileSystem]
class DatabaseFileSystemIo implements DatabaseFileSystem {
  /// Safe delete a files
  Future<void> _safeDeleteFile(String path) async {
    try {
      await File(path).delete(recursive: true);
    } catch (_) {}
  }

  /// Delete the database file including its journal file and other auxiliary files
  @override
  Future<void> deleteDatabase(String path) async {
    await _safeDeleteFile(path);
    await _safeDeleteFile('$path-wal');
    await _safeDeleteFile('$path-shm');
    await _safeDeleteFile('$path-journal');
  }

  /// Read a database file as bytes.
  @override
  Future<Uint8List> readDatabaseBytes(String path) async {
    return await File(path).readAsBytes();
  }

  /// Write database files bytes.
  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async {
    var file = File(path);
    var dir = file.parent;
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Check if database file exists.
  @override
  Future<bool> databaseExists(String path) async {
    // Ignore failure
    try {
      return (File(path)).existsSync();
    } catch (_) {
      return false;
    }
  }
}
