import 'package:sqlite3/common.dart' as common;

/// Opens the database using an ffi implementation
Future<common.CommonDatabase> handleOpenPlatform(Map argumentsMap) async {
  throw UnimplementedError();
}

/// Delete the database file.
Future<void> deleteDatabasePlatform(String path) async {
  throw UnimplementedError();
}

/// Check if database file exists
Future<bool> handleDatabaseExistsPlatform(String path) async {
  throw UnimplementedError();
}
