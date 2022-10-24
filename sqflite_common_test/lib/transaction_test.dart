// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_common_test/src/sqflite_import.dart';
import 'package:test/test.dart';

/// Raw tests.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('transaction', () {
    test('Transaction', () async {
      var path = await context.initDeleteDb('simple_transaction.db');
      var db = await factory.openDatabase(path);
      try {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

        Future testInsert(int i) async {
          await db.transaction((txn) async {
            var count = utils.firstIntValue(
                await txn.rawQuery('SELECT COUNT(*) FROM Test'))!;
            await Future<dynamic>.delayed(const Duration(milliseconds: 40));
            await txn
                .rawInsert('INSERT INTO Test (name) VALUES (?)', ['item $i']);
            //print(await db.query('SELECT COUNT(*) FROM Test'));
            var afterCount = utils
                .firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM Test'));
            expect(count + 1, afterCount);
          });
        }

        var futures = <Future>[];
        for (var i = 0; i < 4; i++) {
          futures.add(testInsert(i));
        }
        await Future.wait<dynamic>(futures);
      } finally {
        await db.close();
      }
    });

    test('Concurrency 1', () async {
      // utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('simple_concurrency_1.db');
      var db = await factory.openDatabase(path);
      var step1 = Completer<dynamic>();
      var step2 = Completer<dynamic>();
      var step3 = Completer<dynamic>();

      Future action1() async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        step1.complete();

        await step2.future;
        try {
          await db
              .rawQuery('SELECT COUNT(*) FROM Test')
              .timeout(const Duration(seconds: 1));
          throw 'should fail';
        } catch (e) {
          expect(e is TimeoutException, true);
        }

        step3.complete();
      }

      Future action2() async {
        await db.transaction((txn) async {
          // Wait for table being created;
          await step1.future;
          await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 1']);
          step2.complete();

          await step3.future;

          var count = utils
              .firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM Test'));
          expect(count, 1);
        });
      }

      var future1 = action1();
      var future2 = action2();

      await Future.wait<dynamic>([future1, future2]);

      var count =
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(count, 1);

      await db.close();
    });

    test('Concurrency 2', () async {
      // utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('simple_concurrency_1.db');
      var db = await factory.openDatabase(path);
      var step1 = Completer<dynamic>();
      var step2 = Completer<dynamic>();
      var step3 = Completer<dynamic>();

      Future action1() async {
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        step1.complete();

        await step2.future;
        try {
          await db
              .rawQuery('SELECT COUNT(*) FROM Test')
              .timeout(const Duration(seconds: 1));
          throw 'should fail';
        } catch (e) {
          expect(e is TimeoutException, true);
        }

        step3.complete();
      }

      Future action2() async {
        // This is the change from concurrency 1
        // Wait for table being created;
        await step1.future;

        await db.transaction((txn) async {
          // Wait for table being created;
          await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 1']);
          step2.complete();

          await step3.future;

          var count = utils
              .firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM Test'));
          expect(count, 1);
        });
      }

      var future1 = action1();
      var future2 = action2();

      await Future.wait<dynamic>([future1, future2]);

      var count =
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(count, 1);

      await db.close();
    });

    test('Transaction recursive', () async {
      var path = await context.initDeleteDb('transaction_recursive.db');
      var db = await factory.openDatabase(path);

      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      // insert then fails to make sure the transaction is cancelled
      await db.transaction((txn) async {
        await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 1']);

        await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 2']);
      });
      var afterCount =
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(afterCount, 2);

      await db.close();
    });

    test('Transaction open twice', () async {
      //utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('transaction_open_twice.db');
      var db = await factory.openDatabase(path);

      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      var db2 = await factory.openDatabase(path);

      await db.transaction((txn) async {
        await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item']);
        var afterCount = utils
            .firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM Test'));
        expect(afterCount, 1);

        /*
        // this is not working on Android
        int db2AfterCount =
        utils.firstIntValue(await db2.rawQuery('SELECT COUNT(*) FROM Test'));
        assert(db2AfterCount == 0);
        */
      });
      var db2AfterCount =
          utils.firstIntValue(await db2.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(db2AfterCount, 1);

      var afterCount =
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(afterCount, 1);

      await db.close();
      await db2.close();
    });
    test('Transaction and concurrent call without synchronized', () async {
      // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);
      var db = await factory.openDatabase(inMemoryDatabasePath);
      // Special trick to avoid the built-in synchronization
      db.internalsDoNotUseSynchronized = true;
      try {
        var completer = Completer();
        var transactionFuture = db.transaction((txn) async {
          await completer.future;
        });
        var futureVersion = db.getVersion();
        await expectLater(
            () => futureVersion.timeout(const Duration(milliseconds: 500)),
            throwsA(isA<TimeoutException>()));
        completer.complete();
        expect(await futureVersion, 0);
        await transactionFuture;
      } finally {
        await db.close();
      }
    });

    test('Transaction and concurrent call and close without synchronized',
        () async {
      // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);
      var db = await factory.openDatabase(inMemoryDatabasePath);
      // Special trick to avoid the built-in synchronization
      db.internalsDoNotUseSynchronized = true;
      try {
        late Future futureVersion;
        var transactionFuture = db.transaction((txn) async {
          //await completer.future;
          futureVersion = db.getVersion();
          await db.close();
        });
        //var futureVersion = db.getVersion();
        //completer.complete();
        try {
          await transactionFuture;
          fail('Should fail');
        } on SqfliteDatabaseException catch (e) {
          expect(e.isDatabaseClosedError(), isTrue);
        }
        // Had time to succeed!
        expect(await futureVersion, 0);
      } finally {
        await db.close();
      }
    });
  });
}
