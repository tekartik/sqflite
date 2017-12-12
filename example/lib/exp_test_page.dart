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
      await Sqflite.setDebugModeOn(true);
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
  }
}
