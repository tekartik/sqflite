import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sql.dart';
import 'test_page.dart';

class ExceptionTestPage extends TestPage {
  ExceptionTestPage() : super("Exception tests") {
    test("Transaction failed", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("transaction_failed.db");
      Database db = await openDatabase(path);

      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      // insert then fails to make sure the transaction is cancelled
      bool hasFailed = false;
      try {
        await db.inTransaction(() async {
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item"]);
          int afterCount = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
          assert(afterCount == 1);

          hasFailed = true;
          // this failure should cancel the insertion before
          await db.execute("DUMMY CALL");
          hasFailed = false;
        });
      } catch (e) {
        // iOS: native_error: PlatformException(sqlite_error, Error Domain=FMDatabase Code=1 "near "DUMMY": syntax error" UserInfo={NSLocalizedDescription=near "DUMMY": syntax error}, null)
        print("native_error: $e");
      }
      assert(hasFailed);

      int afterCount =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      assert(afterCount == 0);

      await db.close();
    });

    test("Transaction recursive failed", () async {
      String path = await initDeleteDb("transaction_failed.db");
      Database db = await openDatabase(path);

      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      // insert then fails to make sure the transaction is cancelled
      bool hasFailed = false;
      try {
        await db.inTransaction(() async {
          await db.inTransaction(() async {
            await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item"]);
            int afterCount = Sqflite
                .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
            assert(afterCount == 1);

            hasFailed = true;
            // this failure should cancel the insertion before
            await db.execute("DUMMY CALL");
            hasFailed = false;
          });
        });
      } catch (e) {
        print("native error: $e");
      }

      assert(hasFailed);

      int afterCount =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      assert(afterCount == 0);

      await db.close();
    });

    test("Sqlite Exception", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("exception.db");
      Database db = await openDatabase(path);

      // Query
      try {
        await db.rawQuery("SELECT COUNT(*) FROM Test");
        assert(false); // should fail before
      } on DatabaseException catch (e) {
        assert(e.isNoSuchTableError("Test"));
      }

      // Catch without using on DatabaseException
      try {
        await db.rawQuery("malformed query");
        assert(false); // should fail before
      } catch (e) {
        assert(e.isSyntaxError());
      }

      try {
        await db.execute("DUMMY");
        assert(false); // should fail before
      } on DatabaseException catch (e) {
        assert(e.isSyntaxError());
      }

      try {
        await db.rawInsert("DUMMY");
        assert(false); // should fail before
      } on DatabaseException catch (e) {
        assert(e.isSyntaxError());
      }

      try {
        await db.rawUpdate("DUMMY");
        assert(false); // should fail before
      } on DatabaseException catch (e) {
        assert(e.isSyntaxError());
      }

      await db.close();
    });

    test("Open onDowngrade fail", () async {
      String path = await initDeleteDb("open_on_downgrade_fail.db");
      Database database = await openDatabase(path, version: 2,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      });
      await database.close();

      // currently this is crashing...
      // should fail going back in versions
      try {
        database = await openDatabase(path,
            version: 1, onDowngrade: onDatabaseVersionChangeError);
        assert(false);
      } catch (e) {
        print(e);
      }

      // should work
      database = await openDatabase(path,
          version: 2, onDowngrade: onDatabaseVersionChangeError);
      print(database);
      await database.close();
    });

    test("Open onDowngrade delete", () async {
      //await Sqflite.setDebugModeOn();

      String path = await initDeleteDb("open_on_downgrade_delete.db");
      Database database = await openDatabase(path, version: 3,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      });
      await database.close();

      // should fail going back in versions
      bool onCreated = false;
      bool onOpened = false;
      database = await openDatabase(path, version: 2,
          onCreate: (Database db, int version) {
        onCreated = true;
        assert(version == 2);
      }, onOpen: (Database db) {
        onOpened = true;
      }, onDowngrade: onDatabaseDowngradeDelete);
      await database.close();

      assert(onCreated);
      assert(onOpened);

      onCreated = false;
      onOpened = false;

      database = await openDatabase(path, version: 2,
          onCreate: (Database db, int version) {
        assert(false, "should not be called");
      }, onOpen: (Database db) {
        onOpened = true;
      }, onDowngrade: onDatabaseDowngradeDelete);
      assert(onOpened);
      await database.close();
    });

    test("Access after close", () async {
      String path = await initDeleteDb("access_after_close.db");
      Database database = await openDatabase(path, version: 3,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      });
      await database.close();
      try {
        await database.getVersion();
        assert(false);
      } on DatabaseException catch (e) {
        print(e);
        assert(e.isDatabaseClosedError());
      }

      try {
        await database.setVersion(1);
        assert(false);
      } on DatabaseException catch (e) {
        print(e);
        assert(e.isDatabaseClosedError());
      }
    });

    test("Non escaping fields", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("non_escaping_fields.db");
      Database db = await openDatabase(path);

      String table = "table";
      try {
        await db.execute("CREATE TABLE $table (group INTEGER)");
        fail("should fail");
      } on DatabaseException catch (e) {
        print(e);
        assert(e.isSyntaxError());
      }
      try {
        await db.execute("INSERT INTO $table (group) VALUES (1)");
        fail("should fail");
      } on DatabaseException catch (e) {
        print(e);
        assert(e.isSyntaxError());
      }
      try {
        await db.rawQuery("SELECT * FROM $table ORDER BY group DESC");
      } on DatabaseException catch (e) {
        print(e);
        assert(e.isSyntaxError());
      }

      try {
        await db.rawQuery("DELETE FROM $table");
      } on DatabaseException catch (e) {
        print(e);
        assert(e.isSyntaxError());
      }

      // Build our escape list from all the sqlite keywords
      List<String> toExclude = [];
      for (String name in allEscapeNames) {
        try {
          await db.execute("CREATE TABLE $name (value INTEGER)");
        } on DatabaseException catch (e) {
          await db.execute("CREATE TABLE ${escapeName(name)} (value INTEGER)");

          assert(e.isSyntaxError());
          toExclude.add(name);
        }
      }
      print(JSON.encode(toExclude));

      await db.close();
    });
  }
}

var escapeNames = [
  "add",
  "all",
  "alter",
  "and",
  "as",
  "autoincrement",
  "between",
  "case",
  "check",
  "collate",
  "commit",
  "constraint",
  "create",
  "default",
  "deferrable",
  "delete",
  "distinct",
  "drop",
  "else",
  "escape",
  "except",
  "exists",
  "foreign",
  "from",
  "group",
  "having",
  "if",
  "in",
  "index",
  "insert",
  "intersect",
  "into",
  "is",
  "isnull",
  "join",
  "limit",
  "not",
  "notnull",
  "null",
  "on",
  "or",
  "order",
  "primary",
  "references",
  "select",
  "set",
  "table",
  "then",
  "to",
  "transaction",
  "union",
  "unique",
  "update",
  "using",
  "values",
  "when",
  "where"
];

var allEscapeNames = [
  "abort",
  "action",
  "add",
  "after",
  "all",
  "alter",
  "analyze",
  "and",
  "as",
  "asc",
  "attach",
  "autoincrement",
  "before",
  "begin",
  "between",
  "by",
  "cascade",
  "case",
  "cast",
  "check",
  "collate",
  "column",
  "commit",
  "conflict",
  "constraint",
  "create",
  "cross",
  "current_date",
  "current_time",
  "current_timestamp",
  "database",
  "default",
  "deferrable",
  "deferred",
  "delete",
  "desc",
  "detach",
  "distinct",
  "drop",
  "each",
  "else",
  "end",
  "escape",
  "except",
  "exclusive",
  "exists",
  "explain",
  "fail",
  "for",
  "foreign",
  "from",
  "full",
  "glob",
  "group",
  "having",
  "if",
  "ignore",
  "immediate",
  "in",
  "index",
  "indexed",
  "initially",
  "inner",
  "insert",
  "instead",
  "intersect",
  "into",
  "is",
  "isnull",
  "join",
  "key",
  "left",
  "like",
  "limit",
  "match",
  "natural",
  "no",
  "not",
  "notnull",
  "null",
  "of",
  "offset",
  "on",
  "or",
  "order",
  "outer",
  "plan",
  "pragma",
  "primary",
  "query",
  "raise",
  "recursive",
  "references",
  "regexp",
  "reindex",
  "release",
  "rename",
  "replace",
  "restrict",
  "right",
  "rollback",
  "row",
  "savepoint",
  "select",
  "set",
  "table",
  "temp",
  "temporary",
  "then",
  "to",
  "transaction",
  "trigger",
  "union",
  "unique",
  "update",
  "using",
  "vacuum",
  "values",
  "view",
  "virtual",
  "when",
  "where",
  "with",
  "without"
];
