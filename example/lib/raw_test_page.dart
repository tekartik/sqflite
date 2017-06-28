import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/test_page.dart';

class SimpleTestPage extends TestPage {
  SimpleTestPage() : super("Raw tests") {
    test("Transaction", () async {
      String path = await initDeleteDb("simple_test2.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      _test(int i) async {
        await db.inTransaction(() async {
          int count = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
          await new Future.delayed(new Duration(milliseconds: 40));
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
          //print(await db.query("SELECT COUNT(*) FROM Test"));
          int afterCount = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
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

    test("Transaction failed", () async {
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

    test("Transaction recursive", () async {
      String path = await initDeleteDb("transaction_recursive.db");
      Database db = await openDatabase(path);

      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      // insert then fails to make sure the transaction is cancelled
      await db.inTransaction(() async {
        await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item 1"]);

        await db.inTransaction(() async {
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item 2"]);
        });
      });
      int afterCount =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      assert(afterCount == 2);

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

    test("Transaction open twice", () async {
      //Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("transaction_open_twice.db");
      Database db = await openDatabase(path);

      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Database db2 = await openDatabase(path);

      await db.inTransaction(() async {
        await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item"]);
        int afterCount = Sqflite
            .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
        assert(afterCount == 1);

        /*
        // this is not working on Android
        int db2AfterCount =
        Sqflite.firstIntValue(await db2.rawQuery("SELECT COUNT(*) FROM Test"));
        assert(db2AfterCount == 0);
        */
      });
      int db2AfterCount = Sqflite
          .firstIntValue(await db2.rawQuery("SELECT COUNT(*) FROM Test"));
      assert(db2AfterCount == 1);

      int afterCount =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      assert(afterCount == 1);

      await db.close();
      await db2.close();
    });

    test("Debug mode (log)", () async {
      //await Sqflite.devSetDebugModeOn(false);
      String path = await initDeleteDb("debug_mode.db");
      Database db = await openDatabase(path);

      await Sqflite.setDebugModeOn(true);
      await db.setVersion(1);
      await Sqflite.setDebugModeOn(false);
      // this message should not appear
      await db.setVersion(2);
      await Sqflite.setDebugModeOn(true);
      await db.setVersion(3);

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

    test("Demo", () async {
      String path = await initDeleteDb("simple_test3.db");
      Database database = await openDatabase(path);

      //int version = await database.update("PRAGMA user_version");
      //print("version: ${await database.update("PRAGMA user_version")}");
      print("version: ${await database.rawQuery("PRAGMA user_version")}");

      //print("drop: ${await database.update("DROP TABLE IF EXISTS Test")}");
      await database.execute("DROP TABLE IF EXISTS Test");

      print("dropped");
      await database.execute(
          "CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)");
      print("table created");
      int id = await database.rawInsert(
          'INSERT INTO Test(name, value, num) VALUES("some name",1234,?)',
          [456.789]);
      print("inserted1: $id");
      id = await database.rawInsert(
          'INSERT INTO Test(name, value) VALUES(?, ?)',
          ["another name", 12345678]);
      print("inserted2: $id");
      int count = await database.rawUpdate(
          'UPDATE Test SET name = ?, VALUE = ? WHERE name = ?',
          ["updated name", "9876", "some name"]);
      print("updated: $count");
      assert(count == 1);
      List<Map> list = await database.rawQuery('SELECT * FROM Test');
      List<Map> expectedList = [
        {"name": "updated name", "id": 1, "value": 9876, "num": 456.789},
        {"name": "another name", "id": 2, "value": 12345678, "num": null}
      ];

      print("list: ${JSON.encode(list)}");
      print("expected $expectedList");
      assert(const DeepCollectionEquality().equals(list, expectedList));

      count = await database
          .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
      print('deleted: $count');
      assert(count == 1);
      list = await database.rawQuery('SELECT * FROM Test');
      expectedList = [
        {"name": "updated name", "id": 1, "value": 9876, "num": 456.789},
      ];

      print("list: ${JSON.encode(list)}");
      print("expected $expectedList");
      assert(const DeepCollectionEquality().equals(list, expectedList));

      await database.close();
    });

    test("Demo clean", () async {
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
            "CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)");
      });

      // Insert some records in a transaction
      await database.inTransaction(() async {
        int id1 = await database.rawInsert(
            'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)');
        print("inserted1: $id1");
        int id2 = await database.rawInsert(
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
    });
  }
}
