import 'dart:isolate';
import 'dart:ui';

import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// The name used to register the sqflite isolate send port with
/// [IsolateNameServer].
const sqfliteFfiIsolatePortName = 'com.tekartik.sqflite_ffi.isolate';

/// Shares the sqflite isolate send port between flutter isolates using
/// [IsolateNameServer].
class _IsolateNameServerPortServer implements ffi.SqfliteFfiIsolatePortServer {
  @override
  SendPort? lookupPort() =>
      IsolateNameServer.lookupPortByName(sqfliteFfiIsolatePortName);

  @override
  bool registerPort(SendPort sendPort) =>
      IsolateNameServer.registerPortWithName(
        sendPort,
        sqfliteFfiIsolatePortName,
      );

  @override
  bool unregisterPort() =>
      IsolateNameServer.removePortNameMapping(sqfliteFfiIsolatePortName);
}

final _portServer = _IsolateNameServerPortServer();

/// The database factory to use for ffi in a flutter application.
///
/// The sqflite isolate is shared between flutter isolates using
/// [IsolateNameServer]: the first isolate using the factory spawns the
/// sqflite isolate and registers its send port, the other isolates
/// (`compute`, `Isolate.run`...) reuse it.
///
/// Check support documentation. Currently supports Win/Mac/Linux.
final ffi.DatabaseFactory sqfliteDatabaseFactoryFfi =
    createSqfliteDatabaseFactoryFfi();

/// Creates an FFI database factory sharing the sqflite isolate between
/// flutter isolates using [IsolateNameServer].
///
/// [ffiInit] is an optional initialization function to override sqlite3 dynamic
/// library opening behavior. If provided, it must be a top-level or static function.
///
/// Returns a new [ffi.DatabaseFactory] configured to share the sqflite isolate
/// port across Flutter isolates.
///
/// Prefer using the [sqfliteDatabaseFactoryFfi] getter if you don't need
/// custom [ffiInit] behavior.
ffi.DatabaseFactory createSqfliteDatabaseFactoryFfi({
  ffi.SqfliteFfiInit? ffiInit,
}) => ffi.createDatabaseFactoryFfi(
  ffiInit: ffiInit,
  isolatePortServer: _portServer,
);

/// sqflite_ffi plugin registration.
class SqfliteFfiPlugin {
  SqfliteFfiPlugin._();

  /// Main entry point called by the flutter platform.
  ///
  /// Initializes ffi (Windows specific setup) and registers
  /// [sqfliteDatabaseFactoryFfi] as the default database factory (if not
  /// already set).
  static void registerWith() {
    ffi.sqfliteFfiInit();
    ffi.databaseFactoryOrNull ??= sqfliteDatabaseFactoryFfi;
  }
}
