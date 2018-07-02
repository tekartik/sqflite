import 'package:flutter_test/flutter_test.dart';
//import 'package:test/test.dart';
import 'package:sqflite/src/sql_builder.dart';

void main() {
  group("sql_builder", () {
    test("delete", () {
      SqlBuilder builder = new SqlBuilder.delete("test",
          where: "value = ?", whereArgs: <dynamic>[1]);
      expect(builder.sql, "DELETE FROM test WHERE value = ?");
      expect(builder.arguments, [1]);

      builder = new SqlBuilder.delete("test");
      expect(builder.sql, "DELETE FROM test");
      expect(builder.arguments, isNull);
    });

    test("query", () {
      SqlBuilder builder = new SqlBuilder.query("test");
      expect(builder.sql, "SELECT * FROM test");
      expect(builder.arguments, isNull);

      builder = new SqlBuilder.query("test",
          distinct: true,
          columns: ["value"],
          where: "value = ?",
          whereArgs: <dynamic>[1],
          groupBy: "group_value",
          having: "value > 0",
          orderBy: "other_value",
          limit: 2,
          offset: 3);
      expect(builder.sql,
          "SELECT DISTINCT value FROM test WHERE value = ? GROUP BY group_value HAVING value > 0 ORDER BY other_value LIMIT 2 OFFSET 3");
      expect(builder.arguments, [1]);
    });

    test("insert", () {
      try {
        new SqlBuilder.insert("test", null);
        fail('should fail, no nullColumnHack');
      } on ArgumentError catch (_) {}

      SqlBuilder builder =
          new SqlBuilder.insert("test", null, nullColumnHack: "value");
      expect(builder.sql, "INSERT INTO test (value) VALUES (NULL)");
      expect(builder.arguments, isNull);

      builder = new SqlBuilder.insert("test", <String, dynamic>{"value": 1});
      expect(builder.sql, "INSERT INTO test (value) VALUES (?)");
      expect(builder.arguments, [1]);

      builder = new SqlBuilder.insert(
          "test", <String, dynamic>{"value": 1, "other_value": null});
      expect(builder.sql,
          "INSERT INTO test (value, other_value) VALUES (?, NULL)");
      expect(builder.arguments, [1]);
    });

    test("update", () {
      try {
        new SqlBuilder.update("test", null);
        fail('should fail, no values');
      } on ArgumentError catch (_) {}

      SqlBuilder builder =
          new SqlBuilder.update("test", <String, dynamic>{"value": 1});
      expect(builder.sql, "UPDATE test SET value = ?");
      expect(builder.arguments, [1]);

      builder = new SqlBuilder.update(
          "test", <String, dynamic>{"value": 1, "other_value": null});
      expect(builder.sql, "UPDATE test SET value = ?, other_value = NULL");
      expect(builder.arguments, [1]);

      // testing where
      builder = new SqlBuilder.update('test', <String, dynamic>{"value": 1},
          where: "a = ? AND b = ?", whereArgs: <dynamic>['some_test', 1]);
      expect(builder.arguments, [1, "some_test", 1]);
    });

    test("query", () {
      SqlBuilder builder = new SqlBuilder.query("table", orderBy: "value");
      expect(builder.sql, 'SELECT * FROM "table" ORDER BY value');
      expect(builder.arguments, isNull);

      builder =
          new SqlBuilder.query("table", orderBy: "column_1 ASC, column_2 DESC");
      expect(builder.sql,
          'SELECT * FROM "table" ORDER BY column_1 ASC, column_2 DESC');
      expect(builder.arguments, isNull);

      // testing where
      builder = new SqlBuilder.query('test',
          where: "a = ? AND b = ?", whereArgs: <dynamic>['some_test', 1]);
      expect(builder.arguments, ["some_test", 1]);
    });

    test("isEscapedName", () {
      expect(isEscapedName(null), false);
      expect(isEscapedName("group"), false);
      expect(isEscapedName("'group'"), false);
      expect(isEscapedName('"group"'), true);
      expect(isEscapedName("`group`"), true);
      expect(isEscapedName("`group'"), false);
      expect(isEscapedName("\"group\""), true);
    });

    test("escapeName", () {
      expect(escapeName(null), null);
      expect(escapeName("group"), '"group"');
      expect(escapeName("dummy"), "dummy");

      for (String name in escapeNames) {
        expect(escapeName(name), '"${name}"');
      }
    });

    test("unescapeName", () {
      expect(unescapeName(null), null);

      expect(unescapeName("dummy"), "dummy");
      expect(unescapeName("'dummy'"), "'dummy'");
      expect(unescapeName("'group'"), "'group'");
      expect(unescapeName('"group"'), "group");
      expect(unescapeName('`group`'), "group");

      for (String name in escapeNames) {
        expect(unescapeName('"$name"'), name);
      }
    });
  });
}
