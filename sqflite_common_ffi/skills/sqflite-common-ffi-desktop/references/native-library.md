# Native SQLite library setup and troubleshooting

`sqflite_common_ffi` does not load SQLite itself: `package:sqlite3` does.
What you configure depends on the `sqlite3` major version resolved by pub.

## sqlite3 v3 (sqflite_common_ffi >= 2.4, current)

`sqlite3 >= 3` uses Dart [build hooks](https://dart.dev/tools/hooks): a
pre-compiled SQLite (with FTS5, RTREE, math functions, session extension) is
downloaded from the `sqlite3.dart` GitHub releases, verified by sha256 and
bundled with the application. Nothing to install on the machine.

Requirements:

* Dart 3.12 / Flutter 3.44 or later.
* Commands that run hooks: `dart run`, `dart test`, `flutter run`,
  `flutter test`, `flutter build`. Plain `dart file.dart` does not run hooks;
  run `dart run` once from a terminal so the library is built and cached
  under `.dart_tool/hooks_runner/`, after which IDE launches usually work.
* `flutter clean` after switching between `sqlite3` v2 and v3.

Library selection lives in the **application** `pubspec.yaml`
(`hooks.user_defines.sqlite3`). Values of `source`:

| `source` | Effect |
| --- | --- |
| `sqlite3` (default) | Bundled upstream SQLite. |
| `sqlite3mc` | Bundled SQLite3MultipleCiphers build (encryption). |
| `sqlcipher` | Bundled SQLCipher community build (encryption, links OpenSSL on Windows/Linux/Android). |
| `system` | `dlopen` the OS library (`libsqlite3.so`, `libsqlite3.dylib`, `sqlite3.dll`). Add `name: sqlcipher` (or `name_windows:`, `name_linux:`, ...) to change the library name. |
| `process` | Symbols from the running process (`DynamicLibrary.process()`). |
| `executable` | Symbols statically linked in the executable. |
| `source` | Compile a `sqlite3.c` you provide (`path:`, optional `defines:`). |

```yaml
hooks:
  user_defines:
    sqlite3:
      source: system
      name_windows: winsqlite3
      name: sqlite3
```

An internal artifact mirror can replace GitHub with `url_pattern:`. See the
`sqlite3` package `doc/hook.md` for every key.

With `sqlcipher` / `sqlite3mc`, set the key as the first statement on the
connection, in `onConfigure`:

```dart
onConfigure: (db) async {
  await db.rawQuery("PRAGMA key = 'my secret'");
},
```

The `ffiInit` parameter of `createDatabaseFactoryFfi` still exists and runs
in the sqflite isolate before the first call, but it is no longer the place
to choose the library.

## sqlite3 v2 (legacy, sqflite_common_ffi <= 2.3.7)

Pin both packages to stay on v2:

```yaml
dependencies:
  sqflite_common_ffi: ^2.3.7
  sqlite3: ^2.9.4
```

* Linux: `sudo apt-get -y install libsqlite3-0 libsqlite3-dev` (or the
  package tool `dart tool/linux_setup.dart` as root). Missing library error:
  `SqfliteFfiException(error, Invalid argument(s): Failed to load dynamic
  library (libsqlite3.so: cannot open shared object file ...))`.
* Windows: a `sqlite3.dll` is bundled for debug; in release copy
  `sqlite3.dll` next to the executable.
* macOS: works as is.
* Flutter iOS/Android/macOS: add `sqlite3_flutter_libs`.
* The library can be overridden in an `ffiInit` with
  `package:sqlite3/open.dart`:

  ```dart
  import 'dart:ffi';
  import 'package:sqlite3/open.dart';

  void ffiInit() {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('path/to/sqlite3.dll'),
    );
  }
  ```

  This API does not exist in `sqlite3` v3.

## GitHub Actions (Linux runners)

With v3 nothing is needed. With v2 on `ubuntu-latest` (24.04 and later) add:

```yaml
- run: sudo apt-get -y install libsqlite3-dev
```

or the cross-platform helper:

```yaml
- name: Install libsqlite3-dev
  run: |
    dart pub global activate --source git https://github.com/tekartik/ci.dart --git-path ci
    dart pub global run tekartik_ci:setup_sqlite3lib
```

## Custom pragmas handled by sqflite_common_ffi

Sent through `db.execute(...)`, never reaching SQLite as-is:

* `PRAGMA sqflite -- db_config_defensive_off` sets `SQLITE_DBCONFIG_DEFENSIVE`
  to 0 on the connection so `PRAGMA writable_schema = ON` works. Constant:
  `sqflitePragmaDbDefensiveOff` (`package:sqflite_common/utils/utils.dart`).

## Where things are

* Default databases directory (`getDatabasesPath()`):
  `<cwd>/.dart_tool/sqflite_common_ffi/databases`. Prefer absolute paths in
  applications.
* Isolate name in the debugger: `SqfliteIsolate`.
* Errors are wrapped in `SqfliteFfiException` (a `DatabaseException`); the
  SQL and arguments are included in `toString()` with blobs shortened to
  `Blob(<length>)`.
