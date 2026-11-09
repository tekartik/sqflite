import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// The name used to register the sqflite isolate send port.
///
/// Not used on the web (there is no sqflite isolate to share).
const sqfliteFfiIsolatePortName = 'com.tekartik.sqflite_ffi.isolate';

/// Not supported on the web: throws an [UnsupportedError] (use
/// `databaseFactoryFfiWeb` of the `sqflite_common_ffi_web` package).
ffi.DatabaseFactory get sqfliteDatabaseFactoryFfi => ffi.databaseFactoryFfi;

/// Not supported on the web: throws an [UnimplementedError] (use
/// `databaseFactoryFfiWeb` of the `sqflite_common_ffi_web` package).
ffi.DatabaseFactory createSqfliteDatabaseFactoryFfi({
  ffi.SqfliteFfiInit? ffiInit,
}) => ffi.createDatabaseFactoryFfi(ffiInit: ffiInit);

/// sqflite_ffi plugin registration (io platforms only).
class SqfliteFfiPlugin {
  SqfliteFfiPlugin._();

  /// Main entry point called by the flutter platform, noop on the web.
  static void registerWith() {}
}
