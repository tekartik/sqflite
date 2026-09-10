---
name: sqflite-common-ffi-async-factory
description: >-
  Use when using package:sqflite_common_ffi_async, the experimental sqflite
  DatabaseFactory built on sqlite_async (PowerSync) for desktop and the Dart
  VM: databaseFactoryFfiAsync, databaseFactoryFfiAsyncTest, readTransaction
  and concurrent reads, how it differs from sqflite_common_ffi
  (databaseFactoryFfi), what falls back to plain ffi (in-memory, read-only),
  and its limitations (no logger, singleInstance ignored, io only).
---

# sqflite_common_ffi_async: sqflite API on top of sqlite_async

`package:sqflite_common_ffi_async` exposes the sqflite `DatabaseFactory` /
`Database` API backed by `package:sqlite_async` (a connection pool with one
writer and several readers) instead of the single background isolate of
`sqflite_common_ffi`. Use it on Linux, macOS, Windows (Dart VM or Flutter
desktop) when reads must not wait behind writes. It is experimental (1.0.x).

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit;
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfiAsync.openDatabase('example.db');
  await db.execute('CREATE TABLE IF NOT EXISTS Product (id INTEGER PRIMARY KEY, title TEXT)');
  await db.insert('Product', {'title': 'Product 1'});
  print(await db.query('Product'));
  await db.close();
}
```

## Guidelines

* Depend on both `sqflite_common_ffi_async` and `sqflite_common_ffi` (the
  async package delegates some operations to it). Import
  `package:sqflite_common_ffi_async/sqflite_ffi_async.dart`; it re-exports
  `package:sqflite_common/sqflite.dart` (`Database`, `OpenDatabaseOptions`,
  `inMemoryDatabasePath`, global `databaseFactory`...). `sqfliteFfiInit`
  comes from `package:sqflite_common_ffi/sqflite_ffi.dart`; call it once at
  startup (Windows setup, no-op elsewhere).
* Public API: `databaseFactoryFfiAsync` (tag `ffi_async`) and
  `databaseFactoryFfiAsyncTest` (tag `ffi_async_test`, a second independent
  factory instance for tests). Everything else is under `src/`.
* The `Database` API (`query`, `insert`, `transaction`, `batch`,
  `OpenDatabaseOptions` callbacks) is the standard sqflite one, documented by
  the `sqflite` / `sqflite_common` skills. Code written against
  `DatabaseFactory` works unchanged; only the factory differs.
* What `sqlite_async` adds:
  * `db.readTransaction((txn) async { ... })` runs on a read connection
    concurrently with writes. Only reads are allowed inside: a write through
    that `txn` throws a `DatabaseException` ("read transaction cannot be used
    for write"). On other sqflite implementations `readTransaction` is not
    supported, so keep it behind this factory.
  * `db.transaction(...)` is a `sqlite_async` write transaction. Several
    `transaction` calls from different callers are queued by the pool, not by
    sqflite, so reads issued outside a transaction are not blocked by a
    running write transaction.
* Falls back to `databaseFactoryFfi` (regular ffi, separate isolate):
  * `openDatabase(inMemoryDatabasePath)`: in-memory databases come from
    `sqflite_common_ffi` (mainly for tests).
  * `openDatabase(path, options: OpenDatabaseOptions(readOnly: true))`.
  * `deleteDatabase(path)` and `getDatabasesPath()` (default is
    `<cwd>/.dart_tool/sqflite_common_ffi/databases`, relative paths resolve
    there).
* The parent directory of a database file is created on open. Prefer absolute
  paths in applications.
* Limitations (from the package README and source):
  * `singleInstance` is ignored: `sqlite_async` manages opening/closing.
  * No logger support (`SqfliteLoggerDatabaseFactory` wrappers are not
    wired in).
  * `queryCursor` / `rawQueryCursor` load the whole result set, no paging.
  * io only (`platforms: linux, macos, windows, android, ios`); no web.
    Calling on the web throws `UnsupportedError`.
  * After `close()`, any call fails with a `database_closed` error.
* For unit tests prefer `databaseFactoryFfi` from `sqflite_common_ffi` (see
  `sqflite-common-ffi-testing`) unless the test exercises `readTransaction`
  or concurrency behavior; then use `databaseFactoryFfiAsyncTest` with a
  file path and `deleteDatabase` in `setUp`.

## Examples

### Concurrent read during a long write transaction

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit;
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var factory = databaseFactoryFfiAsync;
  var db = await factory.openDatabase(
    'concurrent.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)',
      ),
    ),
  );

  var write = db.transaction((txn) async {
    await txn.insert('Item', {'name': 'slow'});
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await txn.insert('Item', {'name': 'write'});
  });
  // Runs on a reader connection while the write transaction is open.
  var count = await db.readTransaction((txn) async {
    var rows = await txn.rawQuery('SELECT COUNT(*) AS c FROM Item');
    return rows.first['c'] as int;
  });
  await write;
  print(count); // 0: the write transaction had not committed yet
  await db.close();
}
```

### Test with the dedicated test factory

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit;
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfiAsyncTest;
  const path = 'ffi_async_test.db';

  setUp(() => factory.deleteDatabase(path));

  test('version and insert', () async {
    var db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)'),
      ),
    );
    expect(await db.getVersion(), 1);
    expect(await db.insert('Test', {'id': 1}), 1);
    await db.close();
  });
}
```

### Selecting the factory per platform

```dart
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';

DatabaseFactory pickFactory() {
  sqfliteFfiInit();
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return databaseFactoryFfiAsync;
  }
  return databaseFactoryFfi;
}
```

## Common mistakes

* Writing inside `readTransaction`: throws. Use `transaction` for writes.
* Using `readTransaction` with `databaseFactoryFfi` or the `sqflite` plugin:
  not supported there.
* Expecting `singleInstance: true` semantics (same `Database` object for the
  same path): the async factory does not honor it.
* Forgetting `sqfliteFfiInit()` on Windows.
* Using it on the web: use `sqflite_common_ffi_web` instead.
* Depending only on `sqflite_common_ffi_async` and importing
  `sqflite_common_ffi/sqflite_ffi.dart` transitively; declare both.
