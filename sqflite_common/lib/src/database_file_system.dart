import 'dart:typed_data';

/// Abstract lightweight database file system.
abstract class DatabaseFileSystem {
  /// Delete the database file including its journal file and other auxiliary files
  Future<void> deleteDatabase(String path);

  /// Read a database file as bytes.
  Future<Uint8List> readDatabaseBytes(String path);

  /// Write database files bytes.
  Future<void> writeDatabaseBytes(String path, Uint8List bytes);

  /// Check if database file exists.
  Future<bool> databaseExists(String path);
}
