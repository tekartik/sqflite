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
      assert(!onConfigureCalled); // onConfigure must be called once
      onConfigureCalled = true;
    };

    onCreate = (Database db, int version) {
      //print("onCreate");
      assert(onConfigureCalled);
      assert(!onCreateCalled);
      onCreateCalled = true;
    };

    onOpen = (Database db) {
      //print("onOpen");
      verify(onConfigureCalled, "onConfigure must be called before onOpen");
      assert(!onOpenCalled);
      onOpenCalled = true;
    };

    onUpgrade = (Database db, int oldVersion, int newVersion) {
      assert(onConfigureCalled);
      assert(!onUpgradeCalled);
      onUpgradeCalled = true;
    };

    onDowngrade = (Database db, int oldVersion, int newVersion) {
      assert(onConfigureCalled);
      assert(!onDowngradeCalled);
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
      assert((await new File(path).exists()) == true);
      print("Deleting database $path");
      await deleteDatabase(path);
      assert((await new File(path).exists()) == false);
    });

    test("Open no version", () async {
      //await Sqflite.devSetDebugModeOn(true);
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
      // await Sqflite.devSetDebugModeOn(true);
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

    test("Open bad path", () async {
      try {
        await openDatabase("/invalid_path");
        assert(false);
      } on DatabaseException catch (e) {
        assert(e.isOpenFailedError());
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
      assert(list.first["name"] == "simple value");

      await db.close();
    });

    test("Open on configure", () async {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, "open_on_configure.db");
      bool onConfigured = false;
      Future _onConfigure(Database db) async {
        onConfigured = true;
      }

      var db = await openDatabase(path, onConfigure: _onConfigure);
      assert(onConfigured);

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
        assert(!onConfigured);
        assert(!onCreated);
        if (!onConfiguredOnce) {
          // first time
          onConfiguredOnce = true;
        } else {
          onConfigured = true;
        }
      }, onCreate: (Database db, int version) {
        assert(onConfigured);
        assert(!onCreated);
        assert(!onOpened);
        onCreated = true;
        assert(version == 2);
      }, onOpen: (Database db) {
        assert(onCreated);
        onOpened = true;
      }, onDowngrade: onDatabaseDowngradeDelete);
      await database.close();

      assert(onCreated);
      assert(onOpened);
      assert(onConfigured);

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

    test("All open callback", () async {
      String path = await initDeleteDb("open_all_callbacks.db");

      OpenCallbacks openCallbacks = new OpenCallbacks();
      var db = await openCallbacks.open(path, version: 1);
      assert(openCallbacks.onConfigureCalled);
      assert(openCallbacks.onCreateCalled);
      assert(openCallbacks.onOpenCalled);
      assert(!openCallbacks.onUpgradeCalled);
      assert(!openCallbacks.onDowngradeCalled);
      await db.close();

      db = await openCallbacks.open(path, version: 3);
      assert(openCallbacks.onConfigureCalled);
      assert(!openCallbacks.onCreateCalled);
      assert(openCallbacks.onOpenCalled);
      assert(openCallbacks.onUpgradeCalled);
      assert(!openCallbacks.onDowngradeCalled);
      await db.close();

      db = await openCallbacks.open(path, version: 2);
      assert(openCallbacks.onConfigureCalled);
      assert(!openCallbacks.onCreateCalled);
      assert(openCallbacks.onOpenCalled);
      assert(!openCallbacks.onUpgradeCalled);
      assert(openCallbacks.onDowngradeCalled);
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

      assert(openCallbacks.onConfigureCalled);
      assert(configureCount == 2);
      assert(openCallbacks.onCreateCalled);
      assert(openCallbacks.onOpenCalled);
      assert(!openCallbacks.onUpgradeCalled);
      assert(!openCallbacks.onDowngradeCalled);
      await db.close();
    });
  }
}
