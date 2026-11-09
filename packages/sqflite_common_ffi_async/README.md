# sqflite_common_ffi_async

The [sqflite](https://pub.dev/packages/sqflite) API on top of
[sqlite_async](https://pub.dev/packages/sqlite_async) (thanks to
[PowerSync](https://github.com/powersync-ja)): a connection pool with one
writer and several readers in background isolates, so reads do not wait behind
writes. Experimental.

[![pub package](https://img.shields.io/pub/v/sqflite_common_ffi_async.svg)](https://pub.dev/packages/sqflite_common_ffi_async)

- Same API as `sqflite` (`openDatabase`, `Database`, `Transaction`, `Batch`...),
  see the [sqflite documentation](https://pub.dev/packages/sqflite), plus
  `readTransaction` for concurrent reads.
- Linux, macOS and Windows (Dart VM and Flutter desktop); Android and iOS are
  declared too. SQLite is bundled by the `sqlite3` 3.x build hooks, as for
  [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi). No web
  support: use [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).

## Getting started

```bash
dart pub add sqflite_common_ffi_async sqflite_common_ffi
```

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit;
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var factory = databaseFactoryFfiAsync;
  var db = await factory.openDatabase(
    'example.db', // in factory.getDatabasesPath()
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT)',
        );
      },
    ),
  );
  await db.insert('Product', {'title': 'Product 1'});
  print(await db.query('Product'));
  await db.close();
}
```

`sqflite_ffi_async.dart` exports the sqflite API
(`package:sqflite_common/sqflite.dart`); `sqfliteFfiInit()` comes from
`sqflite_common_ffi`. A relative path is in `getDatabasesPath()`
(`.dart_tool/sqflite_common_ffi/databases` of the current directory by
default, as `databaseFactoryFfi`), prefer absolute paths in an application.

## When to use it

| Factory | Package | Concurrency |
|---|---|---|
| `databaseFactoryFfi` | `sqflite_common_ffi` | one background isolate, one connection: every call in order |
| `databaseFactoryFfiAsync` | this one | a writer and readers: `readTransaction` and the reads outside a transaction run while a write transaction is open |

```dart
var count = await db.readTransaction((txn) async {
  // A read connection: sees the last committed data, even during a write
  // transaction. A write through this txn throws.
  return (await txn.rawQuery('SELECT COUNT(*) AS c FROM Product')).first['c'];
});
```

With the other factories `readTransaction` is a normal transaction, rolled back
at the end: it waits for the other transactions. `databaseFactoryFfiAsyncTest`
is a second, independent factory for tests.

## What differs from sqflite_common_ffi

- The databases use WAL mode (`-wal` and `-shm` files next to the database).
  `deleteDatabase` deletes them too, and `readDatabaseBytes` of an open
  database checkpoints it first.
- In memory databases (`inMemoryDatabasePath`, `file::memory:`) and read-only
  opens go to `databaseFactoryFfi`.
- `singleInstance` (default true) gives the same `Database` for the same path,
  as elsewhere. sqlite_async shares its connection pool by path: deleting an
  open database closes it.
- No logger (`SqfliteDatabaseFactoryLogger`) support, and `queryCursor` /
  `rawQueryCursor` read the whole result at once.

## Common mistakes

- Calling a `db` method (instead of `txn`) inside a transaction: it throws a
  `DatabaseException` (sqlite_async `LockError`, where other factories wait
  forever). Use the `txn` of the callback.
- Writing in `readTransaction`: throws a `DatabaseException`, use
  `transaction`.
- Expecting concurrent reads from `readTransaction` with another factory:
  there it runs after the current transaction, as any transaction.
- Depending on `sqflite_common_ffi_async` only: add `sqflite_common_ffi` too
  for `sqfliteFfiInit()`.
- Copying the database file while it is open: use `readDatabaseBytes`, the last
  changes may still be in the `-wal` file.
