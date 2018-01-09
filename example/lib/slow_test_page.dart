import 'package:sqflite/sqflite.dart';
import 'test_page.dart';

class SlowTestPage extends TestPage {
  SlowTestPage() : super("Slow tests") {
    test("Perf 100 insert", () async {
      String path = await initDeleteDb("slow_txn_100_insert.db");
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
      String path = await initDeleteDb("slow_100_insert.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      for (int i = 0; i < 1000; i++) {
        await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
      }
      await db.close();
    });

    test("Perf 1000 insert", () async {
      String path = await initDeleteDb("slow_txn_1000_insert.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = new Stopwatch()..start();
      await db.inTransaction(() async {
        for (int i = 0; i < 1000; i++) {
          await db.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
        }
      });
      print("1000 insert ${sw.elapsed}");
      await db.close();
    });

    test("Perf 1000 insert batch", () async {
      String path = await initDeleteDb("slow_txn_1000_insert_batch.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = new Stopwatch()..start();
      Batch batch = db.batch();

      for (int i = 0; i < 1000; i++) {
        await batch
            .rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
      }
      await db.inTransaction(() async {
        await batch.commit();
      });
      print("1000 insert batch ${sw.elapsed}");
      await db.close();
    });

    test("Perf 1000 insert batch no result", () async {
      String path =
          await initDeleteDb("slow_txn_1000_insert_batch_no_result.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = new Stopwatch()..start();
      Batch batch = db.batch();

      for (int i = 0; i < 1000; i++) {
        await batch
            .rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
      }
      await db.inTransaction(() async {
        await batch.commit(noResult: true);
      });
      print("1000 insert batch no result ${sw.elapsed}");
      await db.close();
    });
  }
}
