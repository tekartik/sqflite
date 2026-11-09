# sqflite_ffi

[![pub package](https://img.shields.io/pub/v/sqflite_ffi.svg)](https://pub.dev/packages/sqflite_ffi)

The ffi implementation of sqflite (`package:sqlite3`, SQLite bundled with the
app) as a Flutter plugin, based on
[`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi). Same API
as [sqflite](https://pub.dev/packages/sqflite) (`openDatabase`, `Database`,
`Transaction`, `Batch`...).

What it adds to `sqflite_common_ffi`:

* registration: at startup it sets the global `databaseFactory`, nothing to
  call in `main()`;
* one sqflite isolate for the whole app: its port is shared through Flutter's
  `IsolateNameServer`, so the main isolate, `compute` and `Isolate.run` use the
  same database instances (`singleInstance` and transactions hold across
  isolates).

## Getting started

```sh
flutter pub add sqflite_ffi
```

```dart
import 'package:flutter/widgets.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var db = await openDatabase(inMemoryDatabasePath);
  print(await db.rawQuery('SELECT sqlite_version()'));
  await db.close();
}
```

In a real app, set the databases path first (the ffi default is relative to
the current directory, not writable on Android and iOS), see
[databases path](https://github.com/tekartik/sqflite/blob/master/packages_flutter/sqflite_ffi/doc/databases_path.md):

```dart
var dir = await getApplicationSupportDirectory(); // package:path_provider
await databaseFactory.setDatabasesPath(join(dir.path, 'databases'));
```

## Platforms

| Platform | Support |
|---|---|
| Android, iOS, Linux, macOS, Windows | yes, SQLite bundled by the `sqlite3` build hooks (nothing to install) |
| Web | no: registration does nothing, `sqfliteDatabaseFactoryFfi` throws `UnsupportedError`; use [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) |

## When to use what

| Package | Use it for |
|---|---|
| `sqflite` | Flutter app on Android, iOS, macOS with the SQLite of the OS |
| `sqflite_common_ffi` | Dart VM, desktop, unit tests; you set `databaseFactory`, one sqflite isolate per Dart isolate |
| `sqflite_ffi` | Flutter app wanting a bundled SQLite everywhere, or using the database from several isolates |

Main entry points:

* `sqfliteDatabaseFactoryFfi`: the factory (the one registered as
  `databaseFactory`), use it directly in libraries and tests.
* `createSqfliteDatabaseFactoryFfi(ffiInit: ...)`: a factory with an init
  function for the sqflite isolate (it shares the same isolate).
* `SqfliteFfiPlugin.registerWith()`: called by Flutter, sets
  `databaseFactory` when it is not set yet.

## Common pitfalls

* `sqflite` and `sqflite_ffi` both in an app: both register with
  `databaseFactory ??=`, the first registered wins. Choose in `main()`:
  `databaseFactory = sqfliteDatabaseFactoryFfi;`.
* Do not also use `databaseFactoryFfi` of `sqflite_common_ffi`: it starts a
  second, not shared sqflite isolate (it is hidden by this package's export).
* An isolate spawned by hand (`Isolate.run`, `compute`) has no plugin
  registration: call `DartPluginRegistrant.ensureInitialized()` (`dart:ui`)
  before the global `openDatabase()`, or use `sqfliteDatabaseFactoryFfi`.
* When two isolates open the same file, pass
  `OpenDatabaseOptions(rollbackActiveTransactionOnOpen: false)` (`true` in
  debug mode), otherwise the second open rolls back a transaction of the
  first one. Let the isolate that owns the database close it.
* `ffiInit` (of `createSqfliteDatabaseFactoryFfi`) runs only when this factory
  starts the shared sqflite isolate: it is not called when another factory or
  isolate started it first.
* The databases path is per isolate: pass full paths to background isolates.

## More

* [Databases path](https://github.com/tekartik/sqflite/blob/master/packages_flutter/sqflite_ffi/doc/databases_path.md): per platform folders, same folders
  as the native plugin.
* Agent skill: [`sqflite-ffi-flutter`](https://github.com/tekartik/sqflite/blob/master/packages_flutter/sqflite_ffi/skills/sqflite-ffi-flutter/SKILL.md).
* [sqflite documentation](https://github.com/tekartik/sqflite/tree/master/sqflite/doc)
  and [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (the
  `sqlite3` build hook options).
