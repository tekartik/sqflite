import 'package:sqflite/sqflite.dart';
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
  }
}
