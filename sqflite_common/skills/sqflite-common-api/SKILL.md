---
name: sqflite-common-api
description: >-
  Use when writing Dart code against the sqflite API without depending on
  Flutter, or when a shared package must work with sqflite (mobile),
  sqflite_common_ffi (desktop/VM/tests) and sqflite_common_ffi_web: the
  DatabaseFactory, Database, Transaction, Batch, DatabaseExecutor,
  OpenDatabaseOptions, ConflictAlgorithm, DatabaseException, QueryCursor types
  from package:sqflite_common/sqlite_api.dart, the global databaseFactory /
  openDatabase from sqflite_common/sqflite.dart, sql.dart escapeName,
  utils/utils.dart firstIntValue, sqflite_logger.dart
  SqfliteDatabaseFactoryLogger, sandbox(), SqfliteSqlCommand, queryIterate.
---

# sqflite_common: the pure-Dart sqflite API

`package:sqflite_common` defines the whole sqflite API (`DatabaseFactory`,
`Database`, `Transaction`, `Batch`, `OpenDatabaseOptions`, ...) and the shared
implementation, with no Flutter dependency. It contains no SQLite engine: an
implementation package supplies a `DatabaseFactory` (`sqflite` on
Android/iOS/macOS, `sqflite_common_ffi` on desktop/VM/tests,
`sqflite_common_ffi_web` on the web). Depend on `sqflite_common` in packages
that must stay Flutter-free and accept a factory from the caller.

```dart
import 'package:sqflite_common/sqlite_api.dart';

class NoteStore {
  NoteStore(this.factory, this.path);

  final DatabaseFactory factory;
  final String path;

  Future<Database> open() => factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute(
            'CREATE TABLE Note (id INTEGER PRIMARY KEY, content TEXT)',
          ),
        ),
      );
}
```

## Guidelines

### Which import gives what

* `package:sqflite_common/sqlite_api.dart`: the types only. `DatabaseFactory`
  (`openDatabase(path, {options})`, `getDatabasesPath()`,
  `setDatabasesPath()`, `deleteDatabase()`, `databaseExists()`,
  `readDatabaseBytes()`, `writeDatabaseBytes()`), `DatabaseExecutor`
  (`execute`, `rawInsert`/`insert`, `rawQuery`/`query`,
  `rawQueryCursor`/`queryCursor`, `rawUpdate`/`update`,
  `rawDelete`/`delete`, `batch()`, `database`), `Database` (`path`,
  `isOpen`, `close()`, `transaction()`, `readTransaction()`), `Transaction`,
  `Batch` (`commit`, `apply`, `length`, same mutators as the executor),
  `QueryCursor`, `OpenDatabaseOptions`, `ConflictAlgorithm`,
  `DatabaseException`, `inMemoryDatabasePath`, the callback typedefs
  (`OnDatabaseCreateFn`, `OnDatabaseVersionChangeFn`, `OnDatabaseOpenFn`,
  `OnDatabaseConfigureFn`), `onDatabaseDowngradeDelete`,
  `onDatabaseVersionChangeError`, and the extensions
  `SqfliteDatabaseExecutorExt` (`getVersion`, `setVersion`),
  `SqfliteDatabaseExt` (`setJournalMode`),
  `SqfliteDatabaseExecutorIterateExt` (`queryIterate`, `rawQueryIterate`),
  `SqfliteDatabaseFactorySandboxExtension` (`sandbox`),
  `SqfliteSqlCommand` + `SqfliteSqlCommandExecutorExt`, `sqfliteLogLevel*`
  constants. Use this import in libraries.
* `package:sqflite_common/sqflite.dart`: everything above plus the global
  `databaseFactory` getter/setter, `databaseFactoryOrNull`, and the global
  functions `openDatabase`, `openReadOnlyDatabase`, `getDatabasesPath`,
  `deleteDatabase`, `databaseExists` that forward to `databaseFactory`. Only
  applications should rely on the global; a library that reads it forces the
  app to have set it. `package:sqflite/sqflite.dart` and
  `package:sqflite_common_ffi/sqflite_ffi.dart` both re-export this library,
  so do not import it next to them (`unnecessary_import`).
* `package:sqflite_common/sql.dart`: `ConflictAlgorithm`, `escapeName`,
  `unescapeName`.
* `package:sqflite_common/utils/utils.dart`: `firstIntValue(rows)`,
  `firstStringValue(rows)`, `hex(bytes)`, `setLockWarningInfo(duration:,
  callback:)`, `sqlCountColumn` (`'COUNT(*)'`). There is no `Sqflite` class
  here; that class lives in `package:sqflite`.
* `package:sqflite_common/sqflite_logger.dart`: `SqfliteDatabaseFactoryLogger`
  (its constructor is `@experimental`, expect an `experimental_member_use`
  analyzer warning), `SqfliteLoggerOptions`, `SqfliteDatabaseFactoryLoggerType` (`all`,
  `invoke`), the event classes (`SqfliteLoggerSqlEvent`,
  `SqfliteLoggerBatchEvent`, `SqfliteLoggerDatabaseOpenEvent`,
  `SqfliteLoggerDatabaseCloseEvent`, `SqfliteLoggerDatabaseDeleteEvent`,
  `SqfliteLoggerInvokeEvent`), `SqfliteLoggerEventExt.dump()` and
  `DatabaseFactoryLoggerDebugExt.debugQuickLoggerWrapper()`.
* `package:sqflite_common/sqflite_dev.dart`: deprecated dev-only
  `setLogLevel` / `setOptions` (`SqfliteDatabaseFactoryDev`) and
  `SqfliteOptions`. Do not ship code that uses it.
* Never import `package:sqflite_common/src/...` from user code.

### Designing a Flutter-free package

* Take a `DatabaseFactory` (or a `Database`) as a constructor or function
  parameter. The Flutter app passes `databaseFactory` from `package:sqflite`,
  the CLI or test passes `databaseFactoryFfi` from `sqflite_common_ffi`.
* Take the database `path` as a parameter too: `getDatabasesPath()` is only
  meaningful for the sqflite plugin; on other implementations the app should
  compute a location (`path_provider`, a CLI argument, a temp dir).
  `inMemoryDatabasePath` (`':memory:'`) works everywhere.
* Type your SQL-facing functions on `DatabaseExecutor` so they work with both
  a `Database` and a `Transaction`.
* Opening returns the same instance for the same path while `singleInstance`
  is true (default); it is forced to false for in-memory databases.
* `databaseFactory` throws `StateError('databaseFactory not initialized')`
  until an implementation sets it; the setter rejects factories that are not
  sqflite implementations (`ArgumentError`) and prints a warning when
  changing an already set factory.
* `factory.sandbox(path: root)` returns a `DatabaseFactory` restricted to
  `root` (relative paths resolved under it, absolute paths must be inside,
  `getDatabasesPath()` returns `root`); it works over any implementation and
  is never nested twice.

### Statements, transactions, batches (shared semantics)

* One statement per call; bind with `?` and an argument list; values are
  `int`, `num`, `String`, `Uint8List` or `null` (`bool`, `DateTime`, `List`,
  `Map` are not supported). Results are read-only maps.
* `db.transaction((txn) async {...})` commits when the callback returns and
  rolls back (and rethrows) when it throws. Use only `txn` inside. Callbacks
  `onCreate` / `onUpgrade` / `onDowngrade` are already in a transaction.
* `db.batch()` collects operations and `commit()` runs them in one call in a
  transaction (`noResult: true`, `continueOnError: true`); a batch created
  from a `Transaction` is committed with it.
* `queryIterate` / `rawQueryIterate` (or `queryCursor` + `moveNext()` +
  `close()`) stream large results with a `bufferSize` (default 100).
* `DatabaseException` helpers: `isNoSuchTableError`, `isSyntaxError`,
  `isUniqueConstraintError`, `isNotNullConstraintError`,
  `isDuplicateColumnError`, `isOpenFailedError`, `isDatabaseClosedError`,
  `isReadOnlyError`, `getResultCode()`.

## Examples

### Shared repository, used from Flutter and from a Dart test

```dart
// package my_data (depends on sqflite_common only)
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart';

class TodoRepository {
  TodoRepository({required this.factory, required this.path});

  final DatabaseFactory factory;
  final String path;
  Future<Database>? _db;

  Future<Database> get db => _db ??= factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, _) => db.execute(
            'CREATE TABLE Todo (id INTEGER PRIMARY KEY, title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0)',
          ),
        ),
      );

  Future<int> add(String title) async =>
      (await db).insert('Todo', {'title': title});

  Future<int> count(DatabaseExecutor executor) async =>
      firstIntValue(await executor.query('Todo', columns: [sqlCountColumn])) ?? 0;

  Future<void> markAllDone() async {
    final database = await db;
    await database.transaction((txn) async {
      final pending = await count(txn);
      if (pending > 0) {
        await txn.update('Todo', {'done': 1});
      }
    });
  }

  Future<void> close() async {
    await (await db).close();
    _db = null;
  }
}
```

```dart
// test/todo_repository_test.dart (dev_dependency: sqflite_common_ffi)
// sqflite_ffi.dart re-exports the sqflite_common API (inMemoryDatabasePath...).
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import 'package:my_data/todo_repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('count and markAllDone', () async {
    final repo = TodoRepository(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await repo.add('a');
    expect(await repo.count(await repo.db), 1);
    await repo.markAllDone();
    expect(await (await repo.db).query('Todo', where: 'done = 1'), hasLength(1));
    await repo.close();
  });
}
```

In the Flutter app: `TodoRepository(factory: databaseFactory, path: join(await
getDatabasesPath(), 'todo.db'))` with `package:sqflite/sqflite.dart`.

### Using the global factory in an application

```dart
import 'package:sqflite_common/sqflite.dart';

/// The app (not a library) sets databaseFactory first, e.g.
/// `databaseFactory = databaseFactoryFfi;` from sqflite_common_ffi.
Future<int> countRows(String table) async {
  final db = await openDatabase(inMemoryDatabasePath);
  try {
    await db.execute('CREATE TABLE $table (id INTEGER PRIMARY KEY)');
    final rows = await db.rawQuery('SELECT COUNT(*) FROM $table');
    return rows.first.values.first as int;
  } finally {
    await db.close();
  }
}
```

### Sandboxed factory for tests or per-user data

```dart
import 'package:sqflite_common/sqlite_api.dart';

Future<Database> openUserDb(DatabaseFactory factory, String userRoot) async {
  final userFactory = factory.sandbox(path: userRoot);
  // Relative to userRoot; '/etc/x.db' would throw ArgumentError.
  return userFactory.openDatabase('cache.db');
}
```

### Logging every statement of any factory

```dart
import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common/sqlite_api.dart';

// ignore: experimental_member_use
DatabaseFactory withLogs(DatabaseFactory factory) => SqfliteDatabaseFactoryLogger(
      factory,
      options: SqfliteLoggerOptions(
        type: SqfliteDatabaseFactoryLoggerType.all,
        log: (event) {
          if (event is SqfliteLoggerSqlEvent) {
            print('${event.type.name}: ${event.sql} ${event.arguments ?? ''}'
                '${event.error != null ? ' error: ${event.error}' : ''}');
          } else if (event is SqfliteLoggerBatchEvent) {
            for (final op in event.operations) {
              print('batch ${op.type.name}: ${op.sql} ${op.arguments ?? ''}');
            }
          } else {
            event.dump();
          }
        },
      ),
    );
```

### Prepared commands and iteration

```dart
import 'package:sqflite_common/sqlite_api.dart';

final _byDone = SqfliteSqlCommand.query('Todo', where: 'done = ?', whereArgs: [0]);
final _insert = SqfliteSqlCommand.insert('Todo', {'title': 'x', 'done': 0});

Future<List<String>> pendingTitles(DatabaseExecutor executor) async {
  final titles = <String>[];
  await _byDone.iterate(executor, bufferSize: 50, onRow: (row) {
    titles.add(row['title'] as String);
    return true;
  });
  return titles;
}

Future<int> insertOne(DatabaseExecutor executor) => _insert.insert(executor);

Future<void> walk(DatabaseExecutor executor) => executor.queryIterate(
      'Todo',
      orderBy: 'id',
      onRow: (row) async {
        print(row);
        return row['id'] != 100; // stop at id 100
      },
    );
```

### Reading the schema version and enabling WAL

```dart
import 'package:sqflite_common/sqlite_api.dart';

Future<Database> openWithWal(DatabaseFactory factory, String path) =>
    factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.setJournalMode('WAL');
          if (await db.getVersion() == 0) {
            // New file: settings that must precede table creation.
            await db.execute('PRAGMA auto_vacuum = 2');
          }
        },
        onCreate: (db, v) => db.execute('CREATE TABLE T (id INTEGER PRIMARY KEY)'),
        onUpgrade: (db, old, _) async {
          if (old < 2) await db.execute('ALTER TABLE T ADD name TEXT');
        },
        onDowngrade: onDatabaseDowngradeDelete,
      ),
    );
```

## Common mistakes

* Depending on `package:sqflite` in a package that also runs on the Dart VM
  or in `dart test`; depend on `sqflite_common` and inject the factory.
* Importing `package:sqflite_common/sqflite.dart` in a library only for the
  types; use `sqlite_api.dart` so the library does not read the global.
* Calling `openDatabase(...)` (global) before the app set `databaseFactory`
  (`StateError: databaseFactory not initialized`).
* Assigning a hand-written `DatabaseFactory` implementation to
  `databaseFactory`: the setter only accepts sqflite implementations. Wrap
  with `SqfliteDatabaseFactoryLogger` or use `sandbox()` instead.
* Using `db` inside `db.transaction((txn) ...)`, or `db.transaction()` inside
  `onCreate` / `onUpgrade`.
* Relying on `getDatabasesPath()` from a non-plugin factory for real data;
  pass an explicit path.

## More

Implementation packages: `sqflite` (Flutter, Android/iOS/macOS),
`sqflite_common_ffi` (desktop, VM, tests), `sqflite_common_ffi_web` (web);
each ships its own skills. Docs in the repository: `doc/sqflite_iterate.md`,
`doc/sqflite_sql_command.md`, `doc/sqflite_logger.md`,
`doc/method_call_protocol.md`.
