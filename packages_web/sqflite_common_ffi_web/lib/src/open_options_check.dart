// ignore: implementation_imports
import 'package:sqflite_common/src/constant.dart'
    show paramPath, paramSingleInstance;
// ignore: implementation_imports
import 'package:sqflite_common/src/path_utils.dart' show isInMemoryDatabasePath;

/// Check the `openDatabase` arguments sent to the web implementation.
///
/// Multiple connections to the same database file are not supported on the
/// web: all the databases of a factory are opened in a single sqlite3 (wasm)
/// instance using a single virtual file system (an in-memory image persisted
/// in IndexedDB). This virtual file system has no locking between
/// connections so two connections writing to the same file could interleave
/// their pages and corrupt the database.
///
/// Throws an [ArgumentError] if `singleInstance` is false for a persistent
/// database (in-memory databases are private to each connection so they can
/// be opened multiple times).
void checkOpenDatabaseArgumentsWeb(Object? arguments) {
  if (arguments is Map) {
    var singleInstance = arguments[paramSingleInstance] as bool?;
    var path = arguments[paramPath] as String?;
    if (singleInstance == false &&
        path != null &&
        !isInMemoryDatabasePath(path)) {
      throw ArgumentError(
        'singleInstance: false is not supported on the web (database \'$path\'). '
        'All the connections of a web factory share a single sqlite3 instance '
        'and a single virtual file system without locking between connections, '
        'so opening the same database file more than once could corrupt it. '
        'Open the database once with the default singleInstance: true '
        '(subsequent openDatabase calls with the same path return the same '
        'instance).',
      );
    }
  }
}
