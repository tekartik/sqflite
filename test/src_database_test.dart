import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/constant.dart' hide lockWarningDuration;
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/database_factory.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/utils.dart';

class MockDatabase extends SqfliteDatabase {
  MockDatabase(SqfliteDatabaseOpenHelper openHelper, [String name])
      : super(openHelper, name);

  List<String> methods = [];
  List<String> sqls = [];
  List<Map<String, dynamic>> argumentsLists = [];

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) {
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
  List<String> methods = [];

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) {
    methods.add(method);
    return null;
  }

  MockDatabase newEmptyDatabase() {
    SqfliteDatabaseOpenHelper helper =
        new SqfliteDatabaseOpenHelper(this, null, new OpenDatabaseOptions());
    return helper.newDatabase(null) as MockDatabase;
  }

  @override
  MockDatabase newDatabase(SqfliteDatabaseOpenHelper openHelper, String path) {
    return new MockDatabase(openHelper, path);
  }
}

final MockDatabaseFactory mockDatabaseFactory = new MockDatabaseFactory();

void main() {
  group('database_factory', () {
    test('getDatabasesPath', () async {
      var factory = new MockDatabaseFactory();
      try {
        await factory.getDatabasesPath();
        fail("should fail");
      } on DatabaseException catch (_) {}
      expect(factory.methods, ['getDatabasesPath']);
      //expect(directory, )
    });
  });
  group("database", () {
    test("transaction", () async {
      var db = mockDatabaseFactory.newEmptyDatabase();
      await db.execute("test");
      await db.insert("test", <String, dynamic>{'test': 1});
      await db.update("test", <String, dynamic>{'test': 1});
      await db.delete("test");
      await db.query("test");

      await db.transaction((txn) async {
        await txn.execute("test");
        await txn.insert("test", <String, dynamic>{'test': 1});
        await txn.update("test", <String, dynamic>{'test': 1});
        await txn.delete("test");
        await txn.query("test");
      });

      Batch batch = db.batch();
      batch.execute("test");
      batch.insert("test", <String, dynamic>{'test': 1});
      batch.update("test", <String, dynamic>{'test': 1});
      batch.delete("test");
      batch.query("test");
      await batch.commit();
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
        var step1 = new Completer<dynamic>();
        var step2 = new Completer<dynamic>();
        var step3 = new Completer<dynamic>();

        Future action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            dynamic map = await db
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

        await Future.wait<dynamic>([future1, future2]);
        // check ready
        await db.transaction<dynamic>((_) => null);
      });

      test('concurrent 2', () async {
        var db = mockDatabaseFactory.newEmptyDatabase();
        var step1 = new Completer<dynamic>();
        var step2 = new Completer<dynamic>();
        var step3 = new Completer<dynamic>();

        Future action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            dynamic map = await db
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

        await Future.wait<dynamic>([future1, future2]);
      });
    });

    group('compatibility 1', () {
      test('concurrent 1', () async {
        var db = mockDatabaseFactory.newEmptyDatabase();
        var step1 = new Completer<dynamic>();
        var step2 = new Completer<dynamic>();
        var step3 = new Completer<dynamic>();

        Future action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            dynamic map = await db
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

        await Future.wait<dynamic>([future1, future2]);
        // check ready
        await db.transaction<dynamic>((_) => null);
      });

      test('concurrent 2', () async {
        var db = mockDatabaseFactory.newEmptyDatabase();
        var step1 = new Completer<dynamic>();
        var step2 = new Completer<dynamic>();
        var step3 = new Completer<dynamic>();

        Future action1() async {
          await step1.future;
          try {
            dynamic map = await db
                .execute("test")
                .timeout(new Duration(milliseconds: 100));
            throw "should fail ($map)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          await step2.future;
          try {
            dynamic map = await db
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
            step1.complete();

            // Wait for table being created;
            await txn.execute("test");
            step2.complete();

            await step3.future;

            await txn.execute("test");
          });
        }

        var future2 = action2();
        var future1 = action1();

        await Future.wait<dynamic>([future1, future2]);
        // check ready
        await db.transaction<dynamic>((_) => null);
      });
    });

    group('batch', () {
      test('simple', () async {
        var db = await mockDatabaseFactory.openDatabase(null) as MockDatabase;

        var batch = db.batch();
        batch.execute("test");
        await batch.commit();
        await batch.commit();
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

        await db.transaction((txn) async {
          var batch = txn.batch();
          batch.execute("test");

          await batch.commit();
          await batch.commit();
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
            // ignore: deprecated_member_use
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

      test('multiInstances', () async {
        var futureDb1 = mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(singleInstance: false));
        var db2 = await mockDatabaseFactory.openDatabase(null,
            options: new OpenDatabaseOptions(singleInstance: false));
        var db1 = await futureDb1;
        expect(db1, isNot(db2));
        await db1.close();
        await db2.close();
      });
    });

    test('dead lock', () async {
      var db = mockDatabaseFactory.newEmptyDatabase();
      bool hasTimedOut = false;
      int callbackCount = 0;
      setLockWarningInfo(
          duration: new Duration(milliseconds: 200),
          callback: () {
            callbackCount++;
          });
      try {
        await db.transaction((txn) async {
          await db.execute('test');
          fail("should fail");
        }).timeout(new Duration(milliseconds: 500));
      } on TimeoutException catch (_) {
        hasTimedOut = true;
      }
      expect(hasTimedOut, isTrue);
      expect(callbackCount, 1);
      await db.close();
    });
  });
}
