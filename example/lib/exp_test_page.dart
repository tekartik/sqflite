import 'package:sqflite/sqflite.dart';

import 'src/common_import.dart';
import 'test_page.dart';

final String tableTodo = "todo";
final String columnId = "_id";
final String columnTitle = "title";
final String columnDone = "done";

class ExpTestPage extends TestPage {
  ExpTestPage() : super("Exp Tests") {
    test("order_by", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("order_by_exp.db");
      Database db = await openDatabase(path);

      String table = "test";
      await db
          .execute("CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)");
      // inserted in a wrong order to check ASC/DESC
      await db
          .execute("INSERT INTO $table (column_1, column_2) VALUES (11, 180)");
      await db
          .execute("INSERT INTO $table (column_1, column_2) VALUES (10, 180)");
      await db
          .execute("INSERT INTO $table (column_1, column_2) VALUES (10, 2000)");

      var expectedResult = [
        {"column_1": 10, "column_2": 2000},
        {"column_1": 10, "column_2": 180},
        {"column_1": 11, "column_2": 180}
      ];

      var result = await db.rawQuery(
          "SELECT * FROM $table ORDER BY column_1 ASC, column_2 DESC");
      //print(JSON.encode(result));
      assert(const DeepCollectionEquality().equals(result, expectedResult));
      result = await db.query(table, orderBy: "column_1 ASC, column_2 DESC");
      assert(const DeepCollectionEquality().equals(result, expectedResult));

      await db.close();
    });

    test("in", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("simple_exp.db");
      Database db = await openDatabase(path);

      String table = "test";
      await db
          .execute("CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)");
      await db
          .execute("INSERT INTO $table (column_1, column_2) VALUES (1, 1001)");
      await db
          .execute("INSERT INTO $table (column_1, column_2) VALUES (2, 1002)");
      await db
          .execute("INSERT INTO $table (column_1, column_2) VALUES (2, 1012)");
      await db
          .execute("INSERT INTO $table (column_1, column_2) VALUES (3, 1003)");

      var expectedResult = [
        {"column_1": 1, "column_2": 1001},
        {"column_1": 2, "column_2": 1002},
        {"column_1": 2, "column_2": 1012}
      ];

      // testing with value in the In clause
      var result = await db.query(table,
          where: "column_1 IN (1, 2)", orderBy: "column_1 ASC, column_2 ASC");
      //print(JSON.encode(result));
      assert(const DeepCollectionEquality().equals(result, expectedResult));

      // testing with value as arguments
      result = await db.query(table,
          where: "column_1 IN (?, ?)",
          whereArgs: ["1", "2"],
          orderBy: "column_1 ASC, column_2 ASC");
      assert(const DeepCollectionEquality().equals(result, expectedResult));

      await db.close();
    });

    test("Raw escaping", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("raw_escaping_fields.db");
      Database db = await openDatabase(path);

      String table = "table";
      await db.execute('CREATE TABLE "$table" ("group" INTEGER)');
      // inserted in a wrong order to check ASC/DESC
      await db.execute('INSERT INTO "$table" ("group") VALUES (1)');

      var expectedResult = [
        {"group": 1}
      ];

      var result = await db
          .rawQuery('SELECT "group" FROM "$table" ORDER BY "group" DESC');
      print(result);
      assert(const DeepCollectionEquality().equals(result, expectedResult));
      result =
          await db.rawQuery("SELECT * FROM '$table' ORDER BY `group` DESC");
      //print(JSON.encode(result));
      assert(const DeepCollectionEquality().equals(result, expectedResult));

      await db.rawDelete("DELETE FROM '$table'");

      await db.close();
    });

    test("Escaping fields", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("escaping_fields.db");
      Database db = await openDatabase(path);

      String table = "group";
      await db.execute('CREATE TABLE "$table" ("group" TEXT)');
      // inserted in a wrong order to check ASC/DESC

      await db.insert(table, {"group": "group_value"});
      await db.update(table, {"group": "group_new_value"},
          where: "\"group\" = 'group_value'");

      var expectedResult = [
        {"group": "group_new_value"}
      ];

      var result =
          await db.query(table, columns: ["group"], orderBy: '"group" DESC');
      //print(JSON.encode(result));
      assert(const DeepCollectionEquality().equals(result, expectedResult));

      await db.delete(table);

      await db.close();
    });

    test("Functions", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("exp_functions.db");
      Database db = await openDatabase(path);

      String table = "functions";
      await db.execute('CREATE TABLE "$table" (one TEXT, another TEXT)');
      await db.insert(table, {"one": "1", "another": "2"});
      await db.insert(table, {"one": "1", "another": "3"});
      await db.insert(table, {"one": "2", "another": "2"});

      var result = await db.rawQuery('''
      select one, GROUP_CONCAT(another) as my_col
      from $table
      GROUP BY one''');
      //print('result :$result');
      assert(const DeepCollectionEquality().equals(result, [
        {"one": "1", "my_col": "2,3"},
        {"one": "2", "my_col": "2"}
      ]));

      result = await db.rawQuery('''
      select one, GROUP_CONCAT(another)
      from $table
      GROUP BY one''');
      // print('result :$result');
      assert(const DeepCollectionEquality().equals(result, [
        {"one": "1", "GROUP_CONCAT(another)": "2,3"},
        {"one": "2", "GROUP_CONCAT(another)": "2"}
      ]));

      // user alias
      result = await db.rawQuery('''
      select t.one, GROUP_CONCAT(t.another)
      from $table as t
      GROUP BY t.one''');
      //print('result :$result');
      assert(const DeepCollectionEquality().equals(result, [
        {"one": "1", "GROUP_CONCAT(t.another)": "2,3"},
        {"one": "2", "GROUP_CONCAT(t.another)": "2"}
      ]));

      await db.close();
    });

    test("Alias", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("exp_alias.db");
      Database db = await openDatabase(path);

      String table = "alias";
      await db
          .execute("CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)");
      await db.insert(table, {"column_1": 1, "column_2": 2});

      var result = await db.rawQuery('''
      select t.column_1, t.column_1 as "t.column1", column_1 as column_alias_1, column_2
      from $table as t''');
      print('result :$result');
      assert(const DeepCollectionEquality().equals(result, [
        {"t.column1": 1, "column_1": 1, "column_alias_1": 1, "column_2": 2}
      ]));
    });

    test("Dart2 query", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("exp_alias.db");
      Database db = await openDatabase(path);

      String table = "test";
      await db
          .execute("CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)");
      await db.insert(table, {"column_1": 1, "column_2": 2});

      var result = await db.rawQuery('''
         select column_1, column_2
         from $table as t
      ''');
      print('result: $result');
      // test output types
      print('result.first: ${result.first}');
      Map<String, dynamic> first = result.first;
      print('result.first.keys: ${first.keys}');
      Iterable<String> keys = result.first.keys;
      Iterable values = result.first.values;
      assert(keys.first == "column_1" || keys.first == "column_2");
      assert(values.first == 1 || values.first == 2);
      print('result.last.keys: ${result.last.keys}');
      keys = result.last.keys;
      values = result.last.values;
      assert(keys.last == "column_1" || keys.last == "column_2");
      assert(values.last == 1 || values.last == 2);
    });
    /*

    Save code that modify a map from a result - unused
    var rawResult = await rawQuery(builder.sql, builder.arguments);

    // Super slow if we escape a name, please avoid it
    // This won't be called if no keywords were used
    if (builder.hasEscape) {
      for (Map map in rawResult) {
        var keys = new Set<String>();

        for (String key in map.keys) {
          if (isEscapedName(key)) {
            keys.add(key);
          }
        }
        if (keys.isNotEmpty) {
          for (var key in keys) {
            var value = map[key];
            map.remove(key);
            map[unescapeName(key)] = value;
          }
        }
      }
    }
    return rawResult;
    */
  }
}
