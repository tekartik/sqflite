import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The database factory to use for ffi.
///
/// Check support documentation.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfi => throw UnimplementedError(
    'databaseFactoryFfi only supported for io application');

/// The database factory to use for ffi without creating a separate isolate.
///
/// This should only be used from a background isolate.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfiNoIsolate => throw UnimplementedError(
    'databaseFactoryFfiNoIsolate only supported for io application');

/// Creates an FFI database factory
DatabaseFactory createDatabaseFactoryFfi(
        {SqfliteFfiInit? ffiInit, bool noIsolate = false}) =>
    throw UnimplementedError(
        'createDatabaseFactoryFfi only supported for io application');

/// Optional. Initialize ffi loader.
///
/// Call in main until you find a loader for your needs.
void sqfliteFfiInit() => throw UnimplementedError(
    'sqfliteFfiInit only supported for io application');
