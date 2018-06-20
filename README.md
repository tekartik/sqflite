# sqflite

SQLite plugin for [Flutter](https://flutter.io).
Supports both iOS and Android.

* Support transactions and batches
* Automatic version managment during open
* Helpers for insert/query/update/delete queries
* DB operation executed in a background thread on iOS and Android

## Getting Started

In your flutter project add the dependency:

```yml
dependencies:
  ...
  sqflite: any
```

For help getting started with Flutter, view the online
[documentation](https://flutter.io/).

## Usage example

Import `sqflite.dart`

```dart
import 'package:sqflite/sqflite.dart';
```

### Raw SQL queries
    
Demo code to perform Raw SQL queries

```dart
// Get a location using getDatabasesPath
var databasesPath = await getDatabasesPath();
String path = join(databasesPath, "demo.db");

// Delete the database
await deleteDatabase(path);

// open the database
Database database = await openDatabase(path, version: 1,
    onCreate: (Database db, int version) async {
  // When creating the db, create the table
  await db.execute(
      "CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)");
});

// Insert some records in a transaction
await database.transaction((txn) async {
  int id1 = await txn.rawInsert(
      'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)');
  print("inserted1: $id1");
  int id2 = await txn.rawInsert(
      'INSERT INTO Test(name, value, num) VALUES(?, ?, ?)',
      ["another name", 12345678, 3.1416]);
  print("inserted2: $id2");
});

// Update some record
int count = await database.rawUpdate(
    'UPDATE Test SET name = ?, VALUE = ? WHERE name = ?',
    ["updated name", "9876", "some name"]);
print("updated: $count");

// Get the records
List<Map> list = await database.rawQuery('SELECT * FROM Test');
List<Map> expectedList = [
  {"name": "updated name", "id": 1, "value": 9876, "num": 456.789},
  {"name": "another name", "id": 2, "value": 12345678, "num": 3.1416}
];
print(list);
print(expectedList);
assert(const DeepCollectionEquality().equals(list, expectedList));

// Count the records
count = Sqflite
    .firstIntValue(await database.rawQuery("SELECT COUNT(*) FROM Test"));
assert(count == 2);

// Delete a record
count = await database
    .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
assert(count == 1);

// Close the database
await database.close();
```

### SQL helpers

Example using the helpers

```dart
final String tableTodo = "todo";
final String columnId = "_id";
final String columnTitle = "title";
final String columnDone = "done";

class Todo {
  int id;
  String title;
  bool done;

  Map toMap() {
    Map map = {columnTitle: title, columnDone: done == true ? 1 : 0};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  Todo();

  Todo.fromMap(Map map) {
    id = map[columnId];
    title = map[columnTitle];
    done = map[columnDone] == 1;
  }
}

class TodoProvider {
  Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableTodo ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text not null,
  $columnDone integer not null)
''');
    });
  }

  Future<Todo> insert(Todo todo) async {
    todo.id = await db.insert(tableTodo, todo.toMap());
    return todo;
  }

  Future<Todo> getTodo(int id) async {
    List<Map> maps = await db.query(tableTodo,
        columns: [columnId, columnDone, columnTitle],
        where: "$columnId = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return new Todo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableTodo, where: "$columnId = ?", whereArgs: [id]);
  }

  Future<int> update(Todo todo) async {
    return await db.update(tableTodo, todo.toMap(),
        where: "$columnId = ?", whereArgs: [todo.id]);
  }

  Future close() async => db.close();
}
```

### Transaction

Don't use the database but only use the Transaction object in a transaction
to access the database

```dart
await database.transaction((txn) async {
  // Ok
  await txn.execute("CREATE TABLE Test1 (id INTEGER PRIMARY KEY)");
  
  // DON'T  use the database object in a transaction
  // this will deadlock!
  await database.execute("CREATE TABLE Test2 (id INTEGER PRIMARY KEY)");
});
```

### Batch support

To avoid ping-pong between dart and native code, you can use `Batch`:

```dart
batch = db.batch();
batch.insert("Test", {"name": "item"});
batch.update("Test", {"name": "new_item"}, where: "name = ?", whereArgs: ["item"]);
batch.delete("Test", where: "name = ?", whereArgs: ["item"]);
results = await batch.commit();
```

Getting the result for each operation has a cost (id for insertion and number of changes for
update and delete), especially on Android where an extra SQL request is executed.
If you don't care about the result and worry about performance in big batches, you can use

```dart
await batch.commit(noResult: true);
```

Warning, during a transaction, the batch won't be commited until the transaction is commited

```dart
await database.transaction((txn) async {
  var batch = txn.batch();
  
  // ...
  
  // commit but the actual commit will happen when the transaction is commited
  // however the data is available in this transaction
  await batch.commit();
  
  //  ...
});
```

## Table and column names

In general it is better to avoid using SQLite keywords for entity names. If any of the following
name is used:

    "add","all","alter","and","as","autoincrement","between","case","check","collate","commit","constraint","create","default","deferrable","delete","distinct","drop","else","escape","except","exists","foreign","from","group","having","if","in","index","insert","intersect","into","is","isnull","join","limit","not","notnull","null","on","or","order","primary","references","select","set","table","then","to","transaction","union","unique","update","using","values","when","where"
    
the helper will *escape* the name i.e.

```dart
db.query("table")
```
will be equivalent to manually adding double-quote around the table name (confusingly here named `table`)

```dart
db.rawQuery('SELECT * FROM "table"');
```

However in any other raw statement (including `orderBy`, `where`, `groupBy`), make sure to escape the name
properly using double quote. For example see below where the column name `group` is not escaped in the columns
argument, but is escaped in the `where` argument.

```dart
db.query("table", columns: ["group"], where: '"group" = ?', whereArgs: ["my_group"]);
```

## Supported SQLite types

No validity check is done on values yet so please avoid non supported types. DateTime is not
a supported SQL type (https://www.sqlite.org/datatype3.html). Personally I store them as 
int (millisSinceEpoch) or string (iso8601)

### INTEGER

* Dart type: `int`
* Supported values: from -2^63 to 2^63 - 1

### REAL

* Dart type: `num`

### TEXT

* Dart type: `String`

### BLOB

* Dart type: `Uint8List`
* Dart type `List<int>` is supported but not recommended (slow conversion)

## Current issues

* Due to the way transaction works in SQLite (threads), concurrent read and write transaction are not supported. 
All calls are currently synchronized and transactions block are exclusive. I thought that a basic way to support 
concurrent access is to open a database multiple times but it only works on iOS as Android reuses the same database object.
I also thought a native thread could be a potential future solution however on android accessing the database in another
thread is blocked while in a transaction...
* Currently INTEGER are limited to -2^63 to 2^63 - 1 (although Android supports bigger ones)

## More

* [How to](https://github.com/tekartik/sqflite/blob/master/doc/how_to.md) guide
