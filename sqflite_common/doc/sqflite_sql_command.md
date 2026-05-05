# SqfliteSqlCommand

`SqfliteSqlCommand` is a class that encapsulates an SQL statement along with its arguments and command type. It allows for preparing commands that can be executed later on a `DatabaseExecutor` (either a `Database` or a `Transaction`).

## Creating commands

You can create commands using raw SQL or using builder-style factories.

### Raw factories

```dart
// Raw Query
final queryCmd = SqfliteSqlCommand.rawQuery('SELECT * FROM Test WHERE id = ?', [1]);

// Raw Insert
final insertCmd = SqfliteSqlCommand.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item']);

// Raw Update
final updateCmd = SqfliteSqlCommand.rawUpdate('UPDATE Test SET name = ? WHERE id = ?', ['new name', 1]);

// Raw Delete
final deleteCmd = SqfliteSqlCommand.rawDelete('DELETE FROM Test WHERE id = ?', [1]);

// Generic Execute
final executeCmd = SqfliteSqlCommand.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
```

### Builder factories

These factories use `SqlBuilder` internally to generate the correct SQL and arguments.

```dart
// Query builder
final queryCmd = SqfliteSqlCommand.query('Test', where: 'id = ?', whereArgs: [1]);

// Insert builder
final insertCmd = SqfliteSqlCommand.insert('Test', {'name': 'item'});

// Update builder
final updateCmd = SqfliteSqlCommand.update('Test', {'name': 'new name'}, where: 'id = ?', whereArgs: [1]);

// Delete builder
final deleteCmd = SqfliteSqlCommand.delete('Test', where: 'id = ?', whereArgs: [1]);
```

## Executing commands

You can execute a command by calling the corresponding method on the command object and passing a `DatabaseExecutor`.

```dart
// Execute a query
final rows = await queryCmd.query(db);

// Execute an insert
final id = await insertCmd.insert(db);

// Execute an update
final count = await updateCmd.update(db);

// Execute a delete
final count = await deleteCmd.delete(db);

// Generic execute
await executeCmd.execute(db);
```

### Iterative execution

You can also execute query commands iteratively using a cursor:

```dart
await queryCmd.iterate(db, onRow: (row) {
  // process row ...
  return true;
});
```

## Usage in transactions

`SqfliteSqlCommand` is particularly useful when you want to define a set of commands once and execute them within a transaction:

```dart
final commands = [
  SqfliteSqlCommand.insert('Test', {'id': 1, 'name': 'item 1'}),
  SqfliteSqlCommand.insert('Test', {'id': 2, 'name': 'item 2'}),
];

await db.transaction((txn) async {
  for (final cmd in commands) {
    await cmd.insert(txn);
  }
});
```

## Key points

- `SqfliteSqlCommand` separates the definition of a command from its execution.
- It supports all standard SQL operations: query, insert, update, delete, and execute.
- It provides both raw and builder-style creation methods.
- Execution methods are available via an extension on `SqfliteSqlCommand`.
