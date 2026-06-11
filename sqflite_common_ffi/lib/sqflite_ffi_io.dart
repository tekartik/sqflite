/// io specific API (not supported on the web).
///
/// In addition to the default sqflite ffi API, it exposes
/// [SqfliteFfiIsolatePortServer] allowing to share the sqflite isolate
/// between isolates (typically using Flutter `IsolateNameServer`, see the
/// `sqflite_ffi` package).
library;

export 'sqflite_ffi.dart';
export 'src/isolate.dart' show SqfliteFfiIsolatePortServer;
export 'src/sqflite_ffi_io.dart' show createDatabaseFactoryFfi;
