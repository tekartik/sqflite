# sqflite_common_ffi_web

sqlite Web implementation (experimental) of the [sqflite](https://pub.dev/packages/sqflite)
API. Features:
- Persistency (in indexeddb)
- Cross-tab safe (runs in a shared worker)
- Wasm compatible (`flutter build web --wasm`)

Thanks Simon Binder for the excellent sqlite3 lib.

Same API as `sqflite` (`openDatabase`, `Database`, `Transaction`, `Batch`...),
see the [sqflite documentation](https://pub.dev/packages/sqflite) for the API
and its common pitfalls.

## Setup

Add the dependency:
```bash
dart pub add sqflite_common_ffi_web
```

### Setup binaries

Implementation requires [sqlite3.wasm binaries](https://github.com/simolus3/sqlite3.dart/releases)
into your web folder as well as a sqflite specific shared worker.

You can install binaries using the command (from your project folder, the one
containing the `web` folder, also for a Flutter app):

```bash
$ dart run sqflite_common_ffi_web:setup
```

It should create the following files in your web folder:
- `sqlite3.wasm`
- `sqflite_sw.js`

that you can put in source control or not (personally I don't, in this case run
the command in your build/CI before building the web app). Without these files,
the first database call fails (`An error occurred while initializing the web worker`
in the browser console).

Note: when sqlite3 and its wasm binary are updated, you may need to run the command again using the force option:
```bash
$ dart run sqflite_common_ffi_web:setup --force
```

However since it depends on `sqflite3` version and its associated binary, if it gets updated 
and the tool still download the old version (sorry it is hardcoded) you might have to manually
download a compatible binary from [sqlite3.wasm binaries](https://github.com/simolus3/sqlite3.dart/releases)
I don't have a better option yet, sorry.

### Use the proper factory.

```dart
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  // Use the ffi web factory in web apps (flutter or dart)
  var factory = databaseFactoryFfiWeb;
  var db = await factory.openDatabase('my_db.db');
  var sqliteVersion =
      (await db.rawQuery('select sqlite_version()')).first.values.first;
  print(sqliteVersion); // the SQLite version of sqlite3.wasm
  await db.close();
}
```

On the web, a database path is only a name (`my_db.db`): there is no file
system and `getDatabasesPath()` returns `/`.

### Add web support to existing sqflite application

If you have any existing iOS/Android application, one solution is to change the default database
factory once in `main()`, before opening any database:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  if (kIsWeb) {
    // Change default factory on the web
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const MyApp());
}

/// Anywhere in your app: the same code works on mobile and on the web
Future<Database> openMyDatabase() {
  // Relative to getDatabasesPath() on mobile, only a name on the web.
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

## Limitations

### Use the same web port when debugging

The database is stored in the browser indexeddb. Like any other web storage, it is tied to the port. (i.e. localhost:8080 is different from localhost:8081).
When debugging, you should use the same port to keep the same indexeddb database
(`flutter run -d chrome --web-port 8080`).

### No shared worker available

When shared worker are not supported - for example in Android Chrome as of 2022-10-20 -, a basic web worker is used.
In this case it is not cross-tab safe.

### One connection per database (`singleInstance: false` not supported)

All the databases of a factory are opened in a single sqlite3 (wasm) instance using a single
virtual file system (an in-memory image persisted in IndexedDB). This virtual file system has no
locking between connections, so two connections to the same database file could each write their
own version of the pages and corrupt the database.

For this reason `OpenDatabaseOptions(singleInstance: false)` is not supported for a persistent
database and `openDatabase` throws an `ArgumentError`. Open the database once (default
`singleInstance: true`): subsequent calls to `openDatabase` with the same path return the same
instance. Only in-memory databases (`inMemoryDatabasePath`) can be opened multiple times with
`singleInstance: false`, each connection being a private database.

Use the same name for the same database everywhere in your app (for example
not `my_db.db` here and `/my_db.db` there).

### No file access

Use `databaseFactory.writeDatabaseBytes()` / `readDatabaseBytes()` to import or
export a database (see [opening an asset database on the web](https://github.com/tekartik/sqflite/blob/master/packages_web/sqflite_common_ffi_web/doc/opening_asset_db_web.md)).

## Status

This is still experimental:
- slow
- not fully tested
- bugs
