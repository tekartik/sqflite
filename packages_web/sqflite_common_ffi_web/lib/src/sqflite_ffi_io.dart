import 'package:sqflite_common/sqlite_api.dart';

/// The database factory to use for ffi.
///
/// Check support documentation.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfiWebNoWebWorker => throw UnsupportedError(
    'databaseFactoryFfiWebNoWebWorker only supported on the web');
