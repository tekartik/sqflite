/// sqflite ffi based implementation for flutter.
///
/// On io platforms, the sqflite isolate send port is shared between flutter
/// isolates using `IsolateNameServer` so that all the isolates of an
/// application (main isolate, `compute`, `Isolate.run`...) use the same
/// sqflite isolate and share the same database instances.
library;

export 'package:sqflite_common_ffi/sqflite_ffi.dart'
    hide databaseFactoryFfi, createDatabaseFactoryFfi;

export 'src/sqflite_ffi.dart'
    show
        databaseFactoryFfi,
        createDatabaseFactoryFfi,
        sqfliteFfiIsolatePortName;
