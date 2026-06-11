import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// Not used on the web (there is no sqflite isolate to share).
const sqfliteFfiIsolatePortName = 'com.tekartik.sqflite_ffi.isolate';

/// The database factory to use for ffi on the web.
///
/// There is no isolate sharing on the web, this is the default
/// sqflite_common_ffi web factory.
ffi.DatabaseFactory get sqfliteDatabaseFactoryFfi => ffi.databaseFactoryFfi;

/// Creates an FFI database factory (no isolate sharing on the web).
ffi.DatabaseFactory createSqfliteDatabaseFactoryFfi({
  ffi.SqfliteFfiInit? ffiInit,
}) => ffi.createDatabaseFactoryFfi(ffiInit: ffiInit);

/// sqflite_ffi plugin registration (io platforms only).
///
/// On the web the registration goes through `SqfliteFfiWeb` (see
/// `sqflite_ffi_web_plugin.dart`).
class SqfliteFfiPlugin {
  /// Main entry point called by the flutter platform, noop on the web.
  static void registerWith() {}
}
