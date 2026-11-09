# sqflite_common_ffi_web

The [sqflite](https://pub.dev/packages/sqflite) API on the web: SQLite
compiled to WebAssembly ([sqlite3](https://pub.dev/packages/sqlite3), thanks
Simon Binder), the databases stored in IndexedDB.

[![pub package](https://img.shields.io/pub/v/sqflite_common_ffi_web.svg)](https://pub.dev/packages/sqflite_common_ffi_web)

- Same API as `sqflite` (`openDatabase`, `Database`, `Transaction`, `Batch`...),
  see the [sqflite documentation](https://pub.dev/packages/sqflite) for the API
  and its common pitfalls.
- Persistent (IndexedDB) and cross-tab safe (SQLite runs in a shared worker).
- Flutter web and Dart web apps, dart2js and dart2wasm
  (`flutter build web --wasm`).
- Web only: on Android, iOS and macOS use the `sqflite` plugin, on Linux,
  Windows and the Dart VM use
  [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi).

## Getting started

From the project folder (the one containing the `web` folder, also for a
Flutter app):

```bash
dart pub add sqflite_common_ffi_web
# Creates web/sqlite3.wasm and web/sqflite_sw.js
dart run sqflite_common_ffi_web:setup
```

The app needs these 2 files next to its `index.html`: `sqlite3.wasm` (SQLite)
and `sqflite_sw.js` (the shared worker running it). Put them in source control,
or run the setup in your build/CI before building the web app.

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  var factory = databaseFactoryFfiWeb;
  var db = await factory.openDatabase(
    'my_db.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      },
    ),
  );
  await db.insert('Test', {'name': 'hello'});
  print(await db.query('Test')); // in the browser console
  await db.close();
}
```

On the web a database path is only a name: there is no file system and
`getDatabasesPath()` returns `/`. `my_db.db`, `./my_db.db` and `/my_db.db` are
the same database (`db.path` is `/my_db.db`).

### Flutter: the same code on mobile and on the web

Set the default factory once in `main()`, before opening any database; the
rest of the `sqflite` code is unchanged:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const SizedBox());
}

/// Anywhere in your app: relative to getDatabasesPath() on mobile, a name on
/// the web.
Future<Database> openMyDatabase() {
  return openDatabase(
    'my_db.db',
    version: 1,
    onCreate: (db, version) async {
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
    },
  );
}
```

For Windows and Linux too, see
[one code base for mobile, desktop and web](https://github.com/tekartik/sqflite/blob/master/sqflite/README.md#one-code-base-for-mobile-desktop-and-web).

## Which factory

| Factory | SQLite runs | Files needed | Use it for |
|---|---|---|---|
| `databaseFactoryFfiWeb` | in a shared worker (a basic worker when shared workers are not available, Android Chrome) | `sqlite3.wasm`, `sqflite_sw.js` | apps (default) |
| `databaseFactoryFfiWebNoWebWorker` | in the page | `sqlite3.wasm` | tools, demos, tests: a long query blocks the page, not safe across tabs |
| `createDatabaseFactoryFfiWeb(options: ...)` | as above | as above | other file locations or names, another IndexedDB name, an in memory store (`SqfliteFfiWebOptions`) |

## Setup options

```bash
dart run sqflite_common_ffi_web:setup --help
```

- `--force`: rebuild the worker. The setup caches the worker per version of
  `sqflite_common_ffi_web`: after upgrading `sqflite_common_ffi`,
  `sqflite_common` or `sqlite3` alone, run it with `--force` to get their fixes
  in the worker.
- `--sqlite3-wasm-url <url>`: download another `sqlite3.wasm`
  ([releases](https://github.com/simolus3/sqlite3.dart/releases)), for example
  the one matching a newer `sqlite3` package. By default the setup downloads
  the release known to work with this version.
- `--dir <dir>` (default `web`), `--no-sqlite3-wasm`, `--verbose`, and the
  project path as argument.

The same from Dart (io only): `setupSqfliteWebBinaries()` from
`package:sqflite_common_ffi_web/setup.dart`.

## Common mistakes

- Setup not run, or the files not deployed: the first database call fails,
  the browser console says `An error occurred while initializing the web
  worker` (missing `sqflite_sw.js`), or the error names the `sqlite3.wasm` url
  that could not be loaded.
- Debugging on a different port each time: the IndexedDB storage is per origin,
  port included (`localhost:8080` is not `localhost:8081`). Use
  `flutter run -d chrome --web-port 8080`.
- `OpenDatabaseOptions(singleInstance: false)` for a persistent database: not
  supported, `openDatabase` throws an `ArgumentError` (see below).
- Using `databaseFactoryFfiWeb` outside the web: it throws an
  `UnsupportedError`, guard it with `kIsWeb`.
- Importing only `sqflite_ffi_web.dart`: `Database` and `OpenDatabaseOptions`
  come from `package:sqflite_common/sqlite_api.dart` (or `sqflite`).

## Limitations

### One connection per database (`singleInstance: false` not supported)

All the databases of a factory are opened in a single sqlite3 (wasm) instance
using a single virtual file system (an in-memory image persisted in IndexedDB).
This virtual file system has no locking between connections, so two connections
to the same database file could each write their own version of the pages and
corrupt the database.

For this reason `OpenDatabaseOptions(singleInstance: false)` is not supported
for a persistent database and `openDatabase` throws an `ArgumentError`. Open
the database once (default `singleInstance: true`): subsequent calls to
`openDatabase` with the same path return the same instance. Only in-memory
databases (`inMemoryDatabasePath`) can be opened multiple times with
`singleInstance: false`, each connection being a private database.

### One configuration per page or per worker

The factories of a page share the sqflite state. Create each factory once,
and in a page use a single no worker configuration (`noWebWorker: true`), not
mixed with worker factories: two no worker factories with different
`indexedDbName` see the same databases. A shared worker keeps the options of
its first use: for another `indexedDbName` or `sqlite3.wasm`, use another worker
file name (`sharedWorkerUri`).

### Basic worker

When shared workers are not supported (Android Chrome), a basic web worker is
used. In this case it is not cross-tab safe.

### No file access

Use `databaseFactory.writeDatabaseBytes()` / `readDatabaseBytes()` to import or
export a database (see
[opening an asset database on the web](https://github.com/tekartik/sqflite/blob/master/packages_web/sqflite_common_ffi_web/doc/opening_asset_db_web.md)).
Relative names are always at the root (`setDatabasesPath()` does not apply to
them on the web).

## Status

This is still experimental: slower than native, not fully tested. See also
[sqlite3 versions](https://github.com/tekartik/sqflite/blob/master/packages_web/sqflite_common_ffi_web/doc/troubleshooting.md)
and [why a separate package](https://github.com/tekartik/sqflite/blob/master/packages_web/sqflite_common_ffi_web/doc/why_yet_another_package.md).
