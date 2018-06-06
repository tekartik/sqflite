import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/database_factory.dart';
import 'package:sqflite/src/utils.dart';

class MockDatabase extends SqfliteDatabase {
  MockDatabase(SqfliteDatabaseOpenHelper openHelper, [String name])
      : super(openHelper, name);

  List<String> methods = [];
  List<String> sqls = [];
  List<Map<String, dynamic>> argumentsLists = [];

  @override
  Future<T> invokeMethod<T>(String method, [arguments]) {
    // return super.invokeMethod(method, arguments);

    methods.add(method);
    if (arguments is Map) {
      argumentsLists.add(arguments.cast<String, dynamic>());
      if (arguments[paramOperations] != null) {
        var operations =
            arguments[paramOperations] as List<Map<String, dynamic>>;
        for (var operation in operations) {
          sqls.add(operation[paramSql] as String);
        }
      } else {
        sqls.add(arguments[paramSql] as String);
      }
    } else {
      argumentsLists.add(null);
      sqls.add(null);
    }
    //devPrint("$method $arguments");
    return null;
  }
}

class MockDatabaseFactory extends SqfliteDatabaseFactory {
  MockDatabase newEmptyDatabase() {
    SqfliteDatabaseOpenHelper helper =
        new SqfliteDatabaseOpenHelper(this, null, new OpenDatabaseOptions());
    return helper.newDatabase(null) as MockDatabase;
  }

  MockDatabase newDatabase(SqfliteDatabaseOpenHelper openHelper, String path) {
    return new MockDatabase(openHelper, path);
  }
}

final MockDatabaseFactory mockDatabaseFactory = new MockDatabaseFactory();

main() {
  group("database", () {
    test("synchronized", () async {
      var db = mockDatabaseFactory.newEmptyDatabase();
      expect(db.rawSynchronizedlock, isNull);
      expect(db.rawWriteSynchronizedLock, isNull);
      await db.synchronized(() {});
      expect(db.rawSynchronizedlock, isNotNull);
      expect(db.rawWriteSynchronizedLock, isNull);

      db.rawSynchronizedlock = null;
      db.rawWriteSynchronizedLock = null;

      await db.inTransaction(() {
        expect(db.rawLock.locked, isFalse);
      });
      expect(db.rawSynchronizedlock, isNotNull);
      expect(db.rawWriteSynchronizedLock, db.rawSynchronizedlock);

      db.rawSynchronizedlock = null;
      db.rawWriteSynchronizedLock = null;

      await db.execute("test");
      await db.insert("test", {'test': 1});
      await db.update("test", {'test': 1});
      await db.delete("test");
      await db.query("test");

      await db.transaction((txn) async {
        await txn.execute("test");
        await txn.insert("test", {'test': 1});
        await txn.update("test", {'test': 1});
        await txn.delete("test");
        await txn.query("test");
      });

      Batch batch = db.batch();
      batch.execute("test");
      batch.insert("test", {'test': 1});
      batch.update("test", {'test': 1});
      batch.delete("test");
      batch.query("test");
      await batch.apply();

      expect(db.rawSynchronizedlock, isNull);
    });

    group('open', () {
      test('read-only', () async {
        // var db = mockDatabaseFactory.newEmptyDatabase();
        var db = await mockDatabaseFactory.openDatabase(null,
                options: new SqfliteOpenDatabaseOptions(readOnly: true))
            as MockDatabase;
        await db.close();
        expect(db.methods, ['openDatabase', 'closeDatabase']);
        expect(db.argumentsLists.first, {'path': null, 'readOnly': true});
      });
    });
    group('openTransaction', () {
      test('onCreate', () async {
        var db = await mockDatabaseFactory.openDatabase(null,
            options: new SqfliteOpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  await db.execute("test1");
                  await db.transaction((txn) async {
                    await txn.execute("test2");
                  });
                })) as MockDatabase;

        expect(db.rawSynchronizedlock, isNull);
        await db.close();
        expect(db.methods, [
          'openDatabase',
          'execute',
          'query',
          'execute',
          'execute',
          'execute',
          'execute',
          'closeDatabase'
        ]);
        expect(db.sqls, [
          null,
          'BEGIN EXCLUSIVE',
          'PRAGMA user_version;',
          'test1',
          'test2',
          'PRAGMA user_version = 1;',
          'COMMIT',
          null
        ]);
      });

      test('onConfigure', () async {
        var db = await mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(
                version: 1,
                onConfigure: (db) async {
                  await db.execute("test1");
                  await db.transaction((txn) async {
                    await txn.execute("test2");
                  });
                })) as MockDatabase;

        expect(db.rawSynchronizedlock, isNull);
        await db.close();
        expect(db.sqls, [
          null,
          'test1',
          'BEGIN IMMEDIATE',
          'test2',
          'COMMIT',
          'BEGIN EXCLUSIVE',
          'PRAGMA user_version;',
          'PRAGMA user_version = 1;',
          'COMMIT',
          null
        ]);
      });

      test('onOpen', () async {
        var db = await mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(
                version: 1,
                onOpen: (db) async {
                  await db.execute("test1");
                  await db.transaction((txn) async {
                    await txn.execute("test2");
                  });
                })) as MockDatabase;

        expect(db.rawSynchronizedlock, isNull);
        await db.close();
        expect(db.sqls, [
          null,
          'BEGIN EXCLUSIVE',
          'PRAGMA user_version;',
          'PRAGMA user_version = 1;',
          'COMMIT',
          'test1',
          'BEGIN IMMEDIATE',
          'test2',
          'COMMIT',
          null
        ]);
      });

      test('batch', () async {
        var db = await mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(
                version: 1,
                onConfigure: (db) async {
                  var batch = db.batch();
                  batch.execute("test1");
                  await batch.commit();
                },
                onCreate: (db, _) async {
                  var batch = db.batch();
                  batch.execute("test2");
                  await batch.commit();
                },
                onOpen: (db) async {
                  var batch = db.batch();
                  batch.execute("test3");
                  await batch.commit();
                })) as MockDatabase;

        expect(db.rawSynchronizedlock, isNull);
        await db.close();
        expect(db.sqls, [
          null,
          'BEGIN IMMEDIATE',
          'test1',
          'COMMIT',
          'BEGIN EXCLUSIVE',
          'PRAGMA user_version;',
          'test2',
          'PRAGMA user_version = 1;',
          'COMMIT',
          'BEGIN IMMEDIATE',
          'test3',
          'COMMIT',
          null
        ]);
      });
    });

    group('concurrency', () {
      test('concurrent 1', () async {
        var db = mockDatabaseFactory.newEmptyDatabase();
        var step1 = new Completer();
        var step2 = new Completer();
        var step3 = new Completer();

        Future action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            var map = await db
                .execute("test")
                .timeout(new Duration(milliseconds: 100));
            throw "should fail ($map)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future action2() async {
          // This is the change with concurrency 2
          await step1.future;
          await db.transaction((txn) async {
            // Wait for table being created;
            await txn.execute("test");
            step2.complete();

            await step3.future;

            await txn.execute("test");
          });
        }

        var future1 = action1();
        var future2 = action2();

        await Future.wait([future1, future2]);
        // check ready
        await db.synchronized(() => null);
      });

      test('concurrent 2', () async {
        var db = mockDatabaseFactory.newEmptyDatabase();
        var step1 = new Completer();
        var step2 = new Completer();
        var step3 = new Completer();

        Future action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            var map = await db
                .execute("test")
                .timeout(new Duration(milliseconds: 100));
            throw "should fail ($map)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future action2() async {
          await db.transaction((txn) async {
            await step1.future;
            // Wait for table being created;
            await txn.execute("test");
            step2.complete();

            await step3.future;

            await txn.execute("test");
          });
        }

        var future1 = action1();
        var future2 = action2();

        await Future.wait([future1, future2]);
        // check ready
        await db.synchronized(() => null);
      });
    });

    group('compatibility 1', () {
      test('concurrent 1', () async {
        var db = mockDatabaseFactory.newEmptyDatabase();
        var step1 = new Completer();
        var step2 = new Completer();
        var step3 = new Completer();

        Future action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            var map = await db
                .execute("test")
                .timeout(new Duration(milliseconds: 100));
            throw "should fail ($map)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future action2() async {
          // This is the change with concurrency 2
          await step1.future;
          await db.inTransaction(() async {
            // Wait for table being created;
            await db.execute("test");
            step2.complete();

            await step3.future;

            await db.execute("test");
          });
        }

        var future1 = action1();
        var future2 = action2();

        await Future.wait([future1, future2]);
        // check ready
        await db.synchronized(() => null);
      });

      test('concurrent 2', () async {
        var db = mockDatabaseFactory.newEmptyDatabase();
        var step1 = new Completer();
        var step2 = new Completer();
        var step3 = new Completer();

        Future action1() async {
          await step1.future;
          try {
            var map = await db
                .execute("test")
                .timeout(new Duration(milliseconds: 100));
            throw "should fail ($map)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          await step2.future;
          try {
            var map = await db
                .execute("test")
                .timeout(new Duration(milliseconds: 100));
            throw "should fail ($map)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future action2() async {
          await db.inTransaction(() async {
            step1.complete();

            // Wait for table being created;
            await db.execute("test");
            step2.complete();

            await step3.future;

            await db.execute("test");
          });
        }

        var future2 = action2();
        var future1 = action1();

        await Future.wait([future1, future2]);
        // check ready
        await db.synchronized(() => null);
      });
    });

    group('batch', () {
      test('simple', () async {
        var db = await mockDatabaseFactory.openDatabase(null) as MockDatabase;

        var batch = db.batch();
        batch.execute("test");
        await batch.apply();
        await batch.apply();
        await db.close();
        expect(db.methods, [
          'openDatabase',
          'execute',
          'batch',
          'execute',
          'execute',
          'batch',
          'execute',
          'closeDatabase'
        ]);
        expect(db.sqls, [
          null,
          'BEGIN IMMEDIATE',
          'test',
          'COMMIT',
          'BEGIN IMMEDIATE',
          'test',
          'COMMIT',
          null
        ]);
      });

      test('in_transaction', () async {
        var db = await mockDatabaseFactory.openDatabase(null) as MockDatabase;

        var batch = db.batch();

        await db.transaction((txn) async {
          batch.execute("test");

          await txn.applyBatch(batch);
          await txn.applyBatch(batch);
        });
        await db.close();
        expect(db.methods, [
          'openDatabase',
          'execute',
          'batch',
          'batch',
          'execute',
          'closeDatabase'
        ]);
        expect(
            db.sqls, [null, 'BEGIN IMMEDIATE', 'test', 'test', 'COMMIT', null]);
      });

      test('wrong database', () async {
        var db2 = mockDatabaseFactory.newEmptyDatabase();
        var db = await mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions()) as MockDatabase;

        var batch = db2.batch();

        await db.transaction((txn) async {
          try {
            await txn.applyBatch(batch);
            fail("should fail");
          } on ArgumentError catch (_) {}
        });
        await db.close();
        expect(db.methods,
            ['openDatabase', 'execute', 'execute', 'closeDatabase']);
        expect(db.sqls, [null, 'BEGIN IMMEDIATE', 'COMMIT', null]);
      });
    });

    group('instances', () {
      test('singleInstance same', () async {
        var futureDb1 = mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(singleInstance: true));
        var db2 = await mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(singleInstance: true));
        var db1 = await futureDb1;
        expect(db1, db2);
      });
      test('singleInstance', () async {
        var futureDb1 = mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(singleInstance: true));
        var db2 = await mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(singleInstance: true));
        var db1 = await futureDb1;
        var db3 = await mockDatabaseFactory.openDatabase("other",
            options: new OpenDatabaseOptions(singleInstance: true));
        var db4 = await mockDatabaseFactory.openDatabase(join(".", "other"),
            options: new OpenDatabaseOptions(singleInstance: true));
        //expect(db1, db2);
        expect(db1, isNot(db3));
        expect(db3, db4);
        await db1.close();
        await db2.close();
        await db3.close();
      });

      test('default', () async {
        var futureDb1 = mockDatabaseFactory.openDatabase(null);
        var db2 = await mockDatabaseFactory.openDatabase(null);
        var db1 = await futureDb1;
        expect(db1, isNot(db2));
        await db1.close();
        await db2.close();
      });
    });
  });
}
