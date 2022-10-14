import 'package:sqflite_common/sqlite_api.dart';

import 'database_factory_web.dart';

/// The database factory to use for ffi web.
///
/// Currently does not support web worker. Work in progress.
///
/// Check support documentation.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfiWeb => databaseFactoryFfiWebImpl;

/// The database factory to use for ffi web without web worker.
///
/// Check support documentation.
///
/// Run in the main ui thread so long query could potentially hang.
DatabaseFactory get databaseFactoryFfiWebNoWebWorker =>
    databaseFactoryFfiWebNoWebWorkerImpl;
