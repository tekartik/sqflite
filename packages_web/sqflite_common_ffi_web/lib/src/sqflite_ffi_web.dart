import 'package:sqflite_common/sqlite_api.dart';

import 'database_factory_web.dart';

/// The database factory to use for ffi.
///
/// Check support documentation.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfiWebNoWebWorker =>
    databaseFactoryFfiWebNoWebWorkerImpl;
