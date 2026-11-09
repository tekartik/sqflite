import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Creates a web database factory with its own [options] (sqlite3.wasm and
/// worker urls, IndexedDB name).
///
/// SQLite runs in a shared worker (`sqflite_sw.js`), or in the page when
/// [noWebWorker] is true (only `sqlite3.wasm` needed, not safe across tabs).
/// [tag] names the factory in the logs.
///
/// Web only: throws [UnsupportedError] on io.
DatabaseFactory createDatabaseFactoryFfiWeb({
  SqfliteFfiWebOptions? options,
  bool noWebWorker = false,
  String? tag,
}) => throw UnsupportedError(
  'createDatabaseFactoryFfiWeb is only supported on the web, use the sqflite '
  'plugin (Android, iOS, macOS) or createDatabaseFactoryFfi from '
  'sqflite_common_ffi (desktop, Dart VM) here',
);
