# sqflite

[![pub package](https://img.shields.io/pub/v/sqflite.svg)](https://pub.dev/packages/sqflite)

SQLite plugin for [Flutter](https://flutter.dev). Supports iOS, Android and macOS.
The same API also runs on Windows, Linux, the Dart VM, unit tests and the web
through companion packages (see the table below).

* Support transactions and batches
* Automatic version management during open
* Helpers for insert/query/update/delete queries
* DB operation executed in a background thread on iOS, Android and macOS

Usage example:
* [notepad_sqflite](https://github.com/alextekartik/flutter_app_example/tree/master/notepad_sqflite): Simple flutter notepad working on iOS/Android/Windows/linux/Mac

## Getting Started

### Which package for which platform

| Platform | Package | Factory | SQLite library |
|---|---|---|---|
| Android, iOS, macOS | `sqflite` | set by the plugin, nothing to do | the one of the OS (version depends on the OS version) |
| Windows, Linux (and macOS without the plugin) | [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) (or [`sqflite_ffi`](https://pub.dev/packages/sqflite_ffi) in Flutter) | `databaseFactoryFfi` after `sqfliteFfiInit()` | bundled by `package:sqlite3` build hooks, nothing to install |
| Web (experimental, see [limits](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/web_support.md#limits)) | [`sqflite_common_ffi_web`](https://pub.dev/packages/sqflite_common_ffi_web) | `databaseFactoryFfiWeb` | `sqlite3.wasm` and a worker, copied in `web/` by `dart run sqflite_common_ffi_web:setup` |
| Unit tests (`flutter test`, Dart VM) | `sqflite_common_ffi` (dev dependency) | `databaseFactoryFfi` (`databaseFactoryFfiNoIsolate` in `testWidgets`) | bundled |

Every package uses the same API (`openDatabase`, `Database`, `Transaction`,
`Batch`...). The global `openDatabase()` uses the global `databaseFactory`:
`sqflite` sets it on Android, iOS and macOS. On other platforms, set it once in
`main()` before opening a database, for example `databaseFactory = databaseFactoryFfi;`.
Details: [desktop](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/desktop_support.md),
[web](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/web_support.md),
[unit tests](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/testing.md).

### Add the dependency

```bash
flutter pub add sqflite path
```

### Open, read, write, close

A database is a file identified by a path. `getDatabasesPath()` gives the
default folder: `/data/data/<package>/databases` on Android, the Documents
directory on iOS and macOS. A relative path is relative to this folder.
Its parent directory is created when opening.

Open the database once (at startup or on first use) with a `version` and an
`onCreate` callback that creates the tables, then keep the `Database` object.

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the database. Call it once and keep the result.
Future<Database> openAppDatabase() async {
  // Android: /data/data/<package>/databases, iOS and macOS: Documents.
  var path = join(await getDatabasesPath(), 'app.db');
  return openDatabase(
    path,
    // Increment the version (and handle it in onUpgrade) on schema changes.
    version: 1,
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE Todo (id INTEGER PRIMARY KEY, title TEXT NOT NULL, '
        'done INTEGER NOT NULL)',
      );
    },
  );
}

Future<void> todoDemo() async {
  var db = await openAppDatabase();

  // Create
  var id = await db.insert('Todo', {'title': 'Buy milk', 'done': 0});
  // Read
  var rows = await db.query('Todo', where: 'done = ?', whereArgs: [0]);
  print(rows); // [{id: 1, title: Buy milk, done: 0}]
  // Update
  await db.update('Todo', {'done': 1}, where: 'id = ?', whereArgs: [id]);
  // Delete
  await db.delete('Todo', where: 'id = ?', whereArgs: [id]);

  // Optional: many apps keep the database open until they exit.
  await db.close();
}
```

To change the schema later, increment `version` and add an `onUpgrade` callback,
see [opening a database](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/opening_db.md)
and the [migration example](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/migration_example.md).

### One code base for mobile, desktop and web

Add `sqflite_common_ffi`, `sqflite_common_ffi_web` and `path_provider`, run
`dart run sqflite_common_ffi_web:setup` once for the web, then select the factory
in `main()`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Requires `dart run sqflite_common_ffi_web:setup` (files in web/).
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // The ffi default folder is relative to the current directory,
    // use the application support directory instead.
    var dir = await getApplicationSupportDirectory();
    await databaseFactory.setDatabasesPath(join(dir.path, 'databases'));
  }
  // Android, iOS and macOS: the sqflite plugin factory is already set.

  runApp(const MyApp());
}
```

The rest of the code (`openDatabase`, queries) stays the same. On the web the
path is only a name in the browser storage (IndexedDB).

## Common pitfalls

* **Open the database once.** Keep the `Database` (or the `Future<Database>`)
  in a single place. With the default `singleInstance: true`, opening the same
  path again returns the same instance and ignores the new callbacks; closing it
  closes it for every caller.
* **Await every call.** A call that is not awaited in `onCreate` does not make
  `openDatabase` fail: the version is saved with a partial schema and the error
  is uncaught.
* **Use `txn`, not `db`, in a transaction.** Calling `db` inside
  `db.transaction((txn) async {...})` deadlocks (a warning is printed after 10
  seconds). `onCreate`, `onUpgrade` and `onDowngrade` already run in a
  transaction: use their `db` directly.
* **A schema change needs a version bump.** `onCreate` only runs when the
  database does not exist. Increment `version` and handle the change in
  `onUpgrade` for existing installs.
* **Supported types are `int`, `num`, `String`, `Uint8List` and `null`.** Store
  a `bool` as `0`/`1` and a `DateTime` as an `int` (`millisecondsSinceEpoch`) or
  a `String` (`toIso8601String()`). A blob must be a `Uint8List`, not a
  `List<int>`. See [supported types](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/supported_types.md).
* **Pass values as arguments.** Use `?` with `whereArgs` or the `arguments` of
  the raw methods, never string interpolation (`'... WHERE name = $name'`), which
  breaks on quotes and allows SQL injection. In SQL, string literals use single
  quotes (`'text'`); double quotes are for table and column names.
* **One statement per call.** `execute('CREATE TABLE A ...; CREATE TABLE B ...')`
  is not portable, use two calls or a batch.
* **A batch does nothing until `await batch.commit()`.** Inside a transaction,
  create it with `txn.batch()`.
* **Query results are read-only.** Copy a row with `Map<String, Object?>.from(row)`
  before modifying it.
* **Set the factory on desktop, web and in tests.** Otherwise `openDatabase`
  throws `databaseFactory not initialized`. On the web, also run
  `dart run sqflite_common_ffi_web:setup`.
* **Delete with `deleteDatabase(path)`**, not `File(path).delete()`, so that an
  open instance is closed first.

## Usage example

Import `sqflite.dart`

```dart
import 'package:sqflite/sqflite.dart';
```

Opening a database, its callbacks and migrations:
* See [more information on opening a database](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/opening_db.md).
* Full [migration example](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/migration_example.md)

### Raw SQL queries

Demo code to perform Raw SQL queries

```dart
// Get a location using getDatabasesPath
var databasesPath = await getDatabasesPath();
var path = join(databasesPath, 'demo.db');

// Delete the database
await deleteDatabase(path);

// open the database
var database = await openDatabase(
  path,
  version: 1,
  onCreate: (Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
      'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)',
    );
  },
);

// Insert some records in a transaction
await database.transaction((txn) async {
  // String literals use single quotes in SQL
  var id1 = await txn.rawInsert(
    "INSERT INTO Test(name, value, num) VALUES('some name', 1234, 456.789)",
  );
  print('inserted1: $id1');
  // Prefer arguments (?) to put values in a statement
  var id2 = await txn.rawInsert(
    'INSERT INTO Test(name, value, num) VALUES(?, ?, ?)',
    ['another name', 12345678, 3.1416],
  );
  print('inserted2: $id2');
});

// Update some record
var count = await database.rawUpdate(
  'UPDATE Test SET name = ?, value = ? WHERE name = ?',
  ['updated name', 9876, 'some name'],
);
print('updated: $count');

// Get the records
var list = await database.rawQuery('SELECT * FROM Test');
print(list);
// [{id: 1, name: updated name, value: 9876, num: 456.789},
//  {id: 2, name: another name, value: 12345678, num: 3.1416}]

// Count the records
count =
    Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM Test'),
    ) ??
    0;
assert(count == 2);

// Delete a record
count = await database.rawDelete('DELETE FROM Test WHERE name = ?', [
  'another name',
]);
assert(count == 1);

// Close the database
await database.close();
```

Basic information on SQL [here](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/sql.md).

### SQL helpers

Example using the helpers

```dart
const String tableTodo = 'todo';
const String columnId = '_id';
const String columnTitle = 'title';
const String columnDone = 'done';

class Todo {
  Todo({this.id, required this.title, this.done = false});

  Todo.fromMap(Map<String, Object?> map)
    : id = map[columnId] as int?,
      title = map[columnTitle] as String,
      done = map[columnDone] == 1;

  int? id;
  String title;
  bool done;

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      columnTitle: title,
      // bool is not a SQLite type, store 0 or 1
      columnDone: done ? 1 : 0,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }
}

class TodoProvider {
  late Database db;

  Future<void> open(String path) async {
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
create table $tableTodo (
  $columnId integer primary key autoincrement,
  $columnTitle text not null,
  $columnDone integer not null)
''');
      },
    );
  }

  Future<Todo> insert(Todo todo) async {
    todo.id = await db.insert(tableTodo, todo.toMap());
    return todo;
  }

  Future<Todo?> getTodo(int id) async {
    var maps = await db.query(
      tableTodo,
      columns: [columnId, columnDone, columnTitle],
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Todo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableTodo, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(Todo todo) async {
    return await db.update(
      tableTodo,
      todo.toMap(),
      where: '$columnId = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> close() async => db.close();
}
```

### Read results

Assuming the following read results:

```dart
List<Map<String, Object?>> records = await db.query('my_table');
```

Resulting map items are read-only

```dart
// get the first record
Map<String, Object?> mapRead = records.first;
// Update it in memory...this will throw an exception
mapRead['my_column'] = 1;
// Crash... `mapRead` is read-only
```

You need to create a new map if you want to modify it in memory:

```dart
// get the first record
Map<String, Object?> map = Map<String, Object?>.from(mapRead);
// Update it in memory now
map['my_column'] = 1;
```

### Transaction

Don't use the database but only use the Transaction object in a transaction
to access the database. Keep in mind that the callbacks ```onCreate``` ```onUpgrade``` ```onDowngrade``` are already internally wrapped in a transaction, so there is no need to wrap your statements in a transaction within those callbacks.

```dart
await database.transaction((txn) async {
  // Ok
  await txn.execute('CREATE TABLE Test1 (id INTEGER PRIMARY KEY)');
  
  // DON'T  use the database object in a transaction
  // this will deadlock!
  await database.execute('CREATE TABLE Test2 (id INTEGER PRIMARY KEY)');
});
```

A transaction is committed if the callback does not throw an error. If an error is thrown,
the transaction is cancelled and the same error is re-thrown. So to rollback a transaction one way is to throw an exception.

```dart
try {
   await database.transaction((txn) async {
      await txn.update('TABLE', {'foo': 'bar'});
   });
   // No error, the transaction is committed
} catch (e) {
   // this reliably catch if there is a key conflict
   // We know that the transaction is rolled back.
}

try {
  await database.transaction((txn) async {
    // ...
    // cancel the transaction (any error will do)
    throw StateError('cancel transaction');
  });
} catch (e) {
  // We know that the transaction is rolled back.
}
```
You can however catch the exception inside the transaction and not rethrow it to commit the transaction. Only the failed statement will not be executed.

```dart
await database.transaction((txn) async {
  // ...
  try {
    await txn.update('TABLE', {'foo': 'bar'});
  } catch (e) {
    // The failed update is not applied, the transaction goes on.
  }
  // ...
  // The transaction will be committed
});
```
### Batch support

To avoid ping-pong between dart and native code, you can use `Batch`:

```dart
var batch = db.batch();
batch.insert('Test', {'name': 'item'});
batch.update('Test', {'name': 'new_item'}, where: 'name = ?', whereArgs: ['item']);
batch.delete('Test', where: 'name = ?', whereArgs: ['item']);
var results = await batch.commit();
```

Getting the result for each operation has a cost (id for insertion and number of changes for
update and delete), especially on Android where an extra SQL request is executed.
If you don't care about the result and worry about performance in big batches, you can use

```dart
await batch.commit(noResult: true);
```

Warning, during a transaction, the batch won't be committed until the transaction is committed

```dart
await database.transaction((txn) async {
  var batch = txn.batch();
  
  // ...
  
  // commit but the actual commit will happen when the transaction is committed
  // however the data is available in this transaction
  await batch.commit();
  
  //  ...
});
```

By default a batch stops as soon as it encounters an error (which typically reverts the uncommitted changes). You 
can ignore errors so that every successful operation is ran and committed even if one operation fails:

```dart
await batch.commit(continueOnError: true);
```

## Table and column names

In general it is better to avoid using SQLite keywords for entity names. If any of the following
name is used:

    "add","all","alter","and","as","autoincrement","between","case","check","collate","commit","constraint","create","default","deferrable","delete","distinct","drop","else","escape","except","exists","foreign","from","group","having","if","in","index","insert","intersect","into","is","isnull","join","limit","not","notnull","null","on","or","order","primary","references","select","set","table","then","to","transaction","union","unique","update","using","values","when","where"
    
the helper will *escape* the name i.e.

```dart
db.query('table')
```
will be equivalent to manually adding double-quote around the table name (confusingly here named `table`)

```dart
db.rawQuery('SELECT * FROM "table"');
```

However in any other raw statement (including `orderBy`, `where`, `groupBy`), make sure to escape the name
properly using double quote. For example see below where the column name `group` is not escaped in the columns
argument, but is escaped in the `where` argument.

```dart
db.query('table', columns: ['group'], where: '"group" = ?', whereArgs: ['my_group']);
```

## Supported SQLite types

| SQLite type | Dart type |
|---|---|
| `INTEGER` | `int` (from -2^63 to 2^63 - 1) |
| `REAL` | `num` |
| `TEXT` | `String` |
| `BLOB` | `Uint8List` |

`DateTime` and `bool` are not SQLite types: store a `DateTime` as an `int`
(`millisecondsSinceEpoch`) or a `String` (`toIso8601String()`), a `bool` as
`INTEGER` 0 or 1. See [supported types](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/supported_types.md)
and the [SQLite documentation](https://www.sqlite.org/datatype3.html).

## Current issues

* Due to the way transaction works in SQLite (threads), concurrent read and write transaction are not supported. 
All calls are currently synchronized and transactions block are exclusive. I thought that a basic way to support 
concurrent access is to open a database multiple times but it only works on iOS as Android reuses the same database object.
I also thought a native thread could be a potential future solution however on android accessing the database in another
thread is blocked while in a transaction...

## More

* [How to](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/how_to.md) guide
* [Notes about Desktop support](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/desktop_support.md)
* [Notes about Encryption support](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/encryption_support.md)
* [Notes about Web support](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/web_support.md)
* [Unit testing](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/testing.md)
* [Notes about SQLite versions](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/version.md) as some features may not be available depending on the SQLite version.
* [Troubleshooting](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/troubleshooting.md)
