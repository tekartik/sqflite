import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/test_page.dart';

class OpenTestPage extends TestPage {
  OpenTestPage() : super("Open tests") {
    test("Delete database", () async {
      //await Sqflite.devSetDebugModeOn(false);
      String path = await initDeleteDb("delete_database.db");
      Database db = await openDatabase(path);
      await db.close();
      assert((await new File(path).exists()) == true);
      print("Deleting database $path");
      await deleteDatabase(path);
      assert((await new File(path).exists()) == false);
    });

    test("Open no version", () async {
      String path = await initDeleteDb("open_no_version.db");
      assert((await new File(path).exists()) == false);
      Database db = await openDatabase(path);
      assert((await new File(path).exists()) == true);
      await db.close();
    });

    test("Open no version onCreate", () async {
      // should fail
      String path = await initDeleteDb("open_no_version_on_create.db");
      assert((await new File(path).exists()) == false);
      Database db;
      try {
        db = await openDatabase(path, onCreate: (Database db, int version) {
          // never called
          assert(false);
        });
        assert(false);
      } on ArgumentError catch (_) {}
      assert((await new File(path).exists()) == false);
      assert(db == null);
    });

    test("Open onCreate", () async {
      String path = await initDeleteDb("open_test2.db");
      bool onCreate = false;
      Database db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) {
        assert(version == 1);
        onCreate = true;
      });
      assert(onCreate);
      await db.close();
    });

    test("Open onUpgrade", () async {
      bool onUpgrade = false;
      String path = await initDeleteDb("open_test3.db");
      Database database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      });
      await database.close();
      database = await openDatabase(path, version: 2,
          onUpgrade: (Database db, int oldVersion, int newVersion) async {
        assert(oldVersion == 1);
        assert(newVersion == 2);
        await db.execute("ALTER TABLE Test ADD name TEXT");
        onUpgrade = true;
      });
      assert(onUpgrade);
      await database.close();
    });

    test("Open onDowngrade", () async {
      String path = await initDeleteDb("open_on_downgrade.db");
      Database database = await openDatabase(path, version: 2,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      }, onDowngrade: (Database db, int oldVersion, int newVersion) async {
        assert(false, "should not be called");
      });
      await database.close();

      bool onDowngrade = false;
      database = await openDatabase(path, version: 1,
          onDowngrade: (Database db, int oldVersion, int newVersion) async {
        assert(oldVersion == 2);
        assert(newVersion == 1);
        await db.execute("ALTER TABLE Test ADD name TEXT");
        onDowngrade = true;
      });
      assert(onDowngrade);

      await database.close();
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

    test("Open bad path", () async {
      try {
        await openDatabase("/invalid_path");
        assert(false);
      } on DatabaseException catch (e) {
        assert(e.isOpenFailedError());
      }
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
