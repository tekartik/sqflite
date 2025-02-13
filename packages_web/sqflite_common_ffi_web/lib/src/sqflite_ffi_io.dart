import 'package:sqflite_common/sqlite_api.dart';

/// The database factory to use for ffi web. not supported on io
DatabaseFactory get databaseFactoryFfiWeb =>
    throw UnsupportedError(
      'databaseFactoryFfiWebNoWebWorker only supported on io',
    );

/// The database factory to use for ffi web. not supported on io
DatabaseFactory get databaseFactoryFfiWebNoWebWorker =>
    throw UnsupportedError(
      'databaseFactoryFfiWebNoWebWorker only supported on io',
    );

/// The database factory to use for ffi web. not supported on io
DatabaseFactory get databaseFactoryFfiWebBasicWebWorker =>
    throw UnsupportedError(
      'databaseFactoryFfiWebBasicWebWorker only supported on io',
    );
