---
name: sqflite-open-database
description: >-
  Use when getting started with package:sqflite or opening, creating,
  migrating, closing or deleting a SQLite database in a Flutter app: which
  package and factory per platform (sqflite on Android/iOS/macOS,
  sqflite_common_ffi on Windows/Linux, sqflite_common_ffi_web on the web, one
  code base for mobile + desktop + web), where the database file is
  (getDatabasesPath per platform, path_provider), openDatabase,
  openReadOnlyDatabase, OpenDatabaseOptions, version, onConfigure, onCreate,
  onUpgrade, onDowngrade, onDatabaseDowngradeDelete, onOpen, deleteDatabase,
  databaseExists, inMemoryDatabasePath, singleInstance, readOnly,
  databaseFactory, getVersion, setJournalMode (WAL), foreign keys, copying an
  asset database, and the common pitfalls (opening many times, not awaiting,
  schema change without version bump, "database is locked").
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

### Which package for which platform

| Platform | Package | Factory | SQLite library |
|---|---|---|---|
| Android, iOS, macOS | `sqflite` | set by the plugin, nothing to do | the OS one (version depends on the OS) |
| Windows, Linux (and macOS without the plugin) | `sqflite_common_ffi` (or `sqflite_ffi` in Flutter, auto registered) | `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` | bundled by `package:sqlite3` build hooks, nothing to install |
| Web | `sqflite_common_ffi_web` | `databaseFactory = databaseFactoryFfiWeb;` | `sqlite3.wasm` + `sqflite_sw.js` in `web/`, created by `dart run sqflite_common_ffi_web:setup` |
| `flutter test`, Dart VM | `sqflite_common_ffi` (dev dependency) | `databaseFactoryFfi` (`databaseFactoryFfiNoIsolate` in `testWidgets`) | bundled |

* The global `openDatabase()` uses the global `databaseFactory`. Set it once
  in `main()`, before any open, on every platform but Android/iOS/macOS;
  otherwise `openDatabase` throws `Bad state: databaseFactory not
  initialized` (also in `flutter test`).
* One Flutter code base for mobile + desktop + web (dependencies `sqflite`,
  `sqflite_common_ffi`, `sqflite_common_ffi_web`, `path_provider`, `path`):

  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:flutter/widgets.dart';
  import 'package:path/path.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:sqflite/sqflite.dart';
  import 'package:sqflite_common_ffi/sqflite_ffi.dart'
      show databaseFactoryFfi, sqfliteFfiInit;
  import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
      // Requires `dart run sqflite_common_ffi_web:setup` (files in web/).
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      // The ffi default folder is relative to the current directory.
      var dir = await getApplicationSupportDirectory();
      await databaseFactory.setDatabasesPath(join(dir.path, 'databases'));
    }
    // Android, iOS and macOS: the sqflite plugin factory is already set.
    runApp(const SizedBox());
  }
  ```

  Check `kIsWeb` first: `dart:io` `Platform` throws on the web. With
  `sqflite_ffi` instead of `sqflite_common_ffi`, Windows/Linux need no code.

### Where the database is

* A relative path is resolved against `getDatabasesPath()`:
  * `sqflite` Android: `/data/data/<package>/databases`;
  * `sqflite` iOS/macOS: the Documents directory (`path_provider`
    `getLibraryDirectory()` is a better choice on iOS, not user visible);
  * `sqflite_common_ffi`: `.dart_tool/sqflite_common_ffi/databases` in the
    current directory, fine for tests only: in a desktop app use
    `getApplicationSupportDirectory()` (absolute path or
    `databaseFactory.setDatabasesPath(...)` in `main()`);
  * `sqflite_common_ffi_web`: `/`, a path is only a name (`'app.db'`), no
    `path_provider`, no `dart:io`.
* `openDatabase('app.db', ...)` (relative name) therefore works on every
  platform once the factory and the databases path are set.

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
  concatenation (see "Where the database is" above).
* The plugin (and ffi) creates the parent directory of a read-write database
  on open.
  When you write the file yourself (asset copy) create the directory first
  with `Directory(dirname(path)).create(recursive: true)`.

### Versioning callbacks

* Pass `version` (an `int` > 0) to enable migrations. Callbacks run in this
  order: `onConfigure`, then exactly one of `onCreate` / `onUpgrade` /
  `onDowngrade`, then `onOpen`. Without `version` only `onConfigure` and
  `onOpen` run.
* `onCreate(db, version)` runs when the file does not exist (never again:
  editing `onCreate` alone does not change existing databases, bump
  `version` and handle it in `onUpgrade`). `onUpgrade(db,
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
  ignores its callbacks, and `close()` closes it for every holder. This also
  applies to `inMemoryDatabasePath` (`':memory:'`): while open, a second open
  returns the same in-memory database (same tables and rows); after
  `close()`, the next open is a new empty database; `singleInstance: false`
  gives a private in-memory database at each open. Opening the same file
  twice with `singleInstance: false` causes "database is locked" errors on
  Android and throws `ArgumentError` on the web.
* `rollbackActiveTransactionOnOpen` (`OpenDatabaseOptions`, default: true in
  debug, false in release) rolls back a transaction left open by a previous
  isolate/hot restart when `singleInstance` is true. Keep the default unless
  you deliberately use several isolates.
* `readOnly: true` (or `openReadOnlyDatabase(path)`): the file must exist
  and any write fails (`isReadOnlyError()`). `onConfigure` and `onOpen` still
  run. Do not pass `version`: if it differs from the file version the
  migration callback runs and saving the version fails, so the open fails.
  Use it for shipped asset databases.
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
  background thread and the transaction lock is not cross-isolate. In an
  isolate you spawn (`Isolate.run`, `compute`), call
  `BackgroundIsolateBinaryMessenger.ensureInitialized(token)` first
  (`RootIsolateToken.instance!` read in the main isolate) or `openDatabase`
  throws `databaseFactory not initialized`; open with
  `OpenDatabaseOptions(rollbackActiveTransactionOnOpen: false)` and do not
  close the database there (the native database is shared).
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
  // Shipped data: open read-only, no version.
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

/// Shared while open: a second openDatabase(inMemoryDatabasePath) returns it.
Future<Database> openScratchDb() => openDatabase(inMemoryDatabasePath);

/// A new private in-memory database at each call.
Future<Database> openPrivateScratchDb() =>
    openDatabase(inMemoryDatabasePath, singleInstance: false);
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

* Opening the database in each widget/function instead of once.
* Not awaiting a call in `onCreate` / `onUpgrade`: `openDatabase` succeeds,
  the version is saved with a partial schema and the error is uncaught.
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
* Forgetting `dart run sqflite_common_ffi_web:setup` on the web (the first
  call fails, "An error occurred while initializing the web worker").
* Using `getDatabasesPath()` of ffi (`.dart_tool/...`) in an installed
  desktop app, or `path_provider` / `dart:io` on the web.
* Expecting `inMemoryDatabasePath` to give a fresh database while a previous
  one is still open (single instance).

## More

Queries, transactions and batches: see the `sqflite-crud-and-transactions`
skill. Unit tests, desktop/web factories and logging: see the
`sqflite-testing-and-platforms` skill.
