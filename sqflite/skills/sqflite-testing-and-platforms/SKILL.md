---
name: sqflite-testing-and-platforms
description: >-
  Use when unit testing or widget testing code that uses package:sqflite,
  running it on Linux/Windows/Dart VM (sqflite_common_ffi: sqfliteFfiInit,
  databaseFactoryFfi, databaseFactoryFfiNoIsolate) or on the web
  (sqflite_common_ffi_web: databaseFactoryFfiWeb), swapping the global
  databaseFactory, and debugging SQL: SqfliteDatabaseFactoryLogger,
  debugQuickLoggerWrapper, Sqflite.setDebugModeOn, setLogLevel,
  setLockWarningInfo, "database has been locked", MissingPluginException,
  isolates, Android WAL manifest, iOS unprotected folder, encryption.
---

# sqflite: tests, other platforms and debugging

The `sqflite` plugin itself only runs on an Android, iOS or macOS device or
simulator: `flutter test` has no native SQLite, so `openDatabase` throws
`MissingPluginException`. Every sqflite API is routed through the global
`databaseFactory`; point it at another implementation and the rest of the
code (`openDatabase`, `Database`, `Transaction`, `Batch`) is unchanged.

```dart
// test/db_test.dart
import 'package:flutter_test/flutter_test.dart';
// Re-exports openDatabase, databaseFactory, Database... from sqflite_common.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('create and read', () async {
    final db = await openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT)');
    await db.insert('Product', {'title': 'Product 1'});
    expect(await db.query('Product'), [
      {'id': 1, 'title': 'Product 1'},
    ]);
    await db.close();
  });
}
```

## Guidelines

### Which factory where

* `sqflite` (Android/iOS/macOS): nothing to do, the plugin registers
  `databaseFactory` at startup (`databaseFactorySqflitePlugin`).
* Linux, Windows, Dart VM, `flutter test`, `dart test`: add
  `sqflite_common_ffi` (as a `dev_dependency` when only tests need it), call
  `sqfliteFfiInit()` once, then `databaseFactory = databaseFactoryFfi`. It
  uses its own SQLite (`package:sqlite3`), usually newer than the device
  one; run integration tests on a device for version-specific SQL.
* Widget tests (`testWidgets`): use `databaseFactoryFfiNoIsolate` instead of
  `databaseFactoryFfi`; the isolate-based factory hangs in the test binding.
* `package:sqflite_common_ffi/sqflite_ffi.dart` re-exports the whole
  `package:sqflite_common/sqflite.dart` API (`openDatabase`,
  `databaseFactory`, `Database`, `inMemoryDatabasePath`, ...), so a test
  that imports it does not need `package:sqflite/sqflite.dart` as well (the
  analyzer flags it as `unnecessary_import`); import `sqflite.dart` only for
  the `Sqflite` helper class or the Android/Darwin extensions.
* Web: add `sqflite_common_ffi_web`, set `databaseFactory =
  databaseFactoryFfiWeb` (setup of the worker/wasm binaries is described in
  that package's own skill/README).
* One `main()` can select the factory at runtime: `kIsWeb` first, then
  `Platform.isWindows || Platform.isLinux`, otherwise leave the sqflite
  default. Set `databaseFactory` once, before any `openDatabase`, and before
  `runApp`. Setting it twice prints a warning.
* `databaseFactory` throws `StateError('databaseFactory not initialized')`
  when read before an implementation registered; `databaseFactoryOrNull` is
  the nullable getter.
* Encryption: `sqflite_sqlcipher` on Android/iOS/macOS (same API, shares
  `sqflite_common`); on desktop see the `sqflite_common_ffi` documentation.

### Writing testable code

* Do not call the global `openDatabase` from your repositories. Inject a
  `DatabaseFactory` (or an already open `Database`) and open with
  `factory.openDatabase(path, options: OpenDatabaseOptions(...))`. Tests pass
  `databaseFactoryFfi`, the app passes `databaseFactory`.
* Use `inMemoryDatabasePath` for fast, isolated tests (no file, no
  single-instance sharing). To test file behaviour use a temp directory and
  `factory.deleteDatabase(path)` in `setUp`.
* `factory.sandbox(path: dir)` returns a factory confined to `dir`, handy to
  keep a test's databases apart from the app's.
* Run migration tests by opening at `version: 1`, closing, then reopening at
  `version: 2` on the same path and asserting the schema
  (`PRAGMA table_info(...)` or `sqlite_master`).
* `package:sqflite/sqflite_dev.dart` exposes `setMockDatabaseFactory(factory)`
  (test only) and `sqfliteDatabaseFactoryDefault`; prefer assigning
  `databaseFactory` directly.

### Debugging SQL

* Wrap any factory with `SqfliteDatabaseFactoryLogger` (annotated
  `@experimental`, the analyzer reports `experimental_member_use`) from
  `package:sqflite_common/sqflite_logger.dart` to see every statement, its
  arguments, result and duration: `databaseFactory =
  SqfliteDatabaseFactoryLogger(databaseFactory, options:
  SqfliteLoggerOptions(type: SqfliteDatabaseFactoryLoggerType.all, log:
  (event) {...}))`. Events are `SqfliteLoggerSqlEvent` (`sql`, `arguments`,
  `result`, `error`, `sw`), `SqfliteLoggerBatchEvent` (`operations`),
  `SqfliteLoggerDatabaseOpenEvent`, `...CloseEvent`, `...DeleteEvent`,
  `SqfliteLoggerInvokeEvent`. `event.dump()` prints the event (default
  `log`).
* `databaseFactory = databaseFactory.debugQuickLoggerWrapper()` is the
  one-liner form (deprecated on purpose so it is not left in production).
* Native-side logs: `await databaseFactory.debugSetLogLevel(
  sqfliteLogLevelVerbose)` (extension `SqfliteDatabaseFactoryDebug`,
  deprecated on purpose) before opening; levels `sqfliteLogLevelNone`,
  `sqfliteLogLevelSql`, `sqfliteLogLevelVerbose`. `Sqflite.setDebugModeOn()`
  / `Sqflite.devSetDebugModeOn()` are the older deprecated equivalents.
* `Sqflite.setLockWarningInfo(duration:, callback:)` changes the 10 s
  "Warning database has been locked" watchdog. That warning almost always
  means a call on `db` inside `db.transaction((txn) ...)`.
* Print `await db.query('sqlite_master')` to dump the schema, and
  `SELECT sqlite_version()` to know which SQL features exist on the device.

### Platform notes

* `MissingPluginException` on device: stop and rebuild the app (hot
  restart does not register a newly added plugin), `flutter clean`, on iOS
  `pod install`. In an FCM background handler, register plugins early.
* Android: WAL is off by default. Enable it with `<meta-data
  android:name="com.tekartik.sqflite.wal_enabled" android:value="true"/>` in
  the `<application>` manifest element, or portably with
  `db.setJournalMode('WAL')` in `onConfigure`. Read-only opens do not
  delete a corrupt file; read-write opens follow Android's default handler
  (the file is removed).
* iOS background isolate while the device is locked: create the database in
  a folder created by `SqfliteDarwin.createUnprotectedFolder(parent, name)`
  (data protection `NSFileProtectionNone`).
* Isolates: use the main isolate. A second isolate must open with
  `singleInstance: false` and must not close the database.
* Rows are limited to about 1 MB on Android/iOS cursors; big blobs belong in
  files.

## Examples

### Repository that takes a factory, tested with ffi

```dart
// lib/todo_repository.dart
import 'package:sqflite/sqflite.dart';

class TodoRepository {
  TodoRepository(this.factory, this.path);

  final DatabaseFactory factory;
  final String path;
  Future<Database>? _db;

  Future<Database> get db => _db ??= factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute(
            'CREATE TABLE Todo (id INTEGER PRIMARY KEY, title TEXT NOT NULL)',
          ),
        ),
      );

  Future<int> add(String title) async =>
      (await db).insert('Todo', {'title': title});

  Future<List<String>> titles() async => (await (await db).query('Todo', orderBy: 'id'))
      .map((row) => row['title'] as String)
      .toList();

  Future<void> close() async {
    await (await db).close();
    _db = null;
  }
}
```

```dart
// test/todo_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_app/todo_repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('add and list', () async {
    final repo = TodoRepository(databaseFactoryFfi, inMemoryDatabasePath);
    await repo.add('a');
    await repo.add('b');
    expect(await repo.titles(), ['a', 'b']);
    await repo.close();
  });
}
```

### Widget test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  // No isolate inside the widget test binding.
  databaseFactory = databaseFactoryFfiNoIsolate;

  testWidgets('database in a widget test', (tester) async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, _) =>
          db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)'),
    );
    await db.insert('Test', {'value': 'v'});
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'v'},
    ]);
    await db.close();
  });
}
```

### Selecting the factory per platform in main()

```dart
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
// sqflite_ffi.dart already exports databaseFactory; the sqflite plugin
// registers itself on Android/iOS/macOS without any import.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android, iOS, macOS keep the sqflite plugin factory.
  runApp(const SizedBox());
}
```

### Logging every statement

```dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqflite_logger.dart';

void enableSqlLogs() {
  // ignore: experimental_member_use
  databaseFactory = SqfliteDatabaseFactoryLogger(
    databaseFactory,
    options: SqfliteLoggerOptions(
      type: SqfliteDatabaseFactoryLoggerType.all,
      log: (event) {
        if (event is SqfliteLoggerSqlEvent) {
          print('sql: ${event.sql} ${event.arguments ?? ''} '
              '${event.error ?? ''} ${event.sw?.elapsed ?? ''}');
        } else if (event is SqfliteLoggerBatchEvent) {
          for (final op in event.operations) {
            print('batch: ${op.sql} ${op.arguments ?? ''}');
          }
        } else {
          event.dump();
        }
      },
    ),
  );
}
```

### Migration test on a file database

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  test('v1 to v2 adds a column', () async {
    final dir = await Directory.systemTemp.createTemp('sqflite_test');
    final path = join(dir.path, 'm.db');
    await factory.deleteDatabase(path);

    var db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('CREATE TABLE T (id INTEGER PRIMARY KEY)'),
      ),
    );
    await db.close();

    db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onUpgrade: (db, old, _) async {
          if (old < 2) await db.execute('ALTER TABLE T ADD name TEXT');
        },
      ),
    );
    final columns = (await db.rawQuery('PRAGMA table_info(T)'))
        .map((row) => row['name'])
        .toList();
    expect(columns, ['id', 'name']);
    expect(await db.getVersion(), 2);
    await db.close();
  });
}
```

## Common mistakes

* Running `flutter test` against the plugin factory and getting
  `MissingPluginException`: set `databaseFactory = databaseFactoryFfi`.
* Forgetting `sqfliteFfiInit()` before using `databaseFactoryFfi` on Windows
  or Linux.
* Using `databaseFactoryFfi` (isolate) in `testWidgets`; use
  `databaseFactoryFfiNoIsolate`.
* Setting `databaseFactory` after some code already opened a database, or
  in a library rather than in the app's `main()`.
* Leaving `debugQuickLoggerWrapper()` / `debugSetLogLevel` in production
  code; they are deprecated so the analyzer flags them.
* Reusing an in-memory path between tests and expecting shared state: each
  `openDatabase(inMemoryDatabasePath)` is a new empty database.

## More

Opening and migrations: `sqflite-open-database` skill. Queries and
transactions: `sqflite-crud-and-transactions` skill. Pure-Dart API for shared
packages: the `sqflite_common` package skill. Desktop and web factories: the
`sqflite_common_ffi` and `sqflite_common_ffi_web` package skills.
