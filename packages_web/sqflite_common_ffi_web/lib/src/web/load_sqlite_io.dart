import 'load_sqlite.dart';

/// Web only
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3FileSystem(
        SqfliteFfiWebOptions options) =>
    throw UnsupportedError('loadSqlite3FileSystemWeb not supported on io');

/// Web only
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3Wasm(
        SqfliteFfiWebOptions options,
        {SqfliteFfiWebContext? context}) =>
    throw UnsupportedError('loadSqlite3Wasm not supported on io');

/// Web only
Future<SqfliteFfiWebContext> sqfliteFfiWebStartWebWorker(
        SqfliteFfiWebOptions options) =>
    throw UnsupportedError('sqfliteFfiWebStartWebWorker not supported on io');
