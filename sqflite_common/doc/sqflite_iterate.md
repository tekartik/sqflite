# Sqflite - Iterate

The `queryIterate` method lets you walk over records one at a time using a cursor. Unlike `query`, which loads all matching records into memory, `queryIterate` processes each record in the callback as the cursor advances — making it efficient for large datasets.

`queryIterate` and `rawQueryIterate` are extension methods (`SqfliteDatabaseExecutorIterateExt`) available on a `Database`
and on a `Transaction`.

## Table iterate

```dart
await db.queryIterate('Test', orderBy: 'id', onRow: (row) {
  // process row ...
  return true; // return false to stop early
});
```

The `onRow` callback receives a `Map<String, Object?>` representing the current row and must return `true` to continue or `false` to stop iteration. The callback may be `async`.

### Parameters

The parameters for `queryIterate` are identical to the `query` method, with the addition of `onRow` and an optional `bufferSize`:

- `table`: The table name.
- `distinct`: True if each row should be unique.
- `columns`: List of columns to return.
- `where`: WHERE clause (excluding the WHERE itself).
- `whereArgs`: Arguments for the WHERE clause.
- `groupBy`: GROUP BY clause.
- `having`: HAVING clause.
- `orderBy`: ORDER BY clause.
- `limit`: LIMIT clause.
- `offset`: OFFSET clause.
- `bufferSize`: Number of rows to cache internally (default is 100).
- `onRow`: The callback function for each row.

## Raw iterate

For raw SQL queries, use `rawQueryIterate` (the arguments are required, pass `null` if there are none):

```dart
await db.rawQueryIterate('SELECT * FROM Test WHERE value > ?', [10], onRow: (row) {
  // process row ...
  return true;
});
```

### Stopping early

```dart
var found = false;
await db.queryIterate('Test', onRow: (row) async {
  if (row['id'] == expectedId) {
    found = true;
    return false; // stop after the first match
  }
  return true;
});
```

### Iterating inside an existing transaction

You can call `queryIterate` or `rawQueryIterate` on a transaction object just like on a database object.

```dart
await db.transaction((txn) async {
  await txn.queryIterate('Test', onRow: (row) async {
    // process row within transaction ...
    return true;
  });
});
```

## Key points

- Return `true` to continue, `false` to stop early.
- Cursors are automatically closed when iteration completes or is stopped early.
- For simple queries that fit in memory, `query` is often simpler. Use `queryIterate` for large datasets to keep memory usage low.
- For the same thing with a cursor you manage yourself, see `queryCursor` / `rawQueryCursor` (call `cursor.close()` in a `finally`).
