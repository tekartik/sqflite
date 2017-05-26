import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/test_page.dart';

class OpenTestPage extends TestPage {
  OpenTestPage() : super("Open tests") {
    test("Open no version", () async {
      String path = await initDeleteDb("open_test1.db");
      assert((await new File(path).exists()) == false);
      Database db = await openDatabase(path);
      assert((await new File(path).exists()) == true);
      await db.close();
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
  }
}
