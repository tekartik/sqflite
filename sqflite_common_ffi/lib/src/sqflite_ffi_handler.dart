import 'dart:async';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:sqlite3/common.dart' as common;

/// Ffi handler.
abstract class SqfliteFfiHandler {
  /// Opens the database using an ffi implementation
  Future<common.CommonDatabase> openPlatform(Map argumentsMap);

  /// Delete the database file.
  Future<void> deleteDatabasePlatform(String path);

  /// Write the database i/o bytes.
  Future<void> writeDatabaseBytesPlatform(String path, Uint8List bytes);

  /// Write the database i/o bytes.
  Future<Uint8List> readDatabaseBytesPlatform(String path);

  /// Check if database file exists
  Future<bool> handleDatabaseExistsPlatform(String path);

  /// Default database path.
  String getDatabasesPathPlatform();

  /// Ffi specific options (for the web contains the sqlite3 wasm url)
  Future<void> handleOptionsPlatform(Map argumentMap);
}

/// Base unimplemented mixin.
mixin SqfliteFfiHandlerNonImplementedMixin implements SqfliteFfiHandler {
  @override
  Future<void> writeDatabaseBytesPlatform(String path, Uint8List bytes) =>
      throw UnimplementedError('$runtimeType.writeDatabaseBytesPlatform');

  @override
  Future<Uint8List> readDatabaseBytesPlatform(String path) =>
      throw UnimplementedError('$runtimeType.readDatabaseBytesPlatform');
}
