import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Slow test.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('slow', () {
    test('Perf 100 insert', () async {
      var path = await context.initDeleteDb('slow_txn_100_insert.db');
      var db = await factory.openDatabase(path);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      await db.transaction((txn) async {
        for (var i = 0; i < 100; i++) {
          await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', [
            'item $i',
          ]);
        }
      });
      await db.close();
    });

    // Bigger timeout when using sqflite_server
    test('Perf 100 insert no txn', () async {
      var path = await context.initDeleteDb('slow_100_insert.db');
      var db = await factory.openDatabase(path);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      for (var i = 0; i < 1000; i++) {
        await db.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item $i']);
      }
      await db.close();
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Perf 1000 insert', () async {
      var path = await context.initDeleteDb('slow_txn_1000_insert.db');
      var db = await factory.openDatabase(path);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      var sw = Stopwatch()..start();
      await db.transaction((txn) async {
        for (var i = 0; i < 1000; i++) {
          await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', [
            'item $i',
          ]);
        }
      });
      print('1000 insert ${sw.elapsed}');
      await db.close();
    });

    test('Perf 1000 insert batch', () async {
      var path = await context.initDeleteDb('slow_txn_1000_insert_batch.db');
      var db = await factory.openDatabase(path);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      var sw = Stopwatch()..start();
      var batch = db.batch();

      for (var i = 0; i < 1000; i++) {
        batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item $i']);
      }
      await batch.commit();
      print('1000 insert batch ${sw.elapsed}');
      await db.close();
    });

    test('Perf 1000 insert batch no result', () async {
      var path = await context.initDeleteDb(
        'slow_txn_1000_insert_batch_no_result.db',
      );
      var db = await factory.openDatabase(path);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      var sw = Stopwatch()..start();
      var batch = db.batch();

      for (var i = 0; i < 1000; i++) {
        batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item $i']);
      }
      await batch.commit(noResult: true);

      print('1000 insert batch no result ${sw.elapsed}');
      await db.close();
    });
  });
}
