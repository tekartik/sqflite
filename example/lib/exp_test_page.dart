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
      String path = await initDeleteDb("simple_exp.db");
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

      var expectedResult =  [
        {"column_1": 10, "column_2": 2000},
        {"column_1": 10, "column_2": 180},
        {"column_1": 11, "column_2": 180}
      ];

      var result = await db.rawQuery(
          "SELECT * FROM $table ORDER BY column_1 ASC, column_2 DESC");
      //print(JSON.encode(result));
      assert(const DeepCollectionEquality().equals(result, expectedResult));
      result =
          await db.query(table, orderBy: "column_1 ASC, column_2 DESC");
      assert(const DeepCollectionEquality().equals(result, expectedResult));



      await db.close();
    });
  }
}
