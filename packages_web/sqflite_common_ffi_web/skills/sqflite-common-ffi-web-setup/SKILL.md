---
name: sqflite-common-ffi-web-setup
description: >-
  Use when adding sqflite support to a web app (Flutter web or Dart web) with
  package:sqflite_common_ffi_web: running dart run sqflite_common_ffi_web:setup
  to install sqlite3.wasm and sqflite_sw.js under web/, databaseFactoryFfiWeb,
  databaseFactoryFfiWebNoWebWorker, setting the global databaseFactory behind
  kIsWeb, database names and IndexedDB persistence, shared worker vs basic
  worker, importing a database with writeDatabaseBytes, limitations and
  troubleshooting (missing worker file, port-bound storage, deleteDatabase).
---

# sqflite_common_ffi_web: sqflite in the browser

`package:sqflite_common_ffi_web` implements the sqflite `DatabaseFactory` on
the web with `package:sqlite3` compiled to WebAssembly. Databases persist in
IndexedDB and SQLite runs in a shared worker (one instance for all tabs). It
needs two binary files served next to the app: `sqlite3.wasm` and the worker
script `sqflite_sw.js`, both produced by the package `setup` command.

```bash
dart pub add sqflite_common_ffi_web
dart run sqflite_common_ffi_web:setup   # creates web/sqlite3.wasm and web/sqflite_sw.js
```

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  Database db = await databaseFactoryFfiWeb.openDatabase('my_db.db');
  await db.execute('CREATE TABLE IF NOT EXISTS Test (id INTEGER PRIMARY KEY, value TEXT)');
  await db.insert('Test', {'value': 'hello'});
  print(await db.query('Test'));
  await db.close();
}
```

## Guidelines

### Dependency, binaries and import

* Add `sqflite_common_ffi_web` (currently 1.1.x, Dart 3.12, `platforms: web`
  only) to `dependencies`. It depends on `sqflite_common_ffi` and
  `sqflite_common`.
* Run `dart run sqflite_common_ffi_web:setup` in the project directory after
  adding the dependency and after every upgrade of the package or of
  `sqlite3`. It builds the shared worker with `webdev` (into
  `.dart_tool/sqflite_common_ffi_web/setup/<version>/`) and writes
  `web/sqflite_sw.js` plus `web/sqlite3.wasm` (downloaded from the
  `sqlite3.dart` GitHub releases, version pinned by the package).
  Options: `--force` (`-f`) rebuild, `--dir <dir>` output directory
  (default `web`), `--verbose`, `--no-sqlite3-wasm` (skip the wasm
  download), `--sqlite3-wasm-url <url>`, and an optional project path
  argument. Commit the two files or add them to `.gitignore` and run setup in
  CI; either way they must be present in the deployed site root.
* The same setup is callable from Dart: `setupSqfliteWebBinaries(options:
  SqfliteWebSetupOptions(...))` from `package:sqflite_common_ffi_web/setup.dart`
  (`path`, `dir`, `force`, `verbose`, `sqlite3WasmUri`, `noSqlite3Wasm`,
  `sqlite3WasmFilename`, `sqfliteWebWorkerFilename`). io only.
* Import `package:sqflite_common_ffi_web/sqflite_ffi_web.dart`. It exports
  only the web factories and options (`databaseFactoryFfiWeb`,
  `databaseFactoryFfiWebNoWebWorker`, `databaseFactoryFfiWebBasicWebWorker`,
  `createDatabaseFactoryFfiWeb`, `SqfliteFfiWebOptions`,
  `SqfliteFfiWebContext`, `sqfliteFfiWebLoadSqlite3Wasm`,
  `sqfliteFfiWebStartSharedWorker`, `sqliteFfiWebDebugWebWorker`). The
  `Database` / `DatabaseFactory` types come from
  `package:sqflite_common/sqlite_api.dart` (Dart web),
  `package:sqflite_common_ffi/sqflite_ffi.dart` or `package:sqflite/sqflite.dart`
  (Flutter), so import one of them too.
* The file compiles on io too (the getters throw `UnsupportedError` there),
  so importing it from shared code is fine as long as the factory is only
  touched when `kIsWeb` / `identical(0, 0.0)` is true.

### Choosing the factory

* `databaseFactoryFfiWeb` (tag `ffi_web`): SQLite runs in a `SharedWorker`
  loaded from `sqflite_sw.js`; all tabs of the origin share one SQLite
  instance, so it is cross-tab safe. When `SharedWorker` is unavailable
  (Android Chrome) it silently falls back to a dedicated `Worker`, which is
  not cross-tab safe. This is the default choice.
* `databaseFactoryFfiWebNoWebWorker`: loads `sqlite3.wasm` in the main
  thread; no worker file needed, but long queries block the UI and several
  tabs writing the same database can corrupt it. Use for tools, demos or
  when workers cannot be served.
* `databaseFactoryFfiWebBasicWebWorker`: testing only (forces a dedicated
  `Worker`).
* The worker and wasm are loaded lazily on the first factory call from
  `sqflite_sw.js` / `sqlite3.wasm` relative to the page URL. With a
  non-root `<base href>` or another location, pass `sharedWorkerUri` /
  `sqlite3WasmUri` through `createDatabaseFactoryFfiWeb(options:
  SqfliteFfiWebOptions(...))` (see `sqflite-common-ffi-web-options`).
* Flutter app that already uses `sqflite` on mobile: keep the code, set
  `databaseFactory = databaseFactoryFfiWeb;` once at startup when `kIsWeb`,
  before the first `openDatabase`. The global `openDatabase()` then works on
  all platforms. Use `sqflite_common_ffi` (`databaseFactoryFfi`) for the
  desktop counterpart.

### Paths and persistence

* `getDatabasesPath()` returns `/` and relative paths are used as is: a
  database name such as `my_db.db` is a key in the virtual file system, not
  a file. Do not build paths with `path_provider` on the web.
* Storage is an IndexedDB database named `sqflite_databases` (override with
  `SqfliteFfiWebOptions.indexedDbName`) holding every sqflite database of the
  origin. IndexedDB is per origin including the port: `localhost:8080` and
  `localhost:8081` are different stores, so always debug on the same port.
  There is no OPFS backend.
* `inMemoryDatabasePath` opens a private in-memory SQLite database inside
  the worker (nothing stored).
* To import a bundled database (asset or download), write its bytes with
  `factory.writeDatabaseBytes(path, bytes)` then `openDatabase(path)`;
  `readDatabaseBytes(path)` exports it. `databaseExists`, `deleteDatabase`
  work on the virtual file system.
* `sqfliteFfiInit()` from `sqflite_common_ffi` is a no-op on the web; calling
  it in shared code is harmless.

### Limitations

* Experimental: slower than native, larger message overhead (each call goes
  through `postMessage`), not fully tested.
* `deleteDatabase` is reported as not working when the app itself is
  compiled with dart2wasm (`--wasm`); the JS build is the tested path.
* Basic `Worker` fallback (Android Chrome) is not cross-tab safe.
* Only one worker script name per site: the shared worker is keyed by its
  URL, so after upgrading the package all tabs must reload. To force a
  reload change the worker file name (see options skill, `sw_js_file`).

## Examples

### Flutter app: web + mobile + desktop

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
// sqflite_ffi.dart exports the whole sqflite_common API (openDatabase,
// databaseFactory...); package:sqflite/sqflite.dart would be redundant.
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
  // Global openDatabase() now works everywhere; on the web the path is a name.
  var db = await openDatabase(
    'app.db',
    version: 1,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE Note (id INTEGER PRIMARY KEY, text TEXT)',
    ),
  );
  await db.insert('Note', {'text': 'hello'});
  runApp(const SizedBox());
}
```

### Dart web app (no Flutter)

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  var factory = databaseFactoryFfiWeb;
  var db = await factory.openDatabase(
    'counter.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) =>
          db.execute('CREATE TABLE Counter (id INTEGER PRIMARY KEY, value INTEGER)'),
    ),
  );
  await db.rawInsert(
    'INSERT INTO Counter(id, value) VALUES (1, 0) ON CONFLICT(id) DO UPDATE SET value = value + 1',
  );
  print(await db.query('Counter'));
  await db.close();
}
```

### Importing an asset database on Flutter web

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

Future<Database> openBundledDatabase() async {
  const path = 'bundled.db';
  if (!await databaseFactory.databaseExists(path)) {
    final data = await rootBundle.load('assets/bundled.db');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await databaseFactory.writeDatabaseBytes(path, bytes);
  }
  return openDatabase(path, readOnly: true);
}
```

### Main-thread factory for a small tool page

```dart
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<String> sqliteVersion() async {
  // Only sqlite3.wasm is required, no sqflite_sw.js.
  var db = await databaseFactoryFfiWebNoWebWorker.openDatabase('tool.db');
  try {
    return (await db.rawQuery('SELECT sqlite_version()')).first.values.first
        as String;
  } finally {
    await db.close();
  }
}
```

## Common mistakes

* Forgetting `dart run sqflite_common_ffi_web:setup`: the first call fails
  and the console prints "An error occurred while initializing the web
  worker ... failure to find the worker javascript file at sqflite_sw.js".
* Serving the app from a sub path without adjusting `sharedWorkerUri` /
  `sqlite3WasmUri`, or a server that does not serve `.wasm` as
  `application/wasm`.
* Upgrading `sqflite_common_ffi_web` or `sqlite3` without re-running setup
  (`--force` if the files look up to date but the wasm version changed).
* Using `getDatabasesPath()` + `join` or `path_provider` on the web; use a
  plain name.
* Debugging on changing ports and "losing" the database.
* Setting `databaseFactory = databaseFactoryFfiWeb` on io (throws
  `UnsupportedError`): guard with `kIsWeb`.
* Importing only `sqflite_ffi_web.dart` and expecting `Database` or
  `OpenDatabaseOptions` to be defined; add `package:sqflite_common/sqlite_api.dart`
  (or `sqflite`).
