import 'package:sqflite_common_ffi/src/sqflite_ffi_impl.dart';
import 'package:sqlite3/wasm.dart';

/// Default handler
class SqfliteFfiHandlerIo extends SqfliteFfiHandler {
  @override
  Future<CommonDatabase> openPlatform(Map argumentsMap) {
    throw UnsupportedError('Web not supported');
  }
}

/// Delete the database file.
Future<void> deleteDatabasePlatform(String path) async {
  throw UnsupportedError('Web not supported');
}

/// Check if database file exists
Future<bool> handleDatabaseExistsPlatform(String path) async {
  throw UnsupportedError('Web not supported');
}

/// Default database path.
String getDatabasesPathPlatform() {
  throw UnsupportedError('Web not supported');
}
