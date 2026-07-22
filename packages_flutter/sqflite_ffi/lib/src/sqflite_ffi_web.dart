import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// The name used to register the sqflite isolate send port.
///
/// Not used on the web (there is no sqflite isolate to share).
const sqfliteFfiIsolatePortName = 'com.tekartik.sqflite_ffi.isolate';

/// The database factory to use for ffi on the web.
///
/// Returns [ffi.databaseFactoryFfi]. There is no isolate sharing on the web.
ffi.DatabaseFactory get sqfliteDatabaseFactoryFfi => ffi.databaseFactoryFfi;

/// Creates an FFI database factory on the web (no isolate sharing on web).
///
/// [ffiInit] is an optional function to override sqlite3 initialization.
///
/// Returns a new [ffi.DatabaseFactory].
ffi.DatabaseFactory createSqfliteDatabaseFactoryFfi({
  ffi.SqfliteFfiInit? ffiInit,
}) => ffi.createDatabaseFactoryFfi(ffiInit: ffiInit);

/// sqflite_ffi plugin registration (io platforms only).
class SqfliteFfiPlugin {
  SqfliteFfiPlugin._();

  /// Main entry point called by the flutter platform, noop on the web.
  static void registerWith() {}
}
