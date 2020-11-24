import 'package:sqflite_common/sqlite_api.dart';

/// The database factory to use for ffi.
///
/// Check support documentation.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfi => throw UnimplementedError(
    'databaseFactoryFfi only supported for io application');

DatabaseFactory createDatabaseFactoryFfi({void Function() ffiInit}) => throw UnimplementedError(
    'createDatabaseFactoryFfi only supported for io application');

/// Optional. Initialize ffi loader.
///
/// Call in main until you find a loader for your needs.
void sqfliteFfiInit() => throw UnimplementedError(
    'sqfliteFfiInit only supported for io application');
