---
name: sqflite-open-database
description: >-
  Use when opening, creating, migrating, closing or deleting a SQLite database
  with package:sqflite in a Flutter app (Android, iOS, macOS): openDatabase,
  openReadOnlyDatabase, OpenDatabaseOptions, version, onConfigure, onCreate,
  onUpgrade, onDowngrade, onDatabaseDowngradeDelete, onOpen, getDatabasesPath,
  deleteDatabase, databaseExists, inMemoryDatabasePath, singleInstance,
  readOnly, databaseFactory, getVersion, setJournalMode (WAL), foreign keys,
  copying an asset database, and the "database is locked" pitfalls.
---

# sqflite: opening and migrating a database

`package:sqflite` is the Flutter plugin for SQLite on Android, iOS and macOS.
A database is a file identified by a path; a relative path is resolved against
`getDatabasesPath()`. `openDatabase` runs a small version-based migration
mechanism (`onCreate` / `onUpgrade` / `onDowngrade`) inside a transaction and
returns a `Database` that you keep open for the life of the app.

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> openAppDatabase() async {
  final path = join(await getDatabasesPath(), 'app.db');
  return openDatabase(
    path,
    version: 1,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE Todo (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, done INTEGER NOT NULL)',
      );
    },
  );
}
```

## Guidelines

### Imports and platforms

* `import 'package:sqflite/sqflite.dart';` gives the global functions
  (`openDatabase`, `openReadOnlyDatabase`, `getDatabasesPath`,
  `deleteDatabase`, `databaseExists`), the global `databaseFactory`, the
  `Sqflite` helper class and every type of `package:sqflite/sqlite_api.dart`
  (`Database`, `Transaction`, `Batch`, `DatabaseFactory`,
  `OpenDatabaseOptions`, `ConflictAlgorithm`, `DatabaseException`,
  `inMemoryDatabasePath`, ...).
* `sqflite` only works on Android, iOS and macOS. For Linux, Windows, the Dart
  VM and unit tests use `package:sqflite_common_ffi`; for the web use
  `package:sqflite_common_ffi_web`; both plug in through
  `databaseFactory = ...` and the code below stays unchanged. Code that must
  not depend on Flutter should import `package:sqflite_common/sqlite_api.dart`
  and receive a `DatabaseFactory`.
* Build paths with `join` from `package:path`, never with string
  concatenation. `getDatabasesPath()` is `data/data/<package>/databases` on
  Android and the Documents directory on iOS/macOS; on iOS the Library
  directory from `path_provider` (`getLibraryDirectory()`) is the recommended
  location instead.
* The plugin creates the parent directory of a read-write database on open.
  When you write the file yourself (asset copy) create the directory first
  with `Directory(dirname(path)).create(recursive: true)`.

### Versioning callbacks

* Pass `version` (an `int` > 0) to enable migrations. Callbacks run in this
  order: `onConfigure`, then exactly one of `onCreate` / `onUpgrade` /
  `onDowngrade`, then `onOpen`. Without `version` only `onConfigure` and
  `onOpen` run.
* `onCreate(db, version)` runs when the file does not exist. `onUpgrade(db,
  oldVersion, newVersion)` runs when the stored version is lower than
  `version` (and also instead of `onCreate`, with `oldVersion == 0`, when no
  `onCreate` is given). `onDowngrade` runs when the stored version is higher;
  pass `onDatabaseDowngradeDelete` to delete and recreate the database in that
  case, or `onDatabaseVersionChangeError` to fail.
* `onCreate`, `onUpgrade` and `onDowngrade` already run inside a transaction:
  use the `db` they receive directly (or `db.batch()` + `commit()`), never call
  `db.transaction()` inside them. The version is stored (`PRAGMA
  user_version`) when the callback completes without throwing.
* Write migrations as a chain: `if (oldVersion < 2) {...} if (oldVersion < 3)
  {...}` so any old version reaches the newest schema. Put schema statements
  in a `Batch`, one statement per `execute` (multi-statement strings separated
  by `;` are not supported).
* `onConfigure` is the place for `PRAGMA foreign_keys = ON`,
  `db.setJournalMode('WAL')` (extension `SqfliteDatabaseExt`, handles the
  Android quirk where `execute` fails), `PRAGMA auto_vacuum` (only when
  `await db.getVersion() == 0`, i.e. a new file) and, on Android,
  `db.androidSetLocale('fr-FR')` (extension `SqfliteDatabaseAndroidExt`).
  They must be re-applied at every open, which is why they belong there.
* `db.getVersion()` / `db.setVersion()` exist (extension
  `SqfliteDatabaseExecutorExt`) but do not drive migrations with them; use
  `version` and the callbacks.
* `openDatabase(path, options: OpenDatabaseOptions(...))` is equivalent to
  the named parameters; when `options` is given all other parameters are
  ignored. `DatabaseFactory.openDatabase` only takes `options`.

### Instances, closing, deleting

* Open the database once and keep the `Database`; store the `Future<Database>`
  (not the `Database`) in a field so concurrent callers share the same open
  call. Many apps never close it.
* `singleInstance: true` (default) returns the same `Database` for the same
  path; a second `openDatabase` on that path returns the existing instance and
  ignores its callbacks. It is forced to `false` for `inMemoryDatabasePath`
  (`':memory:'`). Opening the same file twice with `singleInstance: false`
  causes "database is locked" errors on Android.
* `rollbackActiveTransactionOnOpen` (`OpenDatabaseOptions`, default: true in
  debug, false in release) rolls back a transaction left open by a previous
  isolate/hot restart when `singleInstance` is true. Keep the default unless
  you deliberately use several isolates.
* `readOnly: true` (or `openReadOnlyDatabase(path)`) ignores every callback,
  never starts a transaction and fails on the first write. Use it for shipped
  asset databases.
* Delete with `deleteDatabase(path)`, never with `File(path).delete()`: it
  closes the open instance, handles the hot-restart state and removes the
  `-wal`, `-shm` and `-journal` side files.
* `databaseExists(path)` checks the file; `db.isOpen` tells if `close()` was
  called; `db.path` is the resolved absolute path.
* `databaseFactory.readDatabaseBytes(path)` / `writeDatabaseBytes(path,
  bytes)` copy a whole database file (backup, restore, asset import) in a way
  that also works with the ffi and web factories.
* `factory.sandbox(path: root)` (extension
  `SqfliteDatabaseFactorySandboxExtension`) returns a `DatabaseFactory` whose
  relative paths live under `root` and whose absolute paths must stay inside
  it. Use it to isolate tests or per-user data.

### Isolates and hot restart

* Use the database from the main isolate: native calls already run on a
  background thread and the transaction lock is not cross-isolate. If a
  background isolate (push notification, work manager) must read the database,
  open it there with `singleInstance: false` and do not close it.
* After changing the schema during development restart the app; a hot reload
  keeps the native connection open with the old schema.

## Examples

### Migration chain with batches and a downgrade policy

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const _version = 2;

void _createV1(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS Company');
  batch.execute(
    'CREATE TABLE Company (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
  );
}

void _upgradeV1ToV2(Batch batch) {
  batch.execute('ALTER TABLE Company ADD description TEXT');
  batch.execute('''CREATE TABLE Employee (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    companyId INTEGER,
    FOREIGN KEY (companyId) REFERENCES Company(id) ON DELETE CASCADE)''');
}

Future<Database> openCompanyDb() async {
  final path = join(await getDatabasesPath(), 'company.db');
  return openDatabase(
    path,
    version: _version,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      // Fresh install: build the latest schema through the same steps.
      final batch = db.batch();
      _createV1(batch);
      _upgradeV1ToV2(batch);
      await batch.commit();
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      final batch = db.batch();
      if (oldVersion < 2) {
        _upgradeV1ToV2(batch);
      }
      await batch.commit();
    },
    onDowngrade: onDatabaseDowngradeDelete,
  );
}
```

### One shared instance for the whole app

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Future<Database>? _db;

  /// Safe to call concurrently: the first call starts the open, others await it.
  Future<Database> get database => _db ??= _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'app.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.setJournalMode('WAL'),
      onCreate: (db, _) => db.execute(
        'CREATE TABLE Note (id INTEGER PRIMARY KEY, content TEXT)',
      ),
    );
  }

  Future<void> close() async {
    final db = await _db;
    _db = null;
    await db?.close();
  }
}
```

### Copy a bundled asset database on first launch

```dart
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> openAssetDatabase() async {
  final path = join(await getDatabasesPath(), 'catalog.db');
  if (!await databaseExists(path)) {
    await Directory(dirname(path)).create(recursive: true);
    final data = await rootBundle.load(url.join('assets', 'catalog.db'));
    await databaseFactory.writeDatabaseBytes(
      path,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
  // Shipped data: open read-only, no callbacks run.
  return openReadOnlyDatabase(path);
}
```

### Delete and recreate, in-memory database

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<void> resetDatabase() async {
  final path = join(await getDatabasesPath(), 'app.db');
  await deleteDatabase(path); // also closes the open instance
}

Future<Database> openScratchDb() =>
    openDatabase(inMemoryDatabasePath); // singleInstance is forced to false
```

### Opening through an explicit factory

```dart
import 'package:sqflite/sqflite.dart';

/// Works with databaseFactory (sqflite), databaseFactoryFfi, databaseFactoryFfiWeb...
Future<Database> openWith(DatabaseFactory factory, String path) {
  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) =>
          db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)'),
    ),
  );
}
```

## Common mistakes

* Calling `db.transaction()` inside `onCreate` / `onUpgrade`: they are already
  in a transaction, use `db` directly or a batch.
* Creating two tables in one `execute` string. One statement per call.
* Forgetting to bump `version` after changing `onCreate`; existing installs
  never see the new schema. Handle it in `onUpgrade` too.
* Deleting the file with `dart:io` instead of `deleteDatabase`, then wondering
  why `onCreate` does not run after a hot restart.
* Opening the database in every widget/repository call with `singleInstance:
  false`, leading to `database is locked (code 5)`.
* Putting `PRAGMA foreign_keys` / `setJournalMode` in `onCreate`: they are per
  connection and must go in `onConfigure`.
* Calling `openDatabase` on Linux/Windows/web without first setting
  `databaseFactory` from `sqflite_common_ffi` / `sqflite_common_ffi_web`
  (`StateError: databaseFactory not initialized`).

## More

Queries, transactions and batches: see the `sqflite-crud-and-transactions`
skill. Unit tests, desktop/web factories and logging: see the
`sqflite-testing-and-platforms` skill.
