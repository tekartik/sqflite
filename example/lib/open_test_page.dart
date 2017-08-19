import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'test_page.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
      //await Sqflite.devSetDebugModeOn(true);
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
      print(list);
      assert(list.first["name"] == "simple value");
    });
  }
}
