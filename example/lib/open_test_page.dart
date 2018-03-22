import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/src/utils.dart';
import 'test_page.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class OpenCallbacks {
  bool onConfigureCalled;
  bool onOpenCalled;
  bool onCreateCalled;
  bool onDowngradeCalled;
  bool onUpgradeCalled;
  void reset() {
    onConfigureCalled = false;
    onOpenCalled = false;
    onCreateCalled = false;
    onDowngradeCalled = false;
    onUpgradeCalled = false;
  }

  OnDatabaseCreateFn onCreate;
  OnDatabaseConfigureFn onConfigure;
  OnDatabaseVersionChangeFn onDowngrade;
  OnDatabaseVersionChangeFn onUpgrade;
  OnDatabaseOpenFn onOpen;

  OpenCallbacks() {
    onConfigure = (Database db) {
      //print("onConfigure");
      //verify(!onConfigureCalled, "onConfigure must be called once");
      expect(onConfigureCalled, false); // onConfigure must be called once
      onConfigureCalled = true;
    };

    onCreate = (Database db, int version) {
      //print("onCreate");
      expect(onConfigureCalled, true);
      expect(onCreateCalled, false);
      onCreateCalled = true;
    };

    onOpen = (Database db) {
      //print("onOpen");
      verify(onConfigureCalled, "onConfigure must be called before onOpen");
      verify(!onOpenCalled);
      onOpenCalled = true;
    };

    onUpgrade = (Database db, int oldVersion, int newVersion) {
      verify(onConfigureCalled);
      verify(!onUpgradeCalled);
      onUpgradeCalled = true;
    };

    onDowngrade = (Database db, int oldVersion, int newVersion) {
      verify(onConfigureCalled);
      verify(!onDowngradeCalled);
      onDowngradeCalled = true;
    };

    reset();
  }

  Future<Database> open(String path, {int version}) async {
    reset();
    return openDatabase(path,
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen);
  }
}

class OpenTestPage extends TestPage {
  OpenTestPage() : super("Open tests") {
    test("Delete database", () async {
      //await Sqflite.devSetDebugModeOn(false);
      String path = await initDeleteDb("delete_database.db");
      Database db = await openDatabase(path);
      await db.close();
      expect((await new File(path).exists()), true);
      print("Deleting database $path");
      await deleteDatabase(path);
      expect((await new File(path).exists()), false);
    });

    test("Open no version", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("open_no_version.db");
      expect((await new File(path).exists()), false);
      Database db = await openDatabase(path);
      verify(await new File(path).exists());
      await db.close();
    });

    test("Open no version onCreate", () async {
      // should fail
      String path = await initDeleteDb("open_no_version_on_create.db");
      verify(!(await new File(path).exists()));
      Database db;
      try {
        db = await openDatabase(path, onCreate: (Database db, int version) {
          // never called
          verify(false);
        });
        verify(false);
      } on ArgumentError catch (_) {}
      verify(!await new File(path).exists());
      expect(db, null);
    });

    test("Open onCreate", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("open_test2.db");
      bool onCreate = false;
      bool onCreateTransaction = false;
      Database db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        expect(version, 1);
        onCreate = true;

        await db.transaction((txn) async {
          await txn.execute("CREATE TABLE Test2 (id INTEGER PRIMARY KEY)");
          onCreateTransaction = true;
        });
      });
      verify(onCreate);
      expect(onCreateTransaction, true);
      await db.close();
    });

    test("Open 2 databases", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path1 = await initDeleteDb("open_db_1.db");
      String path2 = await initDeleteDb("open_db_2.db");
      Database db1 = await openDatabase(path1, version: 1);
      Database db2 = await openDatabase(path2, version: 1);
      await db1.close();
      await db2.close();
    });

    test("Open onUpgrade", () async {
      bool onUpgrade = false;
      String path = await initDeleteDb("open_on_upgrade.db");
      Database database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      });
      await database.close();
      database = await openDatabase(path, version: 2,
          onUpgrade: (Database db, int oldVersion, int newVersion) async {
        expect(oldVersion, 1);
        expect(newVersion, 2);
        await db.execute("ALTER TABLE Test ADD name TEXT");
        onUpgrade = true;
      });
      verify(onUpgrade);
      await database.close();
    });

    test("Open onDowngrade", () async {
      String path = await initDeleteDb("open_on_downgrade.db");
      Database database = await openDatabase(path, version: 2,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      }, onDowngrade: (Database db, int oldVersion, int newVersion) async {
        verify(false, "should not be called");
      });
      await database.close();

      bool onDowngrade = false;
      database = await openDatabase(path, version: 1,
          onDowngrade: (Database db, int oldVersion, int newVersion) async {
        expect(oldVersion, 2);
        expect(newVersion, 1);
        await db.execute("ALTER TABLE Test ADD name TEXT");
        onDowngrade = true;
      });
      verify(onDowngrade);

      await database.close();
    });

    test("Open bad path", () async {
      try {
        await openDatabase("/invalid_path");
        fail();
      } on DatabaseException catch (e) {
        verify(e.isOpenFailedError());
      }
    });

    test("Open asset database", () async {
      // await Sqflite.devSetDebugModeOn(false);
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, "asset_example.db");

      // delete existing if any
      await deleteDatabase(path);

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "example.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await new File(path).writeAsBytes(bytes);

      // open the database
      Database db = await openDatabase(path);

      // Our database as a single table with a single element
      List<Map<String, dynamic>> list = await db.rawQuery("SELECT * FROM Test");
      print("list $list");
      expect(list.first["name"], "simple value");

      await db.close();
    });

    test("Open on configure", () async {
      String path = await initDeleteDb("open_on_configure.db");

      bool onConfigured = false;
      bool onConfiguredTransaction = false;
      Future _onConfigure(Database db) async {
        onConfigured = true;
        await db.execute("CREATE TABLE Test1 (id INTEGER PRIMARY KEY)");
        await db.transaction((txn) async {
          await txn.execute("CREATE TABLE Test2 (id INTEGER PRIMARY KEY)");
          onConfiguredTransaction = true;
        });
      }

      var db = await openDatabase(path, onConfigure: _onConfigure);
      expect(onConfigured, true);
      expect(onConfiguredTransaction, true);

      await db.close();
    });

    test("Open onDowngrade delete", () async {
      // await Sqflite.devSetDebugModeOn(false);

      String path = await initDeleteDb("open_on_downgrade_delete.db");
      Database database = await openDatabase(path, version: 3,
          onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
      });
      await database.close();

      // should fail going back in versions
      bool onCreated = false;
      bool onOpened = false;
      bool onConfiguredOnce = false; // onConfigure will be called twice here
      // since the database is re-opened
      bool onConfigured = false;
      database =
          await openDatabase(path, version: 2, onConfigure: (Database db) {
        // Must not be configured nor created yet
        verify(!onConfigured);
        verify(!onCreated);
        if (!onConfiguredOnce) {
          // first time
          onConfiguredOnce = true;
        } else {
          onConfigured = true;
        }
      }, onCreate: (Database db, int version) {
        verify(onConfigured);
        verify(!onCreated);
        verify(!onOpened);
        onCreated = true;
        expect(version, 2);
      }, onOpen: (Database db) {
        verify(onCreated);
        onOpened = true;
      }, onDowngrade: onDatabaseDowngradeDelete);
      await database.close();

      expect(onCreated, true);
      expect(onOpened, true);
      expect(onConfigured, true);

      onCreated = false;
      onOpened = false;

      database = await openDatabase(path, version: 2,
          onCreate: (Database db, int version) {
        expect(false, "should not be called");
      }, onOpen: (Database db) {
        onOpened = true;
      }, onDowngrade: onDatabaseDowngradeDelete);
      expect(onOpened, true);
      await database.close();
    });

    test("All open callback", () async {
      String path = await initDeleteDb("open_all_callbacks.db");

      OpenCallbacks openCallbacks = new OpenCallbacks();
      var db = await openCallbacks.open(path, version: 1);
      verify(openCallbacks.onConfigureCalled);
      verify(openCallbacks.onCreateCalled);
      verify(openCallbacks.onOpenCalled);
      verify(!openCallbacks.onUpgradeCalled);
      verify(!openCallbacks.onDowngradeCalled);
      await db.close();

      db = await openCallbacks.open(path, version: 3);
      verify(openCallbacks.onConfigureCalled);
      verify(!openCallbacks.onCreateCalled);
      verify(openCallbacks.onOpenCalled);
      verify(openCallbacks.onUpgradeCalled);
      verify(!openCallbacks.onDowngradeCalled);
      await db.close();

      db = await openCallbacks.open(path, version: 2);
      verify(openCallbacks.onConfigureCalled);
      verify(!openCallbacks.onCreateCalled);
      verify(openCallbacks.onOpenCalled);
      verify(!openCallbacks.onUpgradeCalled);
      verify(openCallbacks.onDowngradeCalled);
      await db.close();

      openCallbacks.onDowngrade = onDatabaseDowngradeDelete;
      int configureCount = 0;
      var callback = openCallbacks.onConfigure;
      // allow being called twice
      openCallbacks.onConfigure = (Database db) {
        if (configureCount == 1) {
          openCallbacks.onConfigureCalled = false;
        }
        configureCount++;
        callback(db);
      };
      db = await openCallbacks.open(path, version: 1);

      verify(openCallbacks.onConfigureCalled);
      verify(configureCount == 2);
      verify(openCallbacks.onCreateCalled);
      verify(openCallbacks.onOpenCalled);
      verify(!openCallbacks.onUpgradeCalled);
      verify(!openCallbacks.onDowngradeCalled);
      await db.close();
    });

    test("Open batch", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("open_batch.db");

      Future _onConfigure(Database db) async {
        var batch = db.batch();
        batch.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
        await batch.commit();
      }

      Future _onCreate(Database db, int version) async {
        var batch = db.batch();
        batch.rawInsert('INSERT INTO Test(value) VALUES("value1")');
        await batch.commit();
      }

      Future _onOpen(Database db) async {
        var batch = db.batch();
        batch.rawInsert('INSERT INTO Test(value) VALUES("value2")');
        await batch.commit();
      }

      var db = await openDatabase(path,
          version: 1,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onOpen: _onOpen);
      expect(
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test")),
          2);

      await db.close();
    });

    test("Open read-only", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("open_read_only.db");

      Future _onCreate(Database db, int version) async {
        var batch = db.batch();
        batch.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
        batch.rawInsert('INSERT INTO Test(value) VALUES("value1")');
        await batch.commit();
      }

      var db = await openDatabase(path, version: 1, onCreate: _onCreate);
      expect(
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test")),
          1);

      await db.close();

      db = await openReadOnlyDatabase(path);
      expect(
          Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test")),
          1);

      try {
        await db.rawInsert('INSERT INTO Test(value) VALUES("value1")');
        fail("should fail");
      } on DatabaseException catch (e) {
        // Error DatabaseException(attempt to write a readonly database (code 8)) running Open read-only
        expect(e.isReadOnlyError(), true);
      }

      var batch = db.batch();
      batch.rawQuery("SELECT COUNT(*) FROM Test");
      await batch.commit();

      await db.close();
    });

    test('Open demo (doc)', () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("open_read_only.db");

      {
        _onConfigure(Database db) async {
          // Add support for cascade delete
          await db.execute("PRAGMA foreign_keys = ON");
        }

        var db = await openDatabase(path, onConfigure: _onConfigure);
        await db.close();
      }

      {
        _onCreate(Database db, int version) async {
          // Database is created, delete the table
          await db.execute(
              "CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
        }

        _onUpgrade(Database db, int oldVersion, int newVersion) async {
          // Database version is updated, alter the table
          await db.execute("ALTER TABLE Test ADD name TEXT");
        }

        // Special callback used for onDowngrade here to recreate the database
        var db = await openDatabase(path,
            version: 1,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            onDowngrade: onDatabaseDowngradeDelete);
        await db.close();
      }

      {
        _onOpen(Database db) async {
          // Database is open, print its version
          print('db version ${await db.getVersion()}');
        }

        var db = await openDatabase(
          path,
          onOpen: _onOpen,
        );
        await db.close();
      }
    });
  }
}
