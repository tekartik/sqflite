---
name: sqflite-common-ffi-testing
description: >-
  Use when writing or fixing unit tests, widget tests or CI runs for code that
  uses sqflite (Dart VM or Flutter, no device or emulator) with
  package:sqflite_common_ffi: sqfliteFfiInit in main or setUpAll, opening
  inMemoryDatabasePath with databaseFactoryFfi, replacing the global
  databaseFactory so existing openDatabase code runs in flutter test,
  databaseFactoryFfiNoIsolate for testWidgets, @TestOn('vm'), temporary
  database files and deleteDatabase, asserting on DatabaseException.
---

# Testing sqflite code with sqflite_common_ffi

The native `sqflite` plugin cannot run in `dart test` or `flutter test`.
`package:sqflite_common_ffi` provides `databaseFactoryFfi`, a real SQLite
implementation (via `package:sqlite3`) that runs on the developer machine and
on Linux/macOS/Windows CI runners, so database code is tested against SQLite
itself rather than mocks.

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  test('insert and query', () async {
    var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
    await db.insert('Test', {'value': 'a'});
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'a'},
    ]);
    await db.close();
  });
}
```

## Guidelines

### Setup

* Add `sqflite_common_ffi` to `dev_dependencies` (to `dependencies` if the
  app itself uses it on desktop). `sqlite3 >= 3` bundles SQLite through build
  hooks: run tests with `dart test` / `flutter test`, nothing to install.
* Import `package:sqflite_common_ffi/sqflite_ffi.dart` in tests. It exports
  the whole `sqflite_common` API (`Database`, `OpenDatabaseOptions`,
  `inMemoryDatabasePath`, `DatabaseException`, global `databaseFactory`,
  `openDatabase`...). In Flutter tests it replaces
  `package:sqflite/sqflite.dart` (importing both triggers the
  `unnecessary_import` lint); both expose the same global `databaseFactory`.
* Call `sqfliteFfiInit()` once, at the top of `main()` or in `setUpAll`.
  Required on Windows, harmless elsewhere.
* Mark Dart VM test files with `@TestOn('vm')` (before `library;`) when the
  package also runs tests on the web: `databaseFactoryFfi` throws
  `UnsupportedError` in a browser.

### Choosing the factory

* Code that receives a `DatabaseFactory` (recommended design): pass
  `databaseFactoryFfi` and open `inMemoryDatabasePath`.
* Code that calls the global `openDatabase()` / `deleteDatabase()` (typical
  Flutter code): set `databaseFactory = databaseFactoryFfi;` in `setUpAll` (or
  at the top of `main`). Do it once per test process; setting it again only
  prints a warning.
* `testWidgets` (Flutter widget tests): use `databaseFactoryFfiNoIsolate`.
  The isolate-based factory can hang under the fake async zone of
  `WidgetTester`; the no-isolate factory runs SQLite synchronously in the test
  isolate.
* Plain `test()` inside a Flutter package works with either factory;
  `databaseFactoryFfi` is closest to production.

### Isolation between tests

* Prefer `inMemoryDatabasePath`: each `openDatabase` after a `close()` gives
  an empty database and nothing is left on disk. Always `close()` in the test
  (or in `tearDown`) so the next test starts fresh.
* For file-based tests (migrations, `onUpgrade`, reopen scenarios) use a
  unique relative name per test: it resolves under
  `.dart_tool/sqflite_common_ffi/databases`, is created on open and is
  ignored by git in most setups. Call `factory.deleteDatabase(path)` in
  `setUp` so a previous run cannot leak state.
* Do not share one `Database` across tests through a global; open it in
  `setUp` and close it in `tearDown`.

### Assertions

* Errors are `DatabaseException`: assert with `isNoSuchTableError('Test')`,
  `isUniqueConstraintError('Test.value')`, `isSyntaxError()`,
  `isDatabaseClosedError()` or `getResultCode()`, never on message text.
* `expect(await db.query(...), [...])` works: rows are
  `List<Map<String, Object?>>` and deep-equal to literal maps.
* `await db.getVersion()` returns the `user_version` and is a quick check that
  `onCreate` / `onUpgrade` ran.

### CI

* Linux, macOS and Windows runners all work with `sqlite3 >= 3` without extra
  packages. Only the legacy `sqlite3` v2 setup needed
  `sudo apt-get install libsqlite3-dev` on Ubuntu.
* Keep test paths relative or under a temp directory; avoid absolute
  developer-machine paths.

## Examples

### Testing a class that takes a DatabaseFactory

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

class NoteStore {
  NoteStore(this.factory);
  final DatabaseFactory factory;
  late Database db;

  Future<void> open(String path) async {
    db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, text TEXT NOT NULL)',
        ),
      ),
    );
  }

  Future<int> add(String text) => db.insert('Note', {'text': text});
  Future<List<String>> texts() async =>
      (await db.query('Note', orderBy: 'id')).map((r) => r['text'] as String).toList();
}

void main() {
  sqfliteFfiInit();
  late NoteStore store;

  setUp(() async {
    store = NoteStore(databaseFactoryFfi);
    await store.open(inMemoryDatabasePath);
  });
  tearDown(() => store.db.close());

  test('add', () async {
    await store.add('hello');
    expect(await store.texts(), ['hello']);
  });

  test('not null constraint', () async {
    try {
      await store.db.insert('Note', {'text': null});
      fail('should throw');
    } on DatabaseException catch (e) {
      expect(e.isNotNullConstraintError('Note.text'), isTrue);
    }
  });
}
```

### Flutter test for code using the global openDatabase

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('openDatabase works in flutter test', () async {
    var db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
      },
    );
    await db.insert('Test', {'value': 'my_value'});
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'},
    ]);
    await db.close();
  });
}
```

### Widget test: no isolate

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  testWidgets('database in a widget test', (tester) async {
    var db = await openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
    expect(await db.query('Test'), isEmpty);
    await db.close();
  });
}
```

### Migration test with a file that is reopened

```dart
@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  const path = 'migration_test.db'; // under .dart_tool/sqflite_common_ffi/databases

  setUp(() => factory.deleteDatabase(path));

  test('upgrade from 1 to 2 adds a column', () async {
    var db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)'),
      ),
    );
    await db.close();

    db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE Test ADD COLUMN name TEXT');
          }
        },
      ),
    );
    expect(await db.getVersion(), 2);
    await db.insert('Test', {'name': 'ok'});
    await db.close();
  });
}
```

### Expecting a missing table error

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  test('no such table', () async {
    var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    try {
      await db.query('Missing');
      fail('should throw');
    } on DatabaseException catch (e) {
      expect(e.isNoSuchTableError('Missing'), isTrue);
    } finally {
      await db.close();
    }
  });
}
```

## Common mistakes

* Forgetting `sqfliteFfiInit()`: tests pass on macOS/Linux and fail on
  Windows.
* Using `databaseFactoryFfi` inside `testWidgets`: use
  `databaseFactoryFfiNoIsolate`.
* Calling the global `openDatabase()` without setting `databaseFactory`
  first: `StateError: databaseFactory not initialized`.
* Not closing databases between tests, so `singleInstance` returns the
  previous test's database (same path) with stale tables.
* Reusing a file path across tests without `deleteDatabase` in `setUp`.
* Running the test file in a browser configuration: add `@TestOn('vm')`.
* Matching on exception messages instead of `DatabaseException` helpers.
