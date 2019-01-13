import 'package:sqflite/sqflite.dart';
import 'test_page.dart';

class SlowTestPage extends TestPage {
  SlowTestPage() : super("Slow tests") {
    test("Perf 100 insert", () async {
      String path = await initDeleteDb("slow_txn_100_insert.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      await db.transaction((txn) async {
        for (int i = 0; i < 100; i++) {
          await txn
              .rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
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

      Stopwatch sw = Stopwatch()..start();
      await db.transaction((txn) async {
        for (int i = 0; i < 1000; i++) {
          await txn
              .rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
        }
      });
      print("1000 insert ${sw.elapsed}");
      await db.close();
    });

    test("Perf 1000 insert batch", () async {
      String path = await initDeleteDb("slow_txn_1000_insert_batch.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = Stopwatch()..start();
      Batch batch = db.batch();

      for (int i = 0; i < 1000; i++) {
        batch.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
      }
      await batch.commit();
      print("1000 insert batch ${sw.elapsed}");
      await db.close();
    });

    test("Perf 1000 insert batch no result", () async {
      String path =
          await initDeleteDb("slow_txn_1000_insert_batch_no_result.db");
      Database db = await openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = Stopwatch()..start();
      Batch batch = db.batch();

      for (int i = 0; i < 1000; i++) {
        batch.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
      }
      await batch.commit(noResult: true);

      print("1000 insert batch no result ${sw.elapsed}");
      await db.close();
    });

    int count = 10000;

    test("Perf $count item", () async {
      //Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("pref_${count}_items.db");
      Database db = await openDatabase(path);
      try {
        await db
            .execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

        Stopwatch sw = new Stopwatch()..start();
        Batch batch = db.batch();

        for (int i = 0; i < count; i++) {
          batch.rawInsert("INSERT INTO Test (name) VALUES (?)", ["item $i"]);
        }
        await batch.commit();
        print("sw ${sw.elapsed} insert $count items batch ");

        sw = new Stopwatch()..start();
        var result = await db.query('Test');
        print(
            "sw ${sw.elapsed} SELECT * From Test : ${result.length} items");

        sw = new Stopwatch()..start();
        result =
            await db.query('Test', where: 'name LIKE ?', whereArgs: ['%item%']);
        print(
            "sw ${sw.elapsed} SELECT * FROM Test WHERE name LIKE %item% ${result.length} items");

        sw = new Stopwatch()..start();
        result = await db
            .query('Test', where: 'name LIKE ?', whereArgs: ['%dummy%']);
        print(
            "sw ${sw.elapsed} SELECT * FROM Test WHERE name LIKE %dummy% ${result.length} items");
      } finally {
        await db.close();
      }
    });
  }
}
