# sqflite

An experimental SQLite plugin for [Flutter](https://flutter.io).
Supports both iOS and Android.

* Support recursive inTransaction calls
* Automatic version managment
* Helpers for insert/query/update/delete queries

## Getting Started

In your flutter project add the dependency:

    dependencies:
      ...
      sqflite:
       git: git://github.com/tekartik/sqflite
    

For help getting started with Flutter, view the online
[documentation](https://flutter.io/).

## Usage example

Import `sqflite.dart`

    import 'package:sqflite/sqflite.dart';
    
Demo code to perform Raw SQL queries


    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "demo.db");

    // Delete the database
    deleteDatabase(path);

    // open the database
    Database database = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
            "CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER)");
    });

    // Insert some record
    await database.inTransaction(() async {
      int id1 = await database
          .insert('INSERT INTO Test(name, value) VALUES("some name",1234)');
      print("inserted1: $id1");
      int id2 = await database.insert('INSERT INTO Test(name, value) VALUES(?, ?)',
          ["another name", 12345678]);
      print("inserted2: $id2");
    });

    // Update some record
    int count = await database.update(
        'UPDATE Test SET name = ?, VALUE = ? WHERE name = ?',
        ["updated name", "9876", "some name"]);
    print("updated: $count");

    // Get the records
    List<Map> list = await database.query('SELECT * FROM Test');
    List<Map> expectedList = [
      {"name": "updated name", "id": 1, "value": 9876},
      {"name": "another name", "id": 2, "value": 12345678}
    ];
    assert(const DeepCollectionEquality().equals(list, expectedList));

    // Count the records
    count = Sqflite.firstIntValue(await database.query("SELECT COUNT(*) FROM Test"));
    assert(count == 2);

    // Delete a record
    count = await database.delete('DELETE FROM Test WHERE name = ?', ['another name']);
    assert(count == 1);
      
    // Close the database
    await database.close();

Example using the helpers

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

## Current issues

* Due to the way transaction works in SQLite (threads), concurrent read and write transaction are not supported yet in 
this sample demo. All calls are currently synchronized and transactions block are exclusive. A basic way to support 
concurrent access is to open a database multiple times but it only works on iOS as Android reuses the same database object.
a native thread for each transaction and zoning inTransaction calls could be a potential future solution
* Only TEXT, INTEGER and REAL types are tested for now. No support for BLOB yet

