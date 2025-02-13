import 'load_sqlite.dart';

/// Web only
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3FileSystem(
  SqfliteFfiWebOptions options,
) => throw UnsupportedError('loadSqlite3FileSystemWeb not supported on io');

/// Web only
Future<SqfliteFfiWebContext> sqfliteFfiWebLoadSqlite3Wasm(
  SqfliteFfiWebOptions options, {
  SqfliteFfiWebContext? context,
  bool? fromWebWorker,
}) => throw UnsupportedError('loadSqlite3Wasm not supported on io');

/// Web only
Future<SqfliteFfiWebContext> sqfliteFfiWebStartSharedWorker(
  SqfliteFfiWebOptions options,
) =>
    throw UnsupportedError(
      'sqfliteFfiWebStartSharedWorker not supported on io',
    );
