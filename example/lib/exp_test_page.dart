import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      expect(result, expectedResult);
      result = await db.query(table, orderBy: "column_1 ASC, column_2 DESC");
      expect(result, expectedResult);

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
      expect(result, expectedResult);

      // testing with value as arguments
      result = await db.query(table,
          where: "column_1 IN (?, ?)",
          whereArgs: ["1", "2"],
          orderBy: "column_1 ASC, column_2 ASC");
      expect(result, expectedResult);

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
      expect(result, expectedResult);
      result =
          await db.rawQuery("SELECT * FROM '$table' ORDER BY `group` DESC");
      //print(JSON.encode(result));
      expect(result, expectedResult);

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
      expect(result, expectedResult);

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
      expect(result, [
        {"one": "1", "my_col": "2,3"},
        {"one": "2", "my_col": "2"}
      ]);

      result = await db.rawQuery('''
      select one, GROUP_CONCAT(another)
      from $table
      GROUP BY one''');
      // print('result :$result');
      expect(result, [
        {"one": "1", "GROUP_CONCAT(another)": "2,3"},
        {"one": "2", "GROUP_CONCAT(another)": "2"}
      ]);

      // user alias
      result = await db.rawQuery('''
      select t.one, GROUP_CONCAT(t.another)
      from $table as t
      GROUP BY t.one''');
      //print('result :$result');
      expect(result, [
        {"one": "1", "GROUP_CONCAT(t.another)": "2,3"},
        {"one": "2", "GROUP_CONCAT(t.another)": "2"}
      ]);

      await db.close();
    });

    test("Alias", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("exp_alias.db");
      Database db = await openDatabase(path);

      try {
        String table = "alias";
        await db.execute(
            "CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)");
        await db.insert(table, {"column_1": 1, "column_2": 2});

        var result = await db.rawQuery('''
      select t.column_1, t.column_1 as "t.column1", column_1 as column_alias_1, column_2
      from $table as t''');
        print('result :$result');
        expect(result, [
          {"t.column1": 1, "column_1": 1, "column_alias_1": 1, "column_2": 2}
        ]);
      } finally {
        await db.close();
      }
    });

    test("Dart2 query", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("exp_dart2_query.db");
      Database db = await openDatabase(path);

      try {
        String table = "test";
        await db.execute(
            "CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)");
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
        verify(keys.first == "column_1" || keys.first == "column_2");
        verify(values.first == 1 || values.first == 2);
        print('result.last.keys: ${result.last.keys}');
        keys = result.last.keys;
        values = result.last.values;
        verify(keys.last == "column_1" || keys.last == "column_2");
        verify(values.last == 1 || values.last == 2);
      } finally {
        await db.close();
      }
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
    test("Issue#48", () async {
      // Sqflite.devSetDebugModeOn(true);
      // devPrint("issue #48");
      // Try to query on a non-indexed field
      String path = await initDeleteDb("exp_issue_48.db");
      Database db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE npa (id INT, title TEXT, identifier TEXT)");
        await db.insert(
            "npa", {"id": 128, "title": "title 1", "identifier": "0001"});
        await db.insert("npa",
            {"id": 215, "title": "title 1", "identifier": "0008120150514"});
      });
      var resultSet = await db.query("npa",
          columns: ["id", "title", "identifier"],
          where: '"identifier" = ?',
          whereArgs: ["0008120150514"]);
      // print(resultSet);
      expect(resultSet.length, 1);
      // but the results is always - empty QueryResultSet[].
      // If i'm trying to do the same with the id field and integer value like
      resultSet = await db.query("npa",
          columns: ["id", "title", "identifier"],
          where: '"id" = ?',
          whereArgs: [215]);
      // print(resultSet);
      expect(resultSet.length, 1);
      await db.close();
    });

    test("Issue#52", () async {
      // Sqflite.devSetDebugModeOn(true);
      // Try to insert string with quote
      String path = await initDeleteDb("exp_issue_52.db");
      Database db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE test (id INT, value TEXT)");
        await db.insert("test", {"id": 1, "value": 'without quote'});
        await db.insert("test", {"id": 2, "value": 'with " quote'});
      });
      var resultSet = await db
          .query("test", where: 'value = ?', whereArgs: ['with " quote']);
      expect(resultSet.length, 1);
      expect(resultSet.first['id'], 2);

      resultSet = await db
          .rawQuery('SELECT * FROM test WHERE value = ?', ['with " quote']);
      expect(resultSet.length, 1);
      expect(resultSet.first['id'], 2);
      await db.close();
    });

    test("Issue#64", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("issue_64.db");

      // delete existing if any
      await deleteDatabase(path);

      // Copy from asset
      var data = await rootBundle.load(join("assets", "issue_64.db"));
      var bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await new File(path).writeAsBytes(bytes);

      // open the database
      Database db = await openDatabase(path);

      var result = await db.query('recordings',
          columns: ['id', 'content', 'file', 'speaker', 'reference']);
      print('result1: $result');
      expect(result.length, 2);

      // This one does not work
      // to investigate
      result = await db.query('recordings',
          columns: ['id', 'content', 'file', 'speaker', 'reference'],
          where: 'speaker = ?',
          whereArgs: [1]);

      print('result2: $result');
      expect(result.length, 2);

      result = await db.query(
        'recordings',
        columns: ['id', 'content', 'file', 'speaker', 'reference'],
        where: 'speaker = 1',
      );
      print('result3: $result');
      expect(result.length, 2);

      await db.close();
    });
  }
}
