---
name: sqflite-common-ffi-desktop
description: >-
  Use when running sqflite on Windows, Linux or macOS (Dart VM, CLI, server or
  Flutter desktop) with package:sqflite_common_ffi: sqfliteFfiInit,
  databaseFactoryFfi, databaseFactoryFfiNoIsolate, createDatabaseFactoryFfi
  (ffiInit, noIsolate, isolatePortServer, SqfliteFfiIsolatePortServer),
  setting the global databaseFactory so openDatabase works on desktop,
  inMemoryDatabasePath, database paths and getDatabasesPath, the sqflite
  background isolate, the sqlite3 native library and build hooks (system
  library, SQLCipher, sqlite3mc), custom "PRAGMA sqflite" statements, and
  which companion package to use on the web (sqflite_common_ffi_web) or in a
  Flutter app (sqflite_ffi).
---

# sqflite_common_ffi: sqflite on desktop and the Dart VM

`package:sqflite_common_ffi` is a `DatabaseFactory` implementation of the
sqflite API built on `package:sqlite3` (dart:ffi). It runs SQLite in a
background isolate and works on Linux, macOS and Windows, on the Dart VM and in
Flutter (also on iOS/Android through `sqlite3` build hooks). It is the only way
to use sqflite in a pure Dart program and the standard way to unit test sqflite
code (see the `sqflite-common-ffi-testing` skill).

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit(); // Windows setup, no-op elsewhere
  var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT)');
  await db.insert('Product', {'title': 'Product 1'});
  print(await db.query('Product')); // [{id: 1, title: Product 1}]
  await db.close();
}
```

The `Database`, `Transaction`, `Batch` and `OpenDatabaseOptions` API is the
sqflite one and is documented by the `sqflite` / `sqflite_common` package
skills (`sqflite-open-database`, `sqflite-crud-and-transactions`,
`sqflite-common-api`). This skill only covers the ffi factory.

## Guidelines

### Dependency and import

* Add `sqflite_common_ffi: ^2.4.2` to `dependencies` (or `dev_dependencies`
  when it is only used by tests). It requires Dart 3.12 and `sqlite3 >= 3`.
* Import `package:sqflite_common_ffi/sqflite_ffi.dart`. It re-exports
  `package:sqflite_common/sqflite.dart`, so `Database`, `DatabaseFactory`,
  `OpenDatabaseOptions`, `inMemoryDatabasePath`, `DatabaseException`, the
  global `databaseFactory` setter and the global `openDatabase()` /
  `deleteDatabase()` functions are all available from this single import.
* In a pure Dart project never import `package:sqflite/sqflite.dart` (Flutter
  only). In a Flutter project either import works; prefer `sqflite_common_ffi`
  in code shared with tests.
* Public API of the package: `sqfliteFfiInit`, `databaseFactoryFfi`,
  `databaseFactoryFfiNoIsolate`, `createDatabaseFactoryFfi`, the `SqfliteFfiInit`
  typedef (`void Function()`) and `SqfliteFfiIsolatePortServer`. Nothing under
  `src/` is meant to be imported.

### Initialization

* Call `sqfliteFfiInit()` once in `main()` (or `setUpAll`) before the first
  database call. It only does Windows-specific work (loads the library in the
  main isolate by opening and closing an in-memory database) and is a no-op on
  other platforms and on the web, so it is safe to call unconditionally.
* `databaseFactoryFfi` is a global `DatabaseFactory` (tag `ffi`). Every call
  is sent to one background `SqfliteIsolate` spawned lazily on first use and
  shared by all ffi factories of the current Dart isolate.
* `databaseFactoryFfiNoIsolate` runs SQLite synchronously in the calling
  isolate. Use it inside a background isolate you already own
  (`Isolate.run`, `compute`) or in Flutter widget tests. In the main isolate of
  a UI app a long query blocks the UI. It throws `UnimplementedError` on the
  web.
* `createDatabaseFactoryFfi({SqfliteFfiInit? ffiInit, bool noIsolate = false,
  SqfliteFfiIsolatePortServer? isolatePortServer})` builds a custom factory:
  * `ffiInit` is a top-level or static `void Function()` executed inside the
    sqflite isolate before the first SQLite call (with `noIsolate: true`, in
    the current isolate at the first call). Use it for extra native setup;
    the library itself is selected by `sqlite3` build hooks, see below.
  * `isolatePortServer` shares the sqflite isolate `SendPort` between Dart
    isolates (`lookupPort()`, `registerPort(SendPort)`, `unregisterPort()`).
    In Flutter use the `sqflite_ffi` package, which implements it with
    `IsolateNameServer`; implement it yourself only for a custom registry.
* Setting the global factory: `databaseFactory = databaseFactoryFfi;` once,
  before any global `openDatabase()`. Only needed for code (yours or third
  party) that uses the global `openDatabase` / `deleteDatabase` functions.
  Reading `databaseFactory` before it is set throws `StateError`; setting it a
  second time prints a warning. Prefer passing a `DatabaseFactory` to your
  own classes so tests can inject any factory.
* Flutter app targeting desktop: set the factory on Windows/Linux (see
  example) or simply depend on `sqflite_ffi`, a Dart-only plugin that
  registers the ffi factory automatically and shares the isolate between
  Flutter isolates.

### Paths

* `inMemoryDatabasePath` (`:memory:`) opens a private in-memory database.
  After `close()` the data is gone.
* A relative path is joined with `getDatabasesPath()`, which for ffi is
  `<current directory>/.dart_tool/sqflite_common_ffi/databases`. This is fine
  for scripts and tests, not for an installed application: build an absolute
  path yourself (`path_provider` `getApplicationSupportDirectory()` in
  Flutter, or a directory you control) and join it with `package:path`.
* The parent directory of the database file is created on open when the file
  does not exist. `file:` URIs are passed through to SQLite (`uri: true`).
* `readOnly: true` on a missing file throws instead of creating it.
* `deleteDatabase(path)` closes the single instance and removes the file and
  its journal files. `databaseExists(path)` checks the file.
  `readDatabaseBytes(path)` / `writeDatabaseBytes(path, bytes)` on the
  factory export or import a whole database file.

### Native SQLite library (sqlite3 v3, build hooks)

* `sqflite_common_ffi >= 2.4` uses `sqlite3 >= 3`, which downloads and
  bundles SQLite with Dart build hooks: no `libsqlite3-dev` on Linux, no
  `sqlite3.dll` to copy on Windows.
* Hooks run with `dart run <file>` / `dart test` / `flutter run` / `flutter
  build`, not with `dart <file>`. Run from the command line at least once so
  the library is built (IDE launchers may skip hooks). Run `flutter clean`
  after changing the `sqlite3` major version.
* The library is chosen in `pubspec.yaml`, not in Dart code:

  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: system   # sqlite3 (default, bundled), sqlcipher, sqlite3mc, system, process, executable
  ```

  `source: sqlcipher` or `source: sqlite3mc` give encryption: send
  `PRAGMA key = '...'` as the first statement in `onConfigure`.
* `package:sqlite3/open.dart` (`open.overrideFor`) belongs to `sqlite3` v2 and
  no longer exists; do not write `ffiInit` functions that use it. To stay on
  v2 pin `sqflite_common_ffi: ^2.3.7` with `sqlite3: ^2.9.4` (see
  [references/native-library.md](references/native-library.md)).

### Behavior notes

* Exceptions are `DatabaseException` (from `sqflite_common`): use
  `isNoSuchTableError()`, `isUniqueConstraintError()`, `isSyntaxError()`,
  `isDatabaseClosedError()`, `getResultCode()` rather than parsing messages.
* SQLite defensive mode is on by default. `PRAGMA writable_schema = ON` only
  works after `await db.execute('PRAGMA sqflite -- db_config_defensive_off')`
  (constant `sqflitePragmaDbDefensiveOff` in
  `package:sqflite_common/utils/utils.dart`).
* Each Dart isolate has its own sqflite isolate and connections, so
  `singleInstance` does not span Dart isolates unless an
  `isolatePortServer` is used (`sqflite_ffi` in Flutter). When two isolates
  open the same file, pass `rollbackActiveTransactionOnOpen: false` in
  `OpenDatabaseOptions` so one isolate does not roll back the other's
  transaction on open.
* `singleInstance: false` (multi-instance) is simulated, keep the default.
* Web: `databaseFactoryFfi` throws `UnsupportedError`; use
  `databaseFactoryFfiWeb` from `sqflite_common_ffi_web` (needs `sqlite3.wasm`
  and a worker file in `web/`). For a `readTransaction` / concurrent-read
  variant on desktop see `sqflite_common_ffi_async`.

## Examples

### Dart CLI application with a persistent database

```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var factory = databaseFactoryFfi;

  // Absolute path you control; the parent directory is created on open.
  var path = p.join(Directory.current.path, 'data', 'app.db');
  var db = await factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT)',
        );
      },
    ),
  );
  await db.insert('Product', {'title': 'Product ${DateTime.now()}'});
  for (var row in await db.query('Product')) {
    print(row);
  }
  await db.close();
}
```

### Flutter app: use ffi on Windows and Linux, the sqflite plugin elsewhere

```dart
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    // Global openDatabase() now works on desktop.
    databaseFactory = databaseFactoryFfi;
  }
  // iOS/Android/macOS keep the native sqflite plugin factory.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

For an app that should use ffi on every platform, depend on `sqflite_ffi`
instead of doing this by hand.

### Injecting the factory instead of using the global one

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProductStore {
  ProductStore(this.factory, this.path);
  final DatabaseFactory factory;
  final String path;
  Database? _db;

  Future<Database> get db async => _db ??= await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute(
            'CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT)',
          ),
        ),
      );

  Future<int> add(String title) async =>
      (await db).insert('Product', {'title': title});

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

Future<void> main() async {
  sqfliteFfiInit();
  var store = ProductStore(databaseFactoryFfi, 'products.db');
  await store.add('Pen');
  await store.close();
}
```

### Database work inside a background isolate (no extra sqflite isolate)

```dart
import 'dart:isolate';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<int> countRows(String path) => Isolate.run(() async {
      // Already in a background isolate: run SQLite synchronously here.
      var db = await databaseFactoryFfiNoIsolate.openDatabase(path);
      try {
        var rows = await db.rawQuery('SELECT COUNT(*) AS c FROM Product');
        return rows.first['c'] as int;
      } finally {
        await db.close();
      }
    });
```

### Custom factory with an ffiInit hook

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Must be top-level or static: it is sent to the sqflite isolate.
void _ffiInit() {
  // Runs in the sqflite isolate before any SQLite call.
}

final databaseFactoryCustom = createDatabaseFactoryFfi(ffiInit: _ffiInit);
```

### Encrypted database (SQLCipher build selected in pubspec.yaml)

```yaml
# pubspec.yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlcipher
```

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openEncrypted(String path, String key) =>
    databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          // First statement on the connection.
          await db.rawQuery("PRAGMA key = '$key'");
        },
        onCreate: (db, _) => db.execute('CREATE TABLE t (i INTEGER)'),
      ),
    );
```

### Editing sqlite_master (defensive mode off)

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> renameTypeInSchema(Database db) async {
  await db.execute('PRAGMA sqflite -- db_config_defensive_off');
  await db.execute('PRAGMA writable_schema = ON');
  await db.update(
    'sqlite_master',
    {'sql': 'CREATE TABLE Test(value BLOB)'},
    where: "name = 'Test' AND type = 'table'",
  );
}
```

## Common mistakes

* Using `databaseFactoryFfi` on the web (throws `UnsupportedError`). Use
  `sqflite_common_ffi_web`.
* Calling the global `openDatabase()` without `databaseFactory =
  databaseFactoryFfi;` first: `StateError: databaseFactory not initialized`.
* Passing a relative path in an installed app: it lands in
  `.dart_tool/sqflite_common_ffi/databases` under the current directory.
* Running `dart bin/main.dart` and getting a "failed to load dynamic library"
  error: use `dart run bin/main.dart` so build hooks run.
* Writing an `ffiInit` with `package:sqlite3/open.dart` (v2 API). Select the
  library with `hooks.user_defines.sqlite3` in `pubspec.yaml`.
* Passing a closure or instance method as `ffiInit`: it must be top-level or
  static to cross the isolate boundary.
* Expecting `singleInstance` to be shared across Dart isolates. Use
  `sqflite_ffi` (Flutter) or a `SqfliteFfiIsolatePortServer`.
* Importing `package:sqflite/sqflite.dart` in a Dart VM program.

## More

See [references/native-library.md](references/native-library.md) for the
`sqlite3` hook options, the legacy `sqlite3` v2 setup (Linux `libsqlite3-dev`,
Windows dll, `open.overrideFor`), CI notes and troubleshooting.
