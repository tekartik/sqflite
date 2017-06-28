import 'package:sqflite/sqflite.dart';
import 'test_page.dart';

class SlowTestPage extends TestPage {
  SlowTestPage() : super("Slow tests") {
    test("Perf 100 insert", () async {
      String path = await initDeleteDb("simple_test1.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      await db.inTransaction(() async {
        for (int i = 0; i < 100; i++) {
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
        }
      });
      await db.close();
    });

    test("Perf 100 insert no txn", () async {
      String path = await initDeleteDb("simple_test1.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      for (int i = 0; i < 1000; i++) {
        await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
      }
      await db.close();
    });

    test("Perf 1000 insert", () async {
      String path = await initDeleteDb("simple_test1.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      await db.inTransaction(() async {
        for (int i = 0; i < 1000; i++) {
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
        }
      });
      await db.close();
    });
  }
}
