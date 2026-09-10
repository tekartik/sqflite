---
name: sqflite-crud-and-transactions
description: >-
  Use when reading or writing rows with package:sqflite: execute, insert,
  query, update, delete and their raw variants (rawInsert, rawQuery,
  rawUpdate, rawDelete), where/whereArgs binding, ConflictAlgorithm (upsert
  with replace/ignore), transaction (txn) and rollback, Batch commit/apply,
  queryCursor/queryIterate for large results, SqfliteSqlCommand, supported
  column types (int, num, String, Uint8List, no bool/DateTime), reserved-name
  escaping (escapeName), Sqflite.firstIntValue for COUNT(*), and
  DatabaseException handling (isUniqueConstraintError, isNoSuchTableError).
---

# sqflite: CRUD, transactions and batches

Every SQL call goes through a `DatabaseExecutor`, which is either the
`Database` or the `Transaction` passed to `transaction()`. Helpers (`insert`,
`query`, `update`, `delete`) build the SQL for you; raw methods take a SQL
string plus a positional `?` argument list. Each call runs exactly one
statement and is serialized on the database.

```dart
import 'package:sqflite/sqflite.dart';

Future<int> addTodo(Database db, String title) =>
    db.insert('Todo', {'title': title, 'done': 0});

Future<List<Map<String, Object?>>> pendingTodos(Database db) =>
    db.query('Todo', where: 'done = ?', whereArgs: [0], orderBy: 'id');
```

## Guidelines

### Statements and arguments

* `execute(sql, [args])` is for DDL and statements without a result (`CREATE
  TABLE`, `PRAGMA`, `DROP`). One statement per call; `;`-separated strings
  are rejected.
* `insert(table, values, {nullColumnHack, conflictAlgorithm})` returns the
  inserted row id (`rawInsert` too). `update(...)` / `delete(...)` and
  `rawUpdate` / `rawDelete` return the number of rows changed. `query(...)`
  / `rawQuery(...)` return `List<Map<String, Object?>>`.
* Always bind values with `?` and an argument list (`whereArgs` or the raw
  `arguments`). Never interpolate user data into the SQL string. `?NNN`
  positional references (`?1`, `?2`) are supported.
* `IN (?)` does not accept a list argument. Generate one `?` per value:
  `'id IN (${List.filled(ids.length, '?').join(',')})'` with `whereArgs: ids`.
* Test for null with `IS NULL` / `IS NOT NULL` in the SQL, not with `= ?`
  and a `null` argument (`whereArgs` values must be non-null; raw `arguments`
  may contain `null`).
* `query` clauses (`where`, `orderBy`, `groupBy`, `having`, `columns`,
  `limit`, `offset`, `distinct`) are raw SQL fragments without the keyword:
  `orderBy: 'name COLLATE NOCASE DESC'`, `where: 'a = ? AND b > ?'`.
  `having` requires `groupBy`.
* Column values must be `int`, `num` (`REAL`), `String` (`TEXT`),
  `Uint8List` (`BLOB`) or `null`. `bool` is stored as `INTEGER` 0/1;
  `DateTime` as `millisecondsSinceEpoch` (`INTEGER`) or `toIso8601String()`
  (`TEXT`); nested maps/lists as a JSON `TEXT`. Passing another type prints a
  warning in debug mode and will throw in the future.
* Table and column names that are SQLite keywords (`group`, `order`,
  `table`, `values`, ...) are escaped automatically by the helpers
  (`insert`, `query`, `update`, `delete` and the `columns` list) but not
  inside `where`, `orderBy` or raw SQL: write `'"group" = ?'` there, or call
  `escapeName(name)` from `package:sqflite/sql.dart`. Prefer names that are
  not keywords.
* Query results are read-only: copy with `Map<String, Object?>.from(row)` /
  `List.of(rows)` before mutating. A row is a `Map<String, Object?>` keyed by
  column name (or alias); a `COUNT(*)` column is keyed `'COUNT(*)'`.
* `Sqflite.firstIntValue(rows)` (or `firstIntValue` from
  `package:sqflite/utils/utils.dart`) reads the first value of the first row
  as an `int?`, the idiom for `SELECT COUNT(*)`. `Sqflite.hex(bytes)` builds
  the argument for `'hex(blob_column) = ?'`.
* `ConflictAlgorithm` (on `insert` and `update`): `replace` deletes the
  conflicting row(s) and inserts (upsert by primary/unique key), `ignore`
  skips the row without error (`insert` then returns 0), `abort` (default),
  `fail`, `rollback`. Alternatively catch `DatabaseException` and check
  `isUniqueConstraintError()`.

### Transactions

* `db.transaction((txn) async {...})` begins `BEGIN IMMEDIATE` (`exclusive:
  true` for `BEGIN EXCLUSIVE`), runs the callback, then `COMMIT`; if the
  callback throws it runs `ROLLBACK` and rethrows. Return a value from the
  callback to get it from `transaction<T>`.
* Inside the callback use only `txn`. Any call on `db` (or on another
  `Database` object for the same file) waits for the transaction and
  deadlocks; after 10 s sqflite prints "Warning database has been locked".
* A caught exception inside the callback does not roll back: the transaction
  commits with the successful statements. Rethrow (or throw your own error)
  to cancel.
* Transactions are exclusive and serialized: no concurrent read while one is
  running. Keep them short and never await UI or network inside.
* `db.readTransaction(...)` is experimental; on sqflite it is a normal
  transaction that is always rolled back. Use `transaction` unless you are on
  an implementation that documents it.

### Batches

* `final batch = db.batch(); batch.insert(...); batch.update(...);
  final results = await batch.commit();` sends all operations in one native
  call inside a transaction managed by sqflite. `results` holds one entry per
  operation (insert id, change count, query rows) in order.
* `commit(noResult: true)` skips result collection (faster for large
  imports). `commit(continueOnError: true)` runs every operation and puts a
  `DatabaseException` in the result slot of the failed ones instead of
  stopping.
* `txn.batch()` inside a transaction is committed with that transaction:
  `await batch.commit()` is still required but the data only lands on
  `COMMIT` of the enclosing transaction. Inside `onCreate` / `onUpgrade` the
  same applies.
* `batch.apply()` runs the statements without a transaction; use `commit()`
  unless you manage `BEGIN`/`COMMIT` yourself.
* A batch is a list of statements decided up front; if a later statement
  depends on a query result, use a `transaction` instead.

### Large results

* `db.query(...)` loads every row in memory. For big tables use
  `queryCursor` / `rawQueryCursor` (`bufferSize`, default 100 rows) and
  `while (await cursor.moveNext()) { cursor.current }` in a `try/finally`
  that calls `cursor.close()`, or the `queryIterate` / `rawQueryIterate`
  extensions (`SqfliteDatabaseExecutorIterateExt`) whose `onRow` callback
  returns `false` to stop and which close the cursor for you.
* Rows over roughly 1 MB fail on Android (`CursorWindow`); store big blobs in
  files and keep a reference in the database.
* `SqfliteSqlCommand.query/insert/update/delete/rawQuery/...` builds a
  reusable command (`sql` + `arguments`); run it later with
  `cmd.query(executor)`, `cmd.insert(executor)`, `cmd.iterate(executor,
  onRow: ...)`.

### Errors

* Every native error surfaces as `DatabaseException`. Use its helpers rather
  than parsing messages: `isNoSuchTableError([table])`,
  `isDuplicateColumnError([column])`, `isSyntaxError()`,
  `isUniqueConstraintError([field])`, `isNotNullConstraintError([field])`,
  `isOpenFailedError()`, `isDatabaseClosedError()`, `isReadOnlyError()`,
  `getResultCode()` (extended code on Android, primary code on iOS).
* Errors thrown by `openDatabase` are usually thrown by your own callbacks;
  read the message, it contains the failing SQL and arguments.

## Examples

### A DAO with the helpers

```dart
import 'package:sqflite/sqflite.dart';

const tableTodo = 'Todo';
const columnId = 'id';
const columnTitle = 'title';
const columnDone = 'done';

class Todo {
  Todo({this.id, required this.title, this.done = false});

  int? id;
  String title;
  bool done;

  Map<String, Object?> toMap() => {
        if (id != null) columnId: id,
        columnTitle: title,
        columnDone: done ? 1 : 0,
      };

  factory Todo.fromMap(Map<String, Object?> map) => Todo(
        id: map[columnId] as int?,
        title: map[columnTitle] as String,
        done: map[columnDone] == 1,
      );
}

class TodoDao {
  TodoDao(this.db);

  final Database db;

  Future<Todo> insert(Todo todo) async {
    todo.id = await db.insert(tableTodo, todo.toMap());
    return todo;
  }

  Future<Todo?> get(int id) async {
    final rows = await db.query(
      tableTodo,
      columns: [columnId, columnTitle, columnDone],
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Todo.fromMap(rows.first);
  }

  Future<List<Todo>> search(String prefix) async {
    final rows = await db.query(
      tableTodo,
      where: '$columnTitle LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: '$columnTitle COLLATE NOCASE',
    );
    return rows.map(Todo.fromMap).toList();
  }

  Future<int> update(Todo todo) => db.update(
        tableTodo,
        todo.toMap(),
        where: '$columnId = ?',
        whereArgs: [todo.id],
      );

  Future<int> delete(int id) =>
      db.delete(tableTodo, where: '$columnId = ?', whereArgs: [id]);

  Future<int> count() async =>
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableTodo'),
      ) ??
      0;
}
```

### Raw SQL with bound arguments

```dart
import 'package:sqflite/sqflite.dart';

Future<void> rawDemo(Database db) async {
  final id = await db.rawInsert(
    'INSERT INTO Todo(title, done) VALUES (?, ?)',
    ['Buy milk', 0],
  );
  final updated = await db.rawUpdate(
    'UPDATE Todo SET done = ? WHERE id = ?',
    [1, id],
  );
  final ids = [1, 2, 3];
  final rows = await db.rawQuery(
    'SELECT * FROM Todo WHERE id IN (${List.filled(ids.length, '?').join(',')})',
    ids,
  );
  final deleted = await db.rawDelete('DELETE FROM Todo WHERE done = ?', [1]);
  print('$updated $deleted ${rows.length}');
}
```

### Transaction: read, decide, write atomically

```dart
import 'package:sqflite/sqflite.dart';

Future<void> transfer(Database db, int from, int to, int amount) async {
  await db.transaction((txn) async {
    // Only txn is used inside the callback, never db.
    final rows = await txn.query(
      'Account',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [from],
    );
    final balance = rows.first['balance'] as int;
    if (balance < amount) {
      // Throwing rolls back everything done in this transaction.
      throw StateError('insufficient funds');
    }
    await txn.rawUpdate(
      'UPDATE Account SET balance = balance - ? WHERE id = ?',
      [amount, from],
    );
    await txn.rawUpdate(
      'UPDATE Account SET balance = balance + ? WHERE id = ?',
      [amount, to],
    );
  });
}
```

### Upsert with ConflictAlgorithm or by catching the constraint error

```dart
import 'package:sqflite/sqflite.dart';

/// Table Product(id TEXT PRIMARY KEY, title TEXT)
Future<void> upsertProduct(Database db, String id, String title) =>
    db.insert(
      'Product',
      {'id': id, 'title': title},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

Future<void> insertOrUpdate(Database db, String id, String title) async {
  try {
    await db.insert('Product', {'id': id, 'title': title});
  } on DatabaseException catch (e) {
    if (!e.isUniqueConstraintError()) rethrow;
    await db.update(
      'Product',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

### Batch import

```dart
import 'package:sqflite/sqflite.dart';

Future<void> importProducts(Database db, List<Map<String, Object?>> items) async {
  final batch = db.batch();
  batch.delete('Product');
  for (final item in items) {
    batch.insert('Product', item, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  // One native round trip, in a transaction; no per-operation results needed.
  await batch.commit(noResult: true);
}

Future<List<Object?>> batchWithResults(Database db) async {
  final batch = db.batch();
  batch.insert('Product', {'id': 'p1', 'title': 'One'});
  batch.update('Product', {'title': 'Uno'}, where: 'id = ?', whereArgs: ['p1']);
  batch.query('Product', where: 'id = ?', whereArgs: ['p1']);
  // [insertedId, updateCount, List<Map<String, Object?>>]
  return batch.commit();
}
```

### Streaming a large table with a cursor

```dart
import 'package:sqflite/sqflite.dart';

Future<int> sumSizes(Database db) async {
  var total = 0;
  await db.queryIterate(
    'File',
    columns: ['size'],
    orderBy: 'id',
    bufferSize: 200,
    onRow: (row) {
      total += row['size'] as int;
      return true; // false stops early; the cursor is closed either way
    },
  );
  return total;
}

Future<void> manualCursor(Database db) async {
  final cursor = await db.rawQueryCursor('SELECT * FROM File', null, bufferSize: 50);
  try {
    while (await cursor.moveNext()) {
      print(cursor.current['name']);
    }
  } finally {
    await cursor.close();
  }
}
```

### Schema introspection and errors

```dart
import 'package:sqflite/sqflite.dart';

Future<bool> tableExists(DatabaseExecutor db, String table) async {
  final count = Sqflite.firstIntValue(await db.query(
    'sqlite_master',
    columns: ['COUNT(*)'],
    where: 'type = ? AND name = ?',
    whereArgs: ['table', table],
  ));
  return (count ?? 0) > 0;
}

Future<List<Map<String, Object?>>> safeQuery(Database db) async {
  try {
    return await db.query('Missing');
  } on DatabaseException catch (e) {
    if (e.isNoSuchTableError('Missing')) return const [];
    rethrow;
  }
}
```

## Common mistakes

* Using `db` instead of `txn` inside `transaction()`: deadlock, then the
  10 s "database has been locked" warning.
* `whereArgs: [list]` for an `IN` clause, or `'col = ?'` with `[null]`.
* Storing `bool`, `DateTime`, `List` or `Map` values directly.
* Mutating a row map returned by `query` (read-only) instead of copying it.
* Expecting `batch.commit()` in a transaction to be visible outside before the
  transaction commits, or expecting `apply()` to be atomic.
* Building `'... WHERE name = "$name"'` by interpolation instead of binding.
* Assuming UPSERT syntax (`ON CONFLICT DO UPDATE`) or JSON functions exist:
  they depend on the OS SQLite version (`SELECT sqlite_version()`);
  `ConflictAlgorithm.replace` or a transaction works everywhere.

## More

See [references/sql.md](references/sql.md) for the escaped keyword list, the
supported-type table, `escapeName`/`unescapeName`, `SqfliteSqlCommand`
factories and the `sqlite_master` recipes. Opening and migrating: see the
`sqflite-open-database` skill.
