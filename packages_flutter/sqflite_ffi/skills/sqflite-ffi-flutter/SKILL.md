---
name: sqflite-ffi-flutter
description: >-
  Use when a Flutter app should use the ffi (package:sqlite3) implementation
  of sqflite on desktop and mobile with package:sqflite_ffi: what it adds over
  sqflite_common_ffi (Dart-only plugin, automatic registration of
  sqfliteDatabaseFactoryFfi as the default databaseFactory through
  SqfliteFfiPlugin.registerWith, one sqflite isolate shared between Flutter
  isolates via IsolateNameServer and sqfliteFfiIsolatePortName),
  createSqfliteDatabaseFactoryFfi, using the database from compute /
  Isolate.run, DartPluginRegistrant.ensureInitialized, coexistence with the
  native sqflite plugin, and when to pick sqflite, sqflite_common_ffi or
  sqflite_ffi.
---

# sqflite_ffi: ffi sqflite as a Flutter plugin

`package:sqflite_ffi` wraps `sqflite_common_ffi` in a Dart-only Flutter
plugin. Adding it to a Flutter app does two things that `sqflite_common_ffi`
alone does not:

* At startup Flutter calls `SqfliteFfiPlugin.registerWith()`, which runs
  `sqfliteFfiInit()` and sets `sqfliteDatabaseFactoryFfi` as the global
  `databaseFactory` if none is registered yet. The global `openDatabase()`
  works on Windows, Linux, macOS, Android and iOS with no `main()` code.
* All Flutter isolates (main, `compute`, `Isolate.run`) share one sqflite
  isolate: its `SendPort` is registered in `IsolateNameServer` under
  `sqfliteFfiIsolatePortName`, so `singleInstance` and transaction ordering
  hold across isolates.

```dart
import 'package:flutter/widgets.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var db = await openDatabase(inMemoryDatabasePath);
  debugPrint('${await db.rawQuery('SELECT sqlite_version()')}');
  await db.close();
  runApp(const SizedBox());
}
```

## Guidelines

* Add `sqflite_ffi` (0.1.x, Flutter >= 3.44, Dart 3.12) to `dependencies`.
  It brings `sqflite_common_ffi` and `sqlite3` (>= 3, build hooks: SQLite is
  bundled, nothing to install; run `flutter clean` when changing the
  `sqlite3` major version).
* Import `package:sqflite_ffi/sqflite_ffi.dart`. It re-exports
  `sqflite_common_ffi/sqflite_ffi.dart` (hence the whole `sqflite_common`
  API: `Database`, `openDatabase`, `deleteDatabase`, `inMemoryDatabasePath`,
  `databaseFactory`, `sqfliteFfiInit`, `SqfliteFfiInit`,
  `databaseFactoryFfiNoIsolate`, `SqfliteFfiIsolatePortServer`) but hides
  `databaseFactoryFfi` and `createDatabaseFactoryFfi`. Use the package's own
  `sqfliteDatabaseFactoryFfi` and `createSqfliteDatabaseFactoryFfi` instead.
* Choosing between packages:
  * `sqflite` alone: native plugin, iOS/Android/macOS only.
  * `sqflite_common_ffi`: pure Dart, desktop and tests; you set
    `databaseFactory` yourself; each Dart isolate gets its own sqflite
    isolate.
  * `sqflite_ffi`: Flutter app that wants ffi everywhere (or on desktop with
    zero setup) and/or uses the database from several isolates.
  * `sqflite_common_ffi_web` for the web: `sqflite_ffi` is a no-op there
    (`SqfliteFfiPlugin.registerWith()` does nothing and
    `sqfliteDatabaseFactoryFfi` returns the unsupported ffi factory).
* Registration order: `SqfliteFfiPlugin.registerWith()` uses
  `databaseFactoryOrNull ??=`, and so does the native `sqflite` plugin
  (`SqflitePlugin.registerWith()`). When both plugins are in the app the
  first one in the generated plugin registrant wins, which is not something
  to rely on. Assign the factory explicitly in `main()`: `databaseFactory =
  sqfliteDatabaseFactoryFfi;` to force ffi, or `databaseFactory =
  databaseFactorySqflitePlugin;` (exported by `package:sqflite/sqflite.dart`)
  to force the native plugin on mobile.
* Explicit factory use is always possible:
  `sqfliteDatabaseFactoryFfi.openDatabase(path, options: ...)`. Prefer it
  in libraries and inject it for tests.
* `createSqfliteDatabaseFactoryFfi({SqfliteFfiInit? ffiInit})` returns a new
  factory that still shares the isolate through `IsolateNameServer`.
  `ffiInit` must be top-level or static and runs in the sqflite isolate
  before the first SQLite call; the native library itself is selected by the
  `sqlite3` build hook user defines in `pubspec.yaml`
  (`hooks.user_defines.sqlite3.source`), see `sqflite-common-ffi-desktop`.
* Do not assume plugin registration in background isolates (`compute`,
  `Isolate.run`, `Isolate.spawn`): the global `databaseFactory` may be unset
  there. Either call `DartPluginRegistrant.ensureInitialized()` (from
  `dart:ui`) before the global `openDatabase()`, or use
  `sqfliteDatabaseFactoryFfi` directly: the `IsolateNameServer` lookup works
  in any isolate without registration.
* When two isolates open the same file, pass
  `OpenDatabaseOptions(rollbackActiveTransactionOnOpen: false)` (the default
  is `true` in debug mode) so the second `openDatabase` does not roll back a
  transaction running in the first isolate. Do not `close()` a shared
  single-instance database from the background isolate; the owner closes it.
* Stale registrations (hot restart leaves a dead port in
  `IsolateNameServer`) are detected with a ping (2 s timeout) and replaced
  automatically; no code needed.
* Paths: relative paths resolve under `.dart_tool/sqflite_common_ffi/databases`
  in the current directory. In an app use `path_provider`
  (`getApplicationSupportDirectory()`) and `package:path` `join`. The parent
  directory is created on open.
* Tests: `flutter test` works with `sqfliteDatabaseFactoryFfi` after
  `TestWidgetsFlutterBinding.ensureInitialized()` and `sqfliteFfiInit()`;
  plain `sqflite_common_ffi` in `dev_dependencies` is enough when the test
  does not need isolate sharing (see `sqflite-common-ffi-testing`).

## Examples

### Database work in a compute isolate sharing the instance

```dart
import 'package:flutter/foundation.dart' show compute;
import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<void> _insertInIsolate(String path) async {
  // Same sqflite isolate as the main isolate: same Database instance.
  final db = await sqfliteDatabaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(rollbackActiveTransactionOnOpen: false),
  );
  await db.transaction((txn) async {
    await txn.insert('Test', {'name': 'isolate 1'});
    await txn.insert('Test', {'name': 'isolate 2'});
  });
  // Do not close: the main isolate owns the shared instance.
}

Future<List<Object?>> run(String path) async {
  final db = await sqfliteDatabaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
      ),
      rollbackActiveTransactionOnOpen: false,
    ),
  );
  try {
    await Future.wait([
      db.transaction((txn) async {
        await txn.insert('Test', {'name': 'main 1'});
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await txn.insert('Test', {'name': 'main 2'});
      }),
      compute(_insertInIsolate, path),
    ]);
    // The background transaction waited for the main one:
    // main 1, main 2, isolate 1, isolate 2
    return (await db.query('Test', orderBy: 'id')).map((r) => r['name']).toList();
  } finally {
    await db.close();
  }
}
```

### Forcing ffi even when the native sqflite plugin is present

```dart
import 'package:flutter/widgets.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Both sqflite and sqflite_ffi are in pubspec.yaml; pick ffi explicitly.
  databaseFactory = sqfliteDatabaseFactoryFfi;
  runApp(const SizedBox());
}
```

### Database path with path_provider

```dart
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<Database> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  return openDatabase(
    p.join(dir.path, 'app.db'),
    version: 1,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE Note (id INTEGER PRIMARY KEY, text TEXT)',
    ),
  );
}
```

### Isolate spawned outside Flutter

```dart
import 'dart:isolate';
import 'dart:ui' show DartPluginRegistrant;

import 'package:sqflite_ffi/sqflite_ffi.dart';

Future<int> countInIsolate(String path) => Isolate.run(() async {
      // Needed for the global openDatabase(); not for sqfliteDatabaseFactoryFfi.
      DartPluginRegistrant.ensureInitialized();
      final db = await openDatabase(
        path,
        options: OpenDatabaseOptions(rollbackActiveTransactionOnOpen: false),
      );
      final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM Note');
      return rows.first['c'] as int;
    });
```

### Custom ffiInit

```dart
import 'package:sqflite_ffi/sqflite_ffi.dart';

void _ffiInit() {
  // Runs inside the shared sqflite isolate before the first SQLite call.
}

final myFactory = createSqfliteDatabaseFactoryFfi(ffiInit: _ffiInit);
```

### Flutter test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('open in memory', () async {
    final db = await sqfliteDatabaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
}
```

## Common mistakes

* Depending on `sqflite_ffi` and still calling `sqfliteFfiInit()` +
  `databaseFactory = databaseFactoryFfi` from `sqflite_common_ffi`: this
  creates a second, non-shared sqflite isolate and prints the "changing
  sqflite default factory" warning. Use `sqfliteDatabaseFactoryFfi` or
  nothing.
* Expecting ffi on the web: use `sqflite_common_ffi_web`.
* Closing a shared single-instance database from a background isolate.
* Opening the same file from two isolates in debug mode without
  `rollbackActiveTransactionOnOpen: false`.
* Calling `openDatabase()` in a hand-spawned isolate without
  `DartPluginRegistrant.ensureInitialized()`: `databaseFactory not
  initialized`.
* Having both `sqflite` and `sqflite_ffi` in `pubspec.yaml` and not
  assigning `databaseFactory`: which implementation runs depends on the
  registrant order.
