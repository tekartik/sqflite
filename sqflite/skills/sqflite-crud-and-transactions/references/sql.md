# sqflite SQL reference

## Supported value types

| SQLite type | Dart type in values / results | Notes |
|-------------|-------------------------------|-------|
| `INTEGER`   | `int`                         | -2^63 to 2^63 - 1 |
| `REAL`      | `num` (`double` on read)      | |
| `TEXT`      | `String`                      | `TIMESTAMP` columns come back as `String` |
| `BLOB`      | `Uint8List`                   | keep rows well under 1 MB |
| `NULL`      | `null`                        | in `whereArgs` use `IS NULL` in SQL instead |

Not supported as values: `bool` (store 0/1), `DateTime` (store
`millisecondsSinceEpoch` or ISO 8601 text), `List`, `Map` (store JSON text),
`BigInt` (web only). Android binds arguments as strings, so `SELECT ?1` may
return `'3'` instead of `3`; arithmetic and comparisons still work.

## Reserved names

`escapeName(name)` (`package:sqflite/sql.dart`, also exported by
`package:sqflite_common/sql.dart`) wraps a name in double quotes when it is
one of the SQLite keywords below, `unescapeName` reverses it. The helpers
(`insert`, `query`, `update`, `delete`, `columns`) call it for table and
column names; raw SQL and the `where` / `orderBy` / `groupBy` / `having`
fragments do not.

```
abort action add after all alter always analyze and as asc attach
autoincrement before begin between by cascade case cast check collate column
commit conflict constraint create cross current current_date current_time
current_timestamp database default deferrable deferred delete desc detach
distinct do drop each else end escape except exclude exclusive exists explain
fail filter first following for foreign from full generated glob group groups
having if ignore immediate in index indexed initially inner insert instead
intersect into is isnull join key last left like limit match materialized
natural no not nothing notnull null nulls of offset on or order others outer
over partition plan pragma preceding primary query raise range recursive
references regexp reindex release rename replace restrict returning right
rollback row rows savepoint select set table temp temporary then ties to
transaction trigger unbounded union unique update using vacuum values view
virtual when where window with without
```

```dart
import 'package:sqflite/sql.dart';

// Column named "group": escaped by the helper in columns, manual in where.
final rows = await db.query(
  'Item',
  columns: ['group'],
  where: '${escapeName('group')} = ?',
  whereArgs: ['my_group'],
);
```

## Query helper to SQL

`query(table, distinct, columns, where, whereArgs, groupBy, having, orderBy,
limit, offset)` produces:

```
SELECT [DISTINCT] col1, col2 | * FROM table
  [WHERE where] [GROUP BY groupBy] [HAVING having] [ORDER BY orderBy]
  [LIMIT limit|-1] [OFFSET offset]
```

`offset` without `limit` emits `LIMIT -1`. `insert(table, values)` emits
`INSERT [OR REPLACE|IGNORE|...] INTO table (c1, c2) VALUES (?, ?)`; a `null`
value is inlined as `NULL`. An empty `values` map needs `nullColumnHack`
(the name of a nullable column). `update(table, values, where, whereArgs)`
emits `UPDATE [OR ...] table SET c1 = ?, c2 = NULL [WHERE where]` with the
where arguments appended after the value arguments.

## SqfliteSqlCommand

Exported by `package:sqflite/sqlite_api.dart`. Builds `sql` + `arguments`
once, executes later on any `DatabaseExecutor` (extension
`SqfliteSqlCommandExecutorExt`).

```dart
final byId = SqfliteSqlCommand.query('Todo', where: 'id = ?', whereArgs: [1]);
final add = SqfliteSqlCommand.insert('Todo', {'title': 'x', 'done': 0});
final rename = SqfliteSqlCommand.update('Todo', {'title': 'y'},
    where: 'id = ?', whereArgs: [1]);
final drop = SqfliteSqlCommand.delete('Todo', where: 'id = ?', whereArgs: [1]);
final raw = SqfliteSqlCommand.rawQuery('SELECT * FROM Todo WHERE done = ?', [1]);
final ddl = SqfliteSqlCommand.execute('CREATE INDEX i ON Todo(title)');

await db.transaction((txn) async {
  final id = await add.insert(txn);
  final rows = await byId.query(txn);
  await rename.update(txn);
  await drop.delete(txn);
  await ddl.execute(txn);
  await raw.iterate(txn, onRow: (row) => true);
});
```

`SqliteSqlCommandType` (`execute`, `insert`, `update`, `delete`, `query`) is
the `type` of a command and of the logger events.

## Schema recipes

```dart
// All tables, indexes, triggers and their CREATE statements.
final schema = await db.query('sqlite_master');

// Table names.
final names = (await db.query('sqlite_master',
        columns: ['name'], where: 'type = ?', whereArgs: ['table']))
    .map((row) => row['name'] as String)
    .toList()
  ..sort();

// Column info.
final columns = await db.rawQuery('PRAGMA table_info(Todo)');

// SQLite version of the platform (features such as UPSERT, JSON1,
// RETURNING depend on it).
final version = (await db.rawQuery('SELECT sqlite_version()')).first.values.first;
```

## DatabaseException helpers

| Method | Matches |
|--------|---------|
| `isNoSuchTableError([table])` | `no such table: <table>` |
| `isDuplicateColumnError([column])` | `duplicate column name: <column>` |
| `isSyntaxError()` | `syntax error` |
| `isUniqueConstraintError([field])` | `UNIQUE constraint failed: <table.field>` |
| `isNotNullConstraintError([field])` | `NOT NULL constraint failed: <table.field>` |
| `isOpenFailedError()` | `open_failed` |
| `isDatabaseClosedError()` | `database_closed` |
| `isReadOnlyError()` | `readonly` |
| `getResultCode()` | SQLite result code parsed from the message (extended on Android/ffi, primary on iOS) |
| `result` | raw platform error payload |

`toString()` includes the failing SQL and truncated arguments.
