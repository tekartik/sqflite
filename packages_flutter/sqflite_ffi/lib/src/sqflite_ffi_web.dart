import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// Not used on the web (there is no sqflite isolate to share).
const sqfliteFfiIsolatePortName = 'com.tekartik.sqflite_ffi.isolate';

/// The database factory to use for ffi on the web.
///
/// There is no isolate sharing on the web, this is the default
/// sqflite_common_ffi web factory.
ffi.DatabaseFactory get databaseFactoryFfi => ffi.databaseFactoryFfi;

/// Creates an FFI database factory (no isolate sharing on the web).
ffi.DatabaseFactory createDatabaseFactoryFfi({ffi.SqfliteFfiInit? ffiInit}) =>
    ffi.createDatabaseFactoryFfi(ffiInit: ffiInit);
