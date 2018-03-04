import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/src/utils.dart';

import 'test_page.dart';

class DeprecatedTestPage extends TestPage {
  DeprecatedTestPage() : super("Deprecated transaction tests") {
    test("Transaction", () async {
      //Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("simple_transaction.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      _test(int i) async {
        // ignore: deprecated_member_use
        await db.inTransaction(() async {
          int count = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
          await new Future.delayed(new Duration(milliseconds: 40));
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
          //print(await db.query("SELECT COUNT(*) FROM Test"));
          int afterCount = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
          expect(count + 1, afterCount);
        });
      }

      List<Future> futures = [];
      for (int i = 0; i < 4; i++) {
        futures.add(_test(i));
      }
      await Future.wait(futures);
      await db.close();
    });

    test("Concurrency 1", () async {
      // Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("simple_concurrency.db");
      Database db = await openDatabase(path);
      var step1 = new Completer();
      var step2 = new Completer();
      var step3 = new Completer();

      Future action1() async {
        await db
            .execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
        step1.complete();

        await step2.future;
        try {
          var map = await db
              .rawQuery("SELECT COUNT(*) FROM Test")
              .timeout(new Duration(seconds: 1));
          throw "should fail ($map)";
        } catch (e) {
          expect(e is TimeoutException, true);
        }

        step3.complete();
      }

      Future action2() async {
        await step1.future;

        // ignore: deprecated_member_use
        await db.inTransaction(() async {
          // Wait for table being created;

          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item 1"]);
          step2.complete();

          await step3.future;

          int count = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
          expect(count, 1);
        });
      }

      var future1 = action1();
      var future2 = action2();

      await Future.wait([future1, future2]);

      int count =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      expect(count, 1);

      await db.close();
    });

    test("Concurrency 2", () async {
      // Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("simple_concurrency.db");
      Database db = await openDatabase(path);
      var step1 = new Completer();
      var step2 = new Completer();

      Future action1() async {
        await step1.future;

        try {
          var map = await db
              .rawQuery("SELECT COUNT(*) FROM Test")
              .timeout(new Duration(seconds: 1));
          throw "should fail ($map)";
        } catch (e) {
          expect(e is TimeoutException, true);
        }

        step2.complete();
      }

      Future action2() async {
        // this is the change from concurrency 1
        // Wait for table being created;

        // ignore: deprecated_member_use
        await db.inTransaction(() async {
          await db
              .execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

          step1.complete();

          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item 1"]);

          await step2.future;

          int count = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
          expect(count, 1);
        });
      }

      var future1 = action1();
      var future2 = action2();

      await Future.wait([future1, future2]);

      int count =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      expect(count, 1);

      await db.close();
    });

    test("Transaction recursive", () async {
      String path = await initDeleteDb("transaction_recursive.db");
      Database db = await openDatabase(path);

      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      // insert then fails to make sure the transaction is cancelled
      // ignore: deprecated_member_use
      await db.inTransaction(() async {
        await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item 1"]);

        // ignore: deprecated_member_use
        await db.inTransaction(() async {
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item 2"]);
        });
      });
      int afterCount =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      expect(afterCount, 2);

      await db.close();
    });

    test("Transaction open twice", () async {
      //Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("transaction_open_twice.db");
      Database db = await openDatabase(path);

      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Database db2 = await openDatabase(path);

      // ignore: deprecated_member_use
      await db.inTransaction(() async {
        await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item"]);
        int afterCount = Sqflite
            .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
        expect(afterCount, 1);

        /*
        // this is not working on Android
        int db2AfterCount =
        Sqflite.firstIntValue(await db2.rawQuery("SELECT COUNT(*) FROM Test"));
        assert(db2AfterCount == 0);
        */
      });
      int db2AfterCount = Sqflite
          .firstIntValue(await db2.rawQuery("SELECT COUNT(*) FROM Test"));
      expect(db2AfterCount, 1);

      int afterCount =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      expect(afterCount, 1);

      await db.close();
      await db2.close();
    });

    test("Demo clean", () async {
      // Get a location using path_provider
      Directory documentsDirectory = await getApplicationDocumentsDirectory();

      // Make sure the directory exists
      try {
        documentsDirectory.create(recursive: true);
      } catch (_) {}

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
      // ignore: deprecated_member_use
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
      //assert(const DeepCollectionEquality().equals(list, expectedList));
      expect(list, expectedList);

      // Count the records
      count = Sqflite
          .firstIntValue(await database.rawQuery("SELECT COUNT(*) FROM Test"));
      expect(count, 2);

      // Delete a record
      count = await database
          .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
      expect(count, 1);

      // Close the database
      await database.close();
    });

    test('BatchQuery', () async {
      // await Sqflite.devSetDebugModeOn();
      String path = await initDeleteDb("batch.db");
      Database db = await openDatabase(path);

      // empty batch
      Batch batch = db.batch();
      batch.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      batch.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item1"]);
      var results = await batch.apply();
      expect(results, [null, 1]);

      var dbResult = await db.rawQuery("SELECT id, name FROM Test");
      // devPrint("dbResult $dbResult");
      expect(dbResult, [
        {"id": 1, "name": "item1"}
      ]);

      // one query
      batch = db.batch();
      batch.rawQuery("SELECT id, name FROM Test");
      batch.query("Test", columns: ["id", "name"]);
      results = await batch.apply();
      // devPrint("select $results ${results?.first}");
      expect(results, [
        [
          {"id": 1, "name": "item1"}
        ],
        [
          {"id": 1, "name": "item1"}
        ]
      ]);
      await db.close();
    });
    test('Batch', () async {
      // await Sqflite.devSetDebugModeOn();
      String path = await initDeleteDb("batch.db");
      Database db = await openDatabase(path);

      // empty batch
      Batch batch = db.batch();
      var results = await batch.apply();
      expect(results.length, 0);
      expect(results, []);

      // one create table
      batch = db.batch();
      batch.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      results = await batch.apply();
      // devPrint("1 $results ${results?.first}");
      expect(results, [null]);
      expect(results[0], null);

      // one insert
      batch = db.batch();
      batch.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item1"]);
      results = await batch.apply();
      expect(results, [1]);

      // one query
      batch = db.batch();
      batch.rawQuery("SELECT id, name FROM Test");
      batch.query("Test", columns: ["id", "name"]);
      results = await batch.apply();
      // devPrint("select $results ${results?.first}");
      expect(results, [
        [
          {"id": 1, "name": "item1"}
        ],
        [
          {"id": 1, "name": "item1"}
        ]
      ]);

      // two insert
      batch = db.batch();
      batch.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item2"]);
      batch.insert("Test", {"name": "item3"});
      results = await batch.apply();
      expect(results, [2, 3]);

      // update
      batch = db.batch();
      batch.rawUpdate(
          "UPDATE Test SET name = ? WHERE name = ?", ["new_item", "item1"]);
      batch.update("Test", {"name": "new_other_item"},
          where: "name != ?", whereArgs: <String>["new_item"]);
      results = await batch.apply();
      expect(results, [1, 2]);

      // delete
      batch = db.batch();
      batch.rawDelete("DELETE FROM Test WHERE name = ?", ["new_item"]);
      batch.delete("Test",
          where: "name = ?", whereArgs: <String>["new_other_item"]);
      results = await batch.apply();
      expect(results, [1, 2]);

      // No result
      batch = db.batch();
      batch.insert("Test", {"name": "item"});
      batch.update("Test", {"name": "new_item"},
          where: "name = ?", whereArgs: <String>["item"]);
      batch.delete("Test", where: "name = ?", whereArgs: ["item"]);
      results = await batch.apply(noResult: true);
      expect(results, null);

      await db.close();
    });

    //
    // Exception
    //
    test("Transaction failed", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("transaction_failed.db");
      Database db = await openDatabase(path);

      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      // insert then fails to make sure the transaction is cancelled
      bool hasFailed = false;
      try {
        // ignore: deprecated_member_use
        await db.inTransaction(() async {
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item"]);
          int afterCount = Sqflite
              .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
          expect(afterCount, 1);

          hasFailed = true;
          // this failure should cancel the insertion before
          await db.execute("DUMMY CALL");
          hasFailed = false;
        });
      } catch (e) {
        // iOS: native_error: PlatformException(sqlite_error, Error Domain=FMDatabase Code=1 "near "DUMMY": syntax error" UserInfo={NSLocalizedDescription=near "DUMMY": syntax error}, null)
        print("native_error: $e");
      }
      verify(hasFailed);

      int afterCount =
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test"));
      expect(afterCount, 0);

      await db.close();
    });
  }
}
