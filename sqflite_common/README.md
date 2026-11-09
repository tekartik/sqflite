# sqflite common

The platform independent API of [sqflite](https://pub.dev/packages/sqflite):
`DatabaseFactory`, `Database`, `Transaction`, `Batch`, `OpenDatabaseOptions`,
`DatabaseException`... It does not contain SQLite itself: an implementation
package provides a `DatabaseFactory`.

## Which package to use

| Platform | Package | Factory |
|---|---|---|
| Flutter on Android, iOS, macOS | [sqflite](https://pub.dev/packages/sqflite) | `databaseFactory`, set by the plugin |
| Windows, Linux, macOS (Flutter or Dart VM), unit tests | [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | `databaseFactoryFfi`, after `sqfliteFfiInit()` |
| Flutter, ffi on every platform | [sqflite_ffi](https://pub.dev/packages/sqflite_ffi) | `sqfliteDatabaseFactoryFfi`, set by the plugin |
| Web | [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) | `databaseFactoryFfiWeb` |

An application depends on one (or several) of these packages. They all
re-export this API, so an application does not need to depend on
`sqflite_common` itself.

Depend on `sqflite_common` directly when your code must not depend on a
platform: a package shared by a Flutter app and a Dart program, or code tested
with `sqflite_common_ffi`. Import `package:sqflite_common/sqlite_api.dart` and
take a `DatabaseFactory` as a parameter.

## Usage in platform independent code

```dart
import 'package:sqflite_common/sqlite_api.dart';

/// Platform independent code: it only needs a [DatabaseFactory].
class NoteStore {
  NoteStore(this.factory, this.path);

  final DatabaseFactory factory;
  final String path;
  Future<Database>? _db;

  /// Opened once, on first use.
  Future<Database> get database => _db ??= factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, content TEXT NOT NULL)',
        );
      },
    ),
  );

  Future<int> add(String content) async {
    var db = await database;
    return db.insert('Note', {'content': content});
  }

  Future<List<String>> list() async {
    var db = await database;
    var rows = await db.query('Note', orderBy: 'id');
    return rows.map((row) => row['content'] as String).toList();
  }

  Future<void> close() async {
    var db = await _db;
    _db = null;
    await db?.close();
  }
}
```

The caller gives the factory and the path:
* Flutter (`sqflite`): `NoteStore(databaseFactory, join(await getDatabasesPath(), 'notes.db'))`
* Dart VM, desktop, tests (`sqflite_common_ffi`): `sqfliteFfiInit();` then
  `NoteStore(databaseFactoryFfi, path)` (`inMemoryDatabasePath` in tests)
* Web (`sqflite_common_ffi_web`): `NoteStore(databaseFactoryFfiWeb, 'notes.db')`

## Global API

`package:sqflite_common/sqflite.dart` adds the global `openDatabase()`,
`deleteDatabase()`, `getDatabasesPath()`... which use the global
`databaseFactory`. The `sqflite` plugin sets it on Android, iOS and macOS;
elsewhere, set it once in `main()` (`databaseFactory = databaseFactoryFfi;`).
Using the global before it is set throws `databaseFactory not initialized`.

## Rules

* Open a database once and keep it. With the default `singleInstance: true`,
  opening the same path again returns the same `Database`, including for
  `inMemoryDatabasePath` while it is open.
* `onCreate`, `onUpgrade` and `onDowngrade` run in a transaction; increment
  `version` for any schema change.
* In a transaction, use the `Transaction` object, not the `Database` (deadlock).
* Values are `int`, `num`, `String`, `Uint8List` or `null`; pass them as `?`
  arguments, not in the SQL string.

See the [sqflite README](https://pub.dev/packages/sqflite) for a longer list
of common pitfalls.

## Documentation

* [sqflite documentation](https://github.com/tekartik/sqflite/blob/master/sqflite/README.md)
  (opening a database, SQL, transactions, batches)
* [Iterate through results](https://github.com/tekartik/sqflite/blob/master/sqflite_common/doc/sqflite_iterate.md) using a cursor
* [SqfliteSqlCommand](https://github.com/tekartik/sqflite/blob/master/sqflite_common/doc/sqflite_sql_command.md) to prepare commands
* [Logger](https://github.com/tekartik/sqflite/blob/master/sqflite_common/doc/sqflite_logger.md)
* [API reference](https://pub.dev/documentation/sqflite_common/latest/)
