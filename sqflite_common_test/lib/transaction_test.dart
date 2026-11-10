// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:math';

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
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
        );

        Future testInsert(int i) async {
          await db.transaction((txn) async {
            var count = utils.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM Test'),
            )!;
            await Future<dynamic>.delayed(const Duration(milliseconds: 40));
            await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', [
              'item $i',
            ]);
            //print(await db.query('SELECT COUNT(*) FROM Test'));
            var afterCount = utils.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM Test'),
            );
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
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
        );
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

          var count = utils.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM Test'),
          );
          expect(count, 1);
        });
      }

      var future1 = action1();
      var future2 = action2();

      await Future.wait<dynamic>([future1, future2]);

      var count = utils.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Test'),
      );
      expect(count, 1);

      await db.close();
    });

    test('Concurrency 2', () async {
      // utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('simple_concurrency_2.db');
      var db = await factory.openDatabase(path);
      var step1 = Completer<dynamic>();
      var step2 = Completer<dynamic>();
      var step3 = Completer<dynamic>();

      Future action1() async {
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
        );
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

          var count = utils.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM Test'),
          );
          expect(count, 1);
        });
      }

      var future1 = action1();
      var future2 = action2();

      await Future.wait<dynamic>([future1, future2]);

      var count = utils.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Test'),
      );
      expect(count, 1);

      await db.close();
    });

    test('Concurrency 3', () async {
      // utils.devSetDebugModeOn(true);
      Future createTable(Database db) {
        return db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
        );
      }

      Future insertMany({
        required DatabaseExecutor executor,
        required String name,
        required int count,
        required void Function(int index) onOneInsert,
      }) async {
        var all = Completer<dynamic>();
        var completeCount = 0;

        final random = Random();
        for (var i = 0; i < count; i++) {
          unawaited(
            executor
                .rawInsert('INSERT INTO Test (name) VALUES (?)', ['$name $i'])
                .then((_) {
                  onOneInsert(i);
                  completeCount++;
                  if (completeCount == count) {
                    all.complete(null);
                  }
                }),
          );
          // Make random gaps so calls of other database are able to cut the
          // queue. And the test will not accidentally pass because of lack
          // of 'concurrency'.
          await Future<void>.delayed(
            Duration(microseconds: random.nextInt(50)),
          );
        }
        return all.future;
      }

      Future<int> countRows(Database db) async {
        return utils.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM Test'),
        )!;
      }

      void expectInOrder(Map<int, int> orders) {
        for (var i = 1; i < orders.length; i++) {
          expect(orders[i - 1]! < orders[i]!, true);
        }
      }

      var path1 = await context.initDeleteDb('concurrency_1.db');
      var db1 = await factory.openDatabase(path1);
      var completeOrder1 = <int, int>{};
      await createTable(db1);

      var path2 = await context.initDeleteDb('concurrency_2.db');
      var db2 = await factory.openDatabase(path2);
      var completeOrder2 = <int, int>{};
      await createTable(db2);

      var path3 = await context.initDeleteDb('concurrency_3.db');
      var db3 = await factory.openDatabase(path3);
      var completeOrder3 = <int, int>{};
      await createTable(db3);

      var completeCount = 0;

      // Run following actions.
      // db1: insert 1000 rows
      // db2: make 100 transactions and each one insert 10 rows
      // db3: make 10 transactions ane each one insert 100 rows

      var future1 = insertMany(
        executor: db1,
        name: 'db1',
        count: 1000,
        onOneInsert: (index) {
          completeOrder1[index] = completeCount++;
        },
      );

      var future2 = Future.wait([
        for (var i = 0; i < 100; i++)
          db2.transaction(
            (txn) => insertMany(
              executor: txn,
              name: 'db2',
              count: 10,
              onOneInsert: (index) {
                final offset = i * 10 + index;
                completeOrder2[offset] = completeCount++;
              },
            ),
          ),
      ]);

      var future3 = Future.wait([
        for (var i = 0; i < 10; i++)
          db3.transaction(
            (txn) => insertMany(
              executor: txn,
              name: 'db3',
              count: 100,
              onOneInsert: (index) {
                final offset = i * 100 + index;
                completeOrder3[offset] = completeCount++;
              },
            ),
          ),
      ]);

      await Future.wait([future1, future2, future3]);

      // All inserts and transactions success.
      // (no thread hop during transaction).
      expect(await countRows(db1), 1000);
      expect(await countRows(db2), 1000);
      expect(await countRows(db3), 1000);

      // Tasks of same db run in FIFO manner.
      expectInOrder(completeOrder1);
      expectInOrder(completeOrder2);
      expectInOrder(completeOrder3);

      await db1.close();
      await db2.close();
      await db3.close();
    }, timeout: const Timeout(Duration(seconds: 150)));

    test('Transaction recursive', () async {
      var path = await context.initDeleteDb('transaction_recursive.db');
      var db = await factory.openDatabase(path);

      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      // insert then fails to make sure the transaction is cancelled
      await db.transaction((txn) async {
        await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 1']);

        await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 2']);
      });
      var afterCount = utils.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Test'),
      );
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
        var afterCount = utils.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM Test'),
        );
        expect(afterCount, 1);

        /*
        // this is not working on Android
        int db2AfterCount =
        utils.firstIntValue(await db2.rawQuery('SELECT COUNT(*) FROM Test'));
        assert(db2AfterCount == 0);
        */
      });
      var db2AfterCount = utils.firstIntValue(
        await db2.rawQuery('SELECT COUNT(*) FROM Test'),
      );
      expect(db2AfterCount, 1);

      var afterCount = utils.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Test'),
      );
      expect(afterCount, 1);

      await db.close();
      await db2.close();
    });
    test('Transaction query cursor closed early', () async {
      var path = await context.initDeleteDb('transaction_cursor_close.db');
      var db = await factory.openDatabase(path);
      try {
        await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
        var batch = db.batch();
        for (var i = 1; i <= 3; i++) {
          batch.insert('Test', <String, Object?>{'id': i});
        }
        await batch.commit(noResult: true);
        // Closing a cursor before its end in a transaction used to hang.
        var id = await db
            .transaction((txn) async {
              var cursor = await txn.queryCursor(
                'Test',
                orderBy: 'id',
                bufferSize: 1,
              );
              expect(await cursor.moveNext(), isTrue);
              var id = cursor.current['id'];
              await cursor.close();
              return id;
            })
            .timeout(const Duration(seconds: 10));
        expect(id, 1);
      } finally {
        await db.close();
      }
    });

    test('Transaction and concurrent call without synchronized', () async {
      // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);
      var db = await factory.openDatabase(inMemoryDatabasePath);
      // Special trick to avoid the built-in synchronization
      db.internalsDoNotUseSynchronized = true;
      try {
        var completer = Completer<void>();
        unawaited(
          db.transaction((txn) async {
            await txn.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
            await completer.future;
          }),
        );
        var futureVersion = db.getVersion();
        var futureUpdate = db.update('Test', <String, Object?>{'id': 1});
        var futureQuery = db.queryCursor('Test');
        var futureInsert = db.insert('Test', <String, Object?>{'id': 1});
        var futureQueryCursor = db.queryCursor('Test', bufferSize: 1);
        var futureExecute = db.execute('PRAGMA user_version = 1');

        var futures = [
          futureVersion,
          futureUpdate,
          futureQuery,
          futureQueryCursor,
          futureInsert,
          futureExecute,
        ];
        await Future.wait(
          futures.map(
            (e) => expectLater(
              () => e.timeout(const Duration(milliseconds: 500)),
              throwsA(isA<TimeoutException>()),
            ),
          ),
        );

        completer.complete();
        expect(await futureVersion, 0);
        expect(await futureUpdate, 0);
        var cursor = await futureQueryCursor;
        await cursor.close();
        await futureExecute;
        // await transactionFuture;
      } finally {
        await db.close();
      }
    });

    test(
      'Transaction and concurrent call and close without synchronized',
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
      },
    );
    test('simple readTransaction', () async {
      var path = await context.initDeleteDb('simple_read_transaction.db');
      var db = await factory.openDatabase(path);
      await db.execute(
        'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
      );
      await db.insert('Test', {'name': 'test'});

      var result = await db.readTransaction((txn) async {
        return await txn.query('Test');
      });

      expect(result, [
        {'id': 1, 'name': 'test'},
      ]);
    });
    test('write in readTransaction', () async {
      var path = await context.initDeleteDb('write_in_read_transaction.db');
      var db = await factory.openDatabase(path);
      try {
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
        );
        try {
          var id = await db.readTransaction((txn) async {
            return await txn.insert('Test', {'name': 'test'});
          });
          expect(id, 1);
        } on DatabaseException catch (_) {
          // State error in sqlite_async impl.
        }

        expect(await db.query('Test'), isEmpty);
      } finally {
        await db.close();
      }
    });

    test('concurrent readTransactions', () async {
      var path = await context.initDeleteDb('concurrent_read_transaction.db');
      var txn1Started = Completer<void>();
      var txn2Started = Completer<void>();
      var db = await factory.openDatabase(path);
      try {
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
        );

        unawaited(
          db.readTransaction((txn) async {
            txn1Started.complete();
            await txn2Started.future;
          }),
        );
        await txn1Started.future;
        await db.readTransaction((txn) async {
          txn2Started.complete();
        });
      } finally {
        await db.close();
      }
    }, skip: !context.supportsConcurrentRead);

    test('rolled back transactions', () async {
      var path = await context.initDeleteDb('rolled_back_transaction.db');

      var db = await factory.openDatabase(path);
      try {
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
        );
        try {
          await db.transaction((txn) async {
            await txn.insert('Test', {
              'id': 1,
            }, conflictAlgorithm: ConflictAlgorithm.rollback);
            try {
              await txn.insert('Test', {
                'id': 1,
              }, conflictAlgorithm: ConflictAlgorithm.rollback);
              fail('should fail 1');
            } on DatabaseException catch (e) {
              expect(e.isUniqueConstraintError(), true);
            }
            try {
              await txn.insert('Test', {
                'id': 2,
              }, conflictAlgorithm: ConflictAlgorithm.rollback);
              fail('should fail 2');
            } on DatabaseException catch (e) {
              /// Transaction already closed
              expect(e.isUniqueConstraintError(), isFalse);
            }
          });
        } on DatabaseException catch (e) {
          /// Transaction already closed !
          expect(e.isUniqueConstraintError(), isFalse);
        }
        expect(await db.query('Test'), isEmpty);
      } finally {
        await db.close();
      }
    });

    test('failed commit (deferred foreign key)', () async {
      var path = await context.initDeleteDb('failed_commit_deferred_fk.db');
      var db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE Parent (id INTEGER PRIMARY KEY)');
            await db.execute(
              'CREATE TABLE Child (id INTEGER PRIMARY KEY, parent_id INTEGER'
              ' REFERENCES Parent(id) DEFERRABLE INITIALLY DEFERRED)',
            );
          },
        ),
      );
      try {
        try {
          await db.transaction((txn) async {
            // Missing parent, only checked on COMMIT.
            await txn.insert('Child', {'id': 1, 'parent_id': 1});
          });
          fail('COMMIT should fail');
        } on DatabaseException catch (_) {
          // FOREIGN KEY constraint failed
        }
        // The failed transaction must not block the next calls...
        expect(
          await db.query('Child').timeout(const Duration(seconds: 10)),
          isEmpty,
        );
        // ...nor the next transaction.
        await db
            .transaction((txn) async {
              await txn.insert('Parent', {'id': 1});
              await txn.insert('Child', {'id': 1, 'parent_id': 1});
            })
            .timeout(const Duration(seconds: 10));
        expect(await db.query('Child'), [
          {'id': 1, 'parent_id': 1},
        ]);
      } finally {
        await db.close();
      }
    });

    group('failed rollback', () {
      // The action ends the transaction itself, so the ROLLBACK ending the
      // transaction fails ('no transaction is active'): the action's own
      // error or result must reach the caller, not this ROLLBACK error.
      Future<Database> openTestDb(String name) async {
        var path = await context.initDeleteDb(name);
        return factory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
            },
          ),
        );
      }

      test('action error kept', () async {
        var db = await openTestDb('failed_rollback_action_error.db');
        try {
          try {
            await db.transaction<void>((txn) async {
              await txn.insert('Test', {'id': 1});
              await txn.execute('ROLLBACK');
              throw StateError('action');
            });
            fail('should fail');
          } on StateError catch (e) {
            expect(e.message, 'action');
          }
          expect(await db.query('Test'), isEmpty);
          // The database is still usable.
          await db
              .transaction((txn) async {
                await txn.insert('Test', {'id': 2});
              })
              .timeout(const Duration(seconds: 10));
          expect(await db.query('Test'), [
            {'id': 2},
          ]);
        } finally {
          await db.close();
        }
      });

      test('readTransaction result kept', () async {
        var db = await openTestDb('failed_rollback_read_result.db');
        try {
          var result = await db.readTransaction((txn) async {
            await txn.execute('ROLLBACK');
            return 42;
          });
          expect(result, 42);
          expect(await db.query('Test'), isEmpty);
        } finally {
          await db.close();
        }
      });
    });

    group('failed commit (busy)', () {
      /// Long enough to detect a hang.
      const timeout = Duration(seconds: 10);

      /// SQLITE_BUSY primary result code.
      const sqliteBusy = 5;

      /// Runs [failingWrite] (a transaction or a batch on the database) while
      /// a second connection on the same file holds a SHARED lock (open read
      /// transaction): its COMMIT fails with SQLITE_BUSY and SQLite keeps the
      /// transaction open.
      ///
      /// The database must then be usable again.
      Future<void> testFailedBusyCommit(
        String dbName,
        Future<void> Function(Database db) failingWrite, {
        int? busyTimeout,
      }) async {
        var path = await context.initDeleteDb(dbName);
        var db = await factory.openDatabase(path);
        Database? reader;
        try {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
          );
          if (busyTimeout != null) {
            await db.rawQuery('PRAGMA busy_timeout = $busyTimeout');
          }
          reader = await factory.openDatabase(
            path,
            options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
          );
          // Hold a SHARED lock until the end of the read transaction.
          await reader.execute('BEGIN');
          expect(
            utils.firstIntValue(
              await reader.rawQuery('SELECT COUNT(*) FROM Test'),
            ),
            0,
          );

          try {
            await failingWrite(db).timeout(timeout);
            fail('COMMIT should fail');
          } on DatabaseException catch (e) {
            expect(e.getResultCode()! & 0xff, sqliteBusy, reason: '$e');
          }

          // The connection is not blocked while the reader still holds its
          // lock and the failed transaction has been rolled back.
          expect(await db.rawQuery('SELECT 1 AS one').timeout(timeout), [
            {'one': 1},
          ]);
          expect(await db.query('Test').timeout(timeout), isEmpty);

          await reader.execute('COMMIT');
          await reader.close();
          reader = null;

          // Writes, transactions and batches work again.
          await db.insert('Test', {'id': 1, 'name': 'insert'}).timeout(timeout);
          await db
              .transaction((txn) async {
                await txn.insert('Test', {'id': 2, 'name': 'transaction'});
              })
              .timeout(timeout);
          var batch = db.batch()..insert('Test', {'id': 3, 'name': 'batch'});
          await batch.commit(noResult: true).timeout(timeout);
        } finally {
          await reader?.close();
          await db.close();
        }

        // Only the writes done after the failed commit are persisted.
        db = await factory.openDatabase(path);
        try {
          expect(await db.query('Test', orderBy: 'id'), [
            {'id': 1, 'name': 'insert'},
            {'id': 2, 'name': 'transaction'},
            {'id': 3, 'name': 'batch'},
          ]);
        } finally {
          await db.close();
        }
      }

      Future<void> failingTransaction(Database db) async {
        await db.transaction((txn) async {
          await txn.insert('Test', {'id': 100, 'name': 'failed'});
        });
      }

      Future<void> failingBatch(Database db) async {
        var batch = db.batch()..insert('Test', {'id': 100, 'name': 'failed'});
        await batch.commit(noResult: true);
      }

      test('transaction', () async {
        await testFailedBusyCommit(
          'failed_commit_busy_transaction.db',
          failingTransaction,
        );
      });

      test('batch', () async {
        await testFailedBusyCommit('failed_commit_busy_batch.db', failingBatch);
      });

      test('transaction with busy timeout', () async {
        await testFailedBusyCommit(
          'failed_commit_busy_timeout_transaction.db',
          failingTransaction,
          busyTimeout: 200,
        );
      });

      test('batch with busy timeout', () async {
        await testFailedBusyCommit(
          'failed_commit_busy_timeout_batch.db',
          failingBatch,
          busyTimeout: 200,
        );
      });

      test('failed begin', () async {
        var path = await context.initDeleteDb('failed_begin_busy.db');
        var db = await factory.openDatabase(path);
        Database? writer;
        try {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
          );
          writer = await factory.openDatabase(
            path,
            options: OpenDatabaseOptions(singleInstance: false),
          );
          // Hold a RESERVED lock, BEGIN IMMEDIATE fails with SQLITE_BUSY.
          await writer.execute('BEGIN IMMEDIATE');
          try {
            await failingTransaction(db).timeout(timeout);
            fail('BEGIN should fail');
          } on DatabaseException catch (e) {
            expect(e.getResultCode()! & 0xff, sqliteBusy, reason: '$e');
          }
          expect(await db.query('Test').timeout(timeout), isEmpty);
          await writer.execute('ROLLBACK');
          await writer.close();
          writer = null;

          await db
              .transaction((txn) async {
                await txn.insert('Test', {'id': 1, 'name': 'transaction'});
              })
              .timeout(timeout);
          expect(await db.query('Test').timeout(timeout), [
            {'id': 1, 'name': 'transaction'},
          ]);
        } finally {
          await writer?.close();
          await db.close();
        }
      });
      // Multiple connections on the same file, native plugins (default busy
      // timeouts, BEGIN on a read-only connection) not verified.
    }, skip: context.isPlugin || !context.supportsMultipleInstances);

    test('throw in transaction', () async {
      var path = await context.initDeleteDb('throw_in_transaction.db');

      Object? exception;
      var db = await factory.openDatabase(path);
      try {
        await db.transaction((txn) async {
          throw _MyException();
        });
      } on _MyException catch (e) {
        exception = e;
      }
      // Check that the exception has been thrown
      expect(exception, isA<_MyException>());
    });
  });
}

class _MyException {}
