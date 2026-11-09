# sqflite ffi

[sqflite](https://pub.dev/packages/sqflite) based ffi implementation. Based
on [`sqlite3`](https://pub.dev/packages/sqlite3). Thanks to [Simon Binder](https://github.com/simolus3)

* Works on Linux, MacOS and Windows on both Flutter and Dart VM.
* Works on iOS and Android (using [sqlite3](https://pub.dev/packages/sqlite3) - Thanks
to [Simon Binder](https://github.com/simolus3))

It allows also mocking sqflite during regular flutter unit test (i.e. not using the emulator/simulator).

Same API as `sqflite` (`openDatabase`, `Database`, `Transaction`, `Batch`...),
see the [sqflite documentation](https://pub.dev/packages/sqflite) for the API
and its common pitfalls. Other platforms:
* Flutter app on Android, iOS, macOS: the native [sqflite](https://pub.dev/packages/sqflite) plugin, or this
  package (see [using ffi instead of sqflite](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md)).
* Flutter app wanting ffi everywhere, or sharing databases between isolates: [sqflite_ffi](https://pub.dev/packages/sqflite_ffi).
* Web: [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).

## Getting Started

### Dart

Add the dependency (or a dev dependency if only used in tests):

```bash
dart pub add sqflite_common_ffi
# or for tests only
dart pub add dev:sqflite_common_ffi
```

Then:
1. call `sqfliteFfiInit()` once, before the first database call,
2. use `databaseFactoryFfi` to open the database, or set it as the global
   factory (`databaseFactory = databaseFactoryFfi;`) to use the global
   `openDatabase()` of existing sqflite code,
3. open the database once with a `version` and an `onCreate` callback, and keep it.

### SQLite library

Since 2.4.0, `sqflite_common_ffi` uses `sqlite3` 3.x, which bundles SQLite with
your application using build hooks on every platform:
* Linux: nothing to install.
* Windows: nothing to copy.
* MacOS, iOS, Android: nothing to do.

Build hooks run with `dart run`, `dart test`, `flutter run`, `flutter test` and
`flutter build`, not with `dart xxx.dart`: run `dart run xxx.dart` at least once
(IDE launchers may not run the hooks). Run `flutter clean` when switching between
`sqlite3` v2 and v3.

The library can be changed in your application `pubspec.yaml`, for example to
use the one of the system (`libsqlite3` must then be installed on Linux) or an
encrypted version (`sqlcipher` or `sqlite3mc`, see [encryption support](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/encryption_support.md)):

```yaml
hooks:
  user_defines:
    sqlite3:
      source: system # default: sqlite3 (bundled)
```

See the [sqlite3 hook options](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md).

`sqfliteFfiInit` is provided as an implementation reference for loading the sqlite library. Please look
at [sqlite3](https://pub.dev/packages/sqlite3)
if you want to override the behavior.

### sqlite3 v2 support

To remain on `sqlite3` v2 (`libsqlite3` and `libsqlite3-dev` required on Linux,
`sudo apt-get -y install libsqlite3-0 libsqlite3-dev`; in Windows release mode, the
[last sqlite3.dll](https://github.com/tekartik/sqflite/blob/1dd13926ec92015640068fca1601b4d1fadfa2ee/sqflite_common_ffi/lib/src/windows/sqlite3.dll)
copied next to the executable), see
[here](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/troubleshooting.md#sqlite3-v2-support).
Use the following constraint:
```yaml
dependencies:
  sqlite3: ^2.9.4
  sqflite_common_ffi: ^2.3.7
```

### Web

Look at package [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) for experimental Web support.

## Sample code

### Unit test code

`sqflite_ffi_test.dart`:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('simple sqflite example', () async {
    var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
}
```

Close the database at the end of each test: while open,
`openDatabase(inMemoryDatabasePath)` returns the same in-memory database.

More info on unit testing [here](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/testing.md)

### Application

Make it a normal dependency.

`main.dart`:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Init ffi (Windows specific setup, no-op on other platforms).
  sqfliteFfiInit();

  var factory = databaseFactoryFfi;
  var db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT NOT NULL)',
        );
      },
    ),
  );
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});
  await db.insert('Product', <String, Object?>{'title': 'Product 2'});

  var result = await db.query('Product');
  print(result);
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 2}]
  await db.close();
}
```

Example with a database file and path_provider (Flutter)

```dart
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var factory = databaseFactoryFfi;
  var appSupportDir = await getApplicationSupportDirectory();

  // Create path for database, its parent directory is created on open.
  var dbPath = p.join(appSupportDir.path, 'databases', 'my_db.db');
  var db = await factory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      // Only called the first time, when the database does not exist yet.
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT NOT NULL)',
        );
      },
    ),
  );

  await db.insert('Product', <String, Object?>{'title': 'Product 1'});
  print(await db.query('Product'));
  await db.close();
}
```

If your existing application uses sqflite on iOS/Android/MacOS, you can also set the proper initialization to have
your
application [work on Linux and windows](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md).

## Limitations

* Database calls are made in a separate isolate (use `databaseFactoryFfiNoIsolate`
  in widget tests or in your own background isolate),
* Multi-instance support (not common) is simulated
* As another note, `getDatabasesPath()` returns `.dart_tool/sqflite_common_ffi/databases`
  in the current directory: fine for tests and scripts, but in an application
  rely on a custom strategy using package such as `path_provider`.
