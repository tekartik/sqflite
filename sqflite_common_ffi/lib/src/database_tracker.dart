import 'dart:ffi';

import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

/// Copied from moor
/// This entire file is an elaborate hack to workaround https://github.com/simolus3/moor/issues/835.
///
/// Users were running into database deadlocks after (stateless) hot restarts
/// in Flutter when they use transactions. The problem is that we don't have a
/// chance to call `sqlite3_close` before a Dart VM restart, the Dart object is
/// just gone without a trace. This means that we're leaking sqlite3 database
/// connections on restarts.
/// Even worse, those connections might have a lock on the database, for
/// instance if they just started a transaction.
///
/// Our solution is to store open sqlite3 database connections in an in-memory
/// sqlite database which can survive restarts! For now, we keep track of the
/// pointer of an sqlite3 database handle in that database.
/// At an early stage of their `main()` method, users can now use
/// `VmDatabase.closeExistingInstances()` to release those resources.
DatabaseTracker get tracker => _tracker ??= DatabaseTracker();
DatabaseTracker? _tracker;

var _tableName = 'open_connections';
var _ptrColName = 'db_pointer';

/// Internal class that we don't export to sqflite users. See [tracker] for why
/// this is necessary.
class DatabaseTracker {
  /// Creates a new tracker with necessary tables.
  ///
  /// If the table exists delete any open connection.
  DatabaseTracker() {
    try {
      _db = sqlite3.open(
        'file:sqflite_database_tracker?mode=memory&cache=shared',
        uri: true,
      );
      var tableExists = (_db!
              .select(
                  'SELECT COUNT(*) FROM sqlite_master WHERE tbl_name = \'$_tableName\'')
              .first
              .columnAt(0) as int) >
          0;
      if (!tableExists) {
        _db!.execute('''
CREATE TABLE IF NOT EXISTS $_tableName (
  $_ptrColName INTEGER NOT NULL PRIMARY KEY
);
    ''');
      } else {
        _closeExisting();
      }
    } catch (e) {
      print('error $e creating tracker db');
    }
  }

  Database? _db;

  /// Tracks the [db]. The [path] argument can be used to track the path
  /// of that database, if it's bound to a file.
  void markOpened(Database db) {
    final ptr = db.handle.address;
    try {
      _db?.execute('INSERT INTO $_tableName($_ptrColName) VALUES($ptr)');
    } catch (_) {
      // Handle when the same pointer is inserted twice
      // sqlite tends to reuse the same pointer
    }
  }

  /// Marks the database [db] as closed.
  void markClosed(CommonDatabase db) {
    final ptr = (db as Database).handle.address;
    _db?.execute('DELETE FROM $_tableName WHERE $_ptrColName = $ptr');
  }

  /// Closes tracked database connections.
  void _closeExisting() {
    if (_db != null) {
      _db!.execute('BEGIN;');
      try {
        final results = _db!.select('SELECT $_ptrColName FROM $_tableName');
        for (final row in results) {
          final ptr = Pointer.fromAddress(row.columnAt(0) as int);
          try {
            sqlite3.fromPointer(ptr).dispose();
          } catch (e) {
            print('error $e disposing $ptr');
          }
        }
        _db!.execute('DELETE FROM $_tableName;');
      } finally {
        _db!.execute('COMMIT;');
      }
    }
  }
}
