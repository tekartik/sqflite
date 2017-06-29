import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'test_page.dart';

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

class TodoTestPage extends TestPage {
  TodoTestPage() : super("Todo example") {
    test("open", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("simple_todo_open.db");
      TodoProvider todoProvider = new TodoProvider();
      await todoProvider.open(path);

      await todoProvider.close();
      //await Sqflite.setDebugModeOn(false);
    });

    test("insert/query/update/delete", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("simple_todo.db");
      TodoProvider todoProvider = new TodoProvider();
      await todoProvider.open(path);

      Todo todo = new Todo()..title = "test";
      await todoProvider.insert(todo);
      assert(todo.id == 1);

      assert(await todoProvider.getTodo(0) == null);
      todo = await todoProvider.getTodo(1);
      assert(todo.id == 1);
      assert(todo.title == "test");
      assert(todo.done == false);

      todo.done = true;
      assert(await todoProvider.update(todo) == 1);
      todo = await todoProvider.getTodo(1);
      assert(todo.id == 1);
      assert(todo.title == "test");
      assert(todo.done == true);

      assert(await todoProvider.delete(0) == 0);
      assert(await todoProvider.delete(1) == 1);
      assert(await todoProvider.getTodo(1) == null);

      await todoProvider.close();
      //await Sqflite.setDebugModeOn(false);
    });
  }
}
