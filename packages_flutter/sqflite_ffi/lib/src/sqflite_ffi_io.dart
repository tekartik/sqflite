import 'dart:isolate';
import 'dart:ui';

import 'package:sqflite_common_ffi/sqflite_ffi_io.dart' as ffi;

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
final ffi.DatabaseFactory databaseFactoryFfi = createDatabaseFactoryFfi();

/// Creates an FFI database factory sharing the sqflite isolate between
/// flutter isolates using [IsolateNameServer].
///
/// Optionally an [ffiInit] function can be provided if you want to override
/// some behavior with the sqlite3 dynamic library opening. This function
/// should be either a top level function or a static function.
///
/// Prefer the use of the [databaseFactoryFfi] getter if you don't need this
/// functionality.
ffi.DatabaseFactory createDatabaseFactoryFfi({ffi.SqfliteFfiInit? ffiInit}) =>
    ffi.createDatabaseFactoryFfi(
      ffiInit: ffiInit,
      isolatePortServer: _portServer,
    );
