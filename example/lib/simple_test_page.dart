import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/utils.dart';
import 'package:sqflite_example/test_page.dart';

class SimpleTestPage extends TestPage {
  SimpleTestPage() : super("Simple tests") {
    test("Perf", () async {
      String path = await initDeleteDb("simple_test1.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      await db.inTransaction(() async {
        for (int i = 0; i < 100; i++) {
          await db.insert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
        }
      });
      await db.close();
    });
    test("Transaction", () async {
      String path = await initDeleteDb("simple_test2.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      _test(int i) async {
        await db.inTransaction(() async {
          int count = parseInt((await db.query("SELECT COUNT(*) FROM Test"))
              ?.first
              .values
              .first);
          await new Future.delayed(new Duration(milliseconds: 40));
          await db.insert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
          //print(await db.query("SELECT COUNT(*) FROM Test"));
          int afterCount = parseInt(
              (await db.query("SELECT COUNT(*) FROM Test"))
                  ?.first
                  .values
                  .first);
          assert(count + 1 == afterCount);
        });
      }

      List<Future> futures = [];
      for (int i = 0; i < 4; i++) {
        futures.add(_test(i));
      }
      await Future.wait(futures);
      await db.close();
    });
    test("Demo", () async {
      String path = await initDeleteDb("simple_test3.db");
      Database database = await openDatabase(path);

      //int version = await database.update("PRAGMA user_version");
      //print("version: ${await database.update("PRAGMA user_version")}");
      print("version: ${await database.query("PRAGMA user_version")}");

      //print("drop: ${await database.update("DROP TABLE IF EXISTS Test")}");
      await database.execute("DROP TABLE IF EXISTS Test");

      print("dropped");
      await database.execute(
          "CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER)");
      print("table created");
      int id = await database
          .insert('INSERT INTO Test(name, value) VALUES("some name",1234)');
      print("inserted1: $id");
      id = await database.insert('INSERT INTO Test(name, value) VALUES(?, ?)',
          ["another name", 12345678]);
      print("inserted2: $id");
      int count = await database.update(
          'UPDATE Test SET name = ?, VALUE = ? WHERE name = ?',
          ["updated name", "9876", "some name"]);
      print("updated: $count");
      List<Map> list = await database.query('SELECT * FROM Test');
      List<Map> expectedList =  [
        {"name": "updated name", "id": "1", "value": "9876"},
        {"name": "another name", "id": "2", "value": "12345678"}
      ];

      print(list);
      print(expectedList);
      assert(const DeepCollectionEquality().equals(list, expectedList));


      await database.close();
    });
  }
}
