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

  List<String> methods = <String>[];
  List<String> sqls = <String>[];
  List<Map<String, dynamic>> argumentsLists = <Map<String, dynamic>>[];

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) {
    // return super.invokeMethod(method, arguments);

    methods.add(method);
    if (arguments is Map) {
      argumentsLists.add(arguments.cast<String, dynamic>());
      if (arguments[paramOperations] != null) {
        final List<Map<String, dynamic>> operations =
            arguments[paramOperations];
        for (Map<String, dynamic> operation in operations) {
          final String sql = operation[paramSql];
          sqls.add(sql);
        }
      } else {
        final String sql = arguments[paramSql];
        sqls.add(sql);
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
  final List<String> methods = <String>[];

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) {
    methods.add(method);
    return null;
  }

  MockDatabase newEmptyDatabase() {
    final SqfliteDatabaseOpenHelper helper =
        SqfliteDatabaseOpenHelper(this, null, OpenDatabaseOptions());
    final MockDatabase db = helper.newDatabase(null);
    return db;
  }

  @override
  MockDatabase newDatabase(SqfliteDatabaseOpenHelper openHelper, String path) {
    return MockDatabase(openHelper, path);
  }

  @override
  Future<String> getDatabasesPath() async {
    return join('.dart_tool', 'sqlite', 'test', 'mock');
  }
}

class MockDatabaseFactoryBase extends SqfliteDatabaseFactory {
  final List<String> methods = <String>[];

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) {
    methods.add(method);
    return null;
  }

  MockDatabase newEmptyDatabase() {
    final SqfliteDatabaseOpenHelper helper =
        SqfliteDatabaseOpenHelper(this, null, OpenDatabaseOptions());
    final MockDatabase db = helper.newDatabase(null);
    return db;
  }

  @override
  MockDatabase newDatabase(SqfliteDatabaseOpenHelper openHelper, String path) {
    return MockDatabase(openHelper, path);
  }
}

final MockDatabaseFactory mockDatabaseFactory = MockDatabaseFactory();

void main() {
  group('database_factory', () {
    test('getDatabasesPath', () async {
      final MockDatabaseFactoryBase factory = MockDatabaseFactoryBase();
      try {
        await factory.getDatabasesPath();
        fail("should fail");
      } on DatabaseException catch (_) {}
      expect(factory.methods, <String>['getDatabasesPath']);
      //expect(directory, )
    });
  });
  group("database", () {
    test("transaction", () async {
      final MockDatabase db = mockDatabaseFactory.newEmptyDatabase();
      await db.execute("test");
      await db.insert("test", <String, dynamic>{'test': 1});
      await db.update("test", <String, dynamic>{'test': 1});
      await db.delete("test");
      await db.query("test");

      await db.transaction((Transaction txn) async {
        await txn.execute("test");
        await txn.insert("test", <String, dynamic>{'test': 1});
        await txn.update("test", <String, dynamic>{'test': 1});
        await txn.delete("test");
        await txn.query("test");
      });

      final Batch batch = db.batch();
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
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
            options: SqfliteOpenDatabaseOptions(readOnly: true));
        await db.close();
        expect(db.methods, <String>['openDatabase', 'closeDatabase']);
        expect(db.argumentsLists.first,
            <String, dynamic>{'path': null, 'readOnly': true});
      });
      test('isOpen', () async {
        // var db = mockDatabaseFactory.newEmptyDatabase();
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
            options: SqfliteOpenDatabaseOptions(readOnly: true));
        expect(db.isOpen, true);
        final Future<void> closeFuture = db.close();
        // it is not closed right away
        expect(db.isOpen, true);
        await closeFuture;
        expect(db.isOpen, false);
      });
    });
    group('openTransaction', () {
      test('onCreate', () async {
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
            options: SqfliteOpenDatabaseOptions(
                version: 1,
                onCreate: (Database db, int version) async {
                  await db.execute("test1");
                  await db.transaction((Transaction txn) async {
                    await txn.execute("test2");
                  });
                }));

        await db.close();
        expect(db.methods, <String>[
          'openDatabase',
          'execute',
          'query',
          'execute',
          'execute',
          'execute',
          'execute',
          'closeDatabase'
        ]);
        expect(db.sqls, <String>[
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
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
            options: OpenDatabaseOptions(
                version: 1,
                onConfigure: (Database db) async {
                  await db.execute("test1");
                  await db.transaction((Transaction txn) async {
                    await txn.execute("test2");
                  });
                }));

        await db.close();
        expect(db.sqls, <String>[
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
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
            options: OpenDatabaseOptions(
                version: 1,
                onOpen: (Database db) async {
                  await db.execute("test1");
                  await db.transaction((Transaction txn) async {
                    await txn.execute("test2");
                  });
                }));

        await db.close();
        expect(db.sqls, <String>[
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
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
            options: OpenDatabaseOptions(
                version: 1,
                onConfigure: (Database db) async {
                  final Batch batch = db.batch();
                  batch.execute("test1");
                  await batch.commit();
                },
                onCreate: (Database db, _) async {
                  final Batch batch = db.batch();
                  batch.execute("test2");
                  await batch.commit();
                },
                onOpen: (Database db) async {
                  final Batch batch = db.batch();
                  batch.execute("test3");
                  await batch.commit();
                }));

        await db.close();
        expect(db.sqls, <String>[
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
        final MockDatabase db = mockDatabaseFactory.newEmptyDatabase();
        final Completer<dynamic> step1 = Completer<dynamic>();
        final Completer<dynamic> step2 = Completer<dynamic>();
        final Completer<dynamic> step3 = Completer<dynamic>();

        Future<void> action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            await db.execute("test").timeout(Duration(milliseconds: 100));
            throw "should fail";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future<void> action2() async {
          // This is the change with concurrency 2
          await step1.future;
          await db.transaction((Transaction txn) async {
            // Wait for table being created;
            await txn.execute("test");
            step2.complete();

            await step3.future;

            await txn.execute("test");
          });
        }

        final Future<dynamic> future1 = action1();
        final Future<dynamic> future2 = action2();

        await Future.wait<dynamic>(<Future<dynamic>>[future1, future2]);
        // check ready
        await db.transaction<dynamic>((_) => null);
      });

      test('concurrent 2', () async {
        final MockDatabase db = mockDatabaseFactory.newEmptyDatabase();
        final Completer<dynamic> step1 = Completer<dynamic>();
        final Completer<dynamic> step2 = Completer<dynamic>();
        final Completer<dynamic> step3 = Completer<dynamic>();

        Future<void> action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            final dynamic map =
                await db.execute("test").timeout(Duration(milliseconds: 100));
            throw "should fail ($map)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future<void> action2() async {
          await db.transaction((Transaction txn) async {
            await step1.future;
            // Wait for table being created;
            await txn.execute("test");
            step2.complete();

            await step3.future;

            await txn.execute("test");
          });
        }

        final Future<dynamic> future1 = action1();
        final Future<dynamic> future2 = action2();

        await Future.wait<dynamic>(<Future<dynamic>>[future1, future2]);
      });
    });

    group('compatibility 1', () {
      test('concurrent 1', () async {
        final MockDatabase db = mockDatabaseFactory.newEmptyDatabase();
        final Completer<dynamic> step1 = Completer<dynamic>();
        final Completer<dynamic> step2 = Completer<dynamic>();
        final Completer<dynamic> step3 = Completer<dynamic>();

        Future<void> action1() async {
          await db.execute("test");
          step1.complete();

          await step2.future;
          try {
            final dynamic result =
                await db.execute("test").timeout(Duration(milliseconds: 100));
            throw "should fail ($result)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future<void> action2() async {
          // This is the change with concurrency 2
          await step1.future;
          await db.transaction((Transaction txn) async {
            // Wait for table being created;
            await txn.execute("test");
            step2.complete();

            await step3.future;

            await txn.execute("test");
          });
        }

        final Future<dynamic> future1 = action1();
        final Future<dynamic> future2 = action2();

        await Future.wait<dynamic>(<Future<dynamic>>[future1, future2]);
        // check ready
        await db.transaction<dynamic>((_) => null);
      });

      test('concurrent 2', () async {
        final MockDatabase db = mockDatabaseFactory.newEmptyDatabase();
        final Completer<dynamic> step1 = Completer<dynamic>();
        final Completer<dynamic> step2 = Completer<dynamic>();
        final Completer<dynamic> step3 = Completer<dynamic>();

        Future<void> action1() async {
          await step1.future;
          try {
            final dynamic result =
                await db.execute("test").timeout(Duration(milliseconds: 100));
            throw "should fail ($result)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          await step2.future;
          try {
            final dynamic result =
                await db.execute("test").timeout(Duration(milliseconds: 100));
            throw "should fail ($result)";
          } catch (e) {
            expect(e is TimeoutException, true);
          }

          step3.complete();
        }

        Future<void> action2() async {
          await db.transaction((Transaction txn) async {
            step1.complete();

            // Wait for table being created;
            await txn.execute("test");
            step2.complete();

            await step3.future;

            await txn.execute("test");
          });
        }

        final Future<dynamic> future2 = action2();
        final Future<dynamic> future1 = action1();

        await Future.wait<dynamic>(<Future<dynamic>>[future1, future2]);
        // check ready
        await db.transaction<dynamic>((_) => null);
      });
    });

    group('batch', () {
      test('simple', () async {
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null);

        final Batch batch = db.batch();
        batch.execute("test");
        await batch.commit();
        await batch.commit();
        await db.close();
        expect(db.methods, <String>[
          'openDatabase',
          'execute',
          'batch',
          'execute',
          'execute',
          'batch',
          'execute',
          'closeDatabase'
        ]);
        expect(db.sqls, <String>[
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
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null);

        await db.transaction((Transaction txn) async {
          final Batch batch = txn.batch();
          batch.execute("test");

          await batch.commit();
          await batch.commit();
        });
        await db.close();
        expect(db.methods, <String>[
          'openDatabase',
          'execute',
          'batch',
          'batch',
          'execute',
          'closeDatabase'
        ]);
        expect(db.sqls,
            <String>[null, 'BEGIN IMMEDIATE', 'test', 'test', 'COMMIT', null]);
      });

      test('wrong database', () async {
        final MockDatabase db2 = mockDatabaseFactory.newEmptyDatabase();
        final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
            options: OpenDatabaseOptions());

        final Batch batch = db2.batch();

        await db.transaction((Transaction txn) async {
          try {
            // ignore: deprecated_member_use
            await txn.applyBatch(batch);
            fail("should fail");
          } on ArgumentError catch (_) {}
        });
        await db.close();
        expect(db.methods,
            <String>['openDatabase', 'execute', 'execute', 'closeDatabase']);
        expect(db.sqls, <String>[null, 'BEGIN IMMEDIATE', 'COMMIT', null]);
      });
    });

    group('instances', () {
      test('singleInstance same', () async {
        final Future<Database> futureDb1 = mockDatabaseFactory.openDatabase(
            null,
            options: OpenDatabaseOptions(singleInstance: true));
        final MockDatabase db2 = await mockDatabaseFactory.openDatabase(null,
            options: OpenDatabaseOptions(singleInstance: true));
        final MockDatabase db1 = await futureDb1;
        expect(db1, db2);
      });
      test('singleInstance', () async {
        final Future<Database> futureDb1 = mockDatabaseFactory.openDatabase(
            null,
            options: OpenDatabaseOptions(singleInstance: true));
        final MockDatabase db2 = await mockDatabaseFactory.openDatabase(null,
            options: OpenDatabaseOptions(singleInstance: true));
        final MockDatabase db1 = await futureDb1;
        final MockDatabase db3 = await mockDatabaseFactory.openDatabase("other",
            options: OpenDatabaseOptions(singleInstance: true));
        final MockDatabase db4 = await mockDatabaseFactory.openDatabase(
            join(".", "other"),
            options: OpenDatabaseOptions(singleInstance: true));
        //expect(db1, db2);
        expect(db1, isNot(db3));
        expect(db3, db4);
        await db1.close();
        await db2.close();
        await db3.close();
      });

      test('multiInstances', () async {
        final Future<Database> futureDb1 = mockDatabaseFactory.openDatabase(
            null,
            options: OpenDatabaseOptions(singleInstance: false));
        final MockDatabase db2 = await mockDatabaseFactory.openDatabase(null,
            options: OpenDatabaseOptions(singleInstance: false));
        final MockDatabase db1 = await futureDb1;
        expect(db1, isNot(db2));
        await db1.close();
        await db2.close();
      });
    });

    test('dead lock', () async {
      final MockDatabase db = mockDatabaseFactory.newEmptyDatabase();
      bool hasTimedOut = false;
      int callbackCount = 0;
      setLockWarningInfo(
          duration: Duration(milliseconds: 200),
          callback: () {
            callbackCount++;
          });
      try {
        await db.transaction((Transaction txn) async {
          await db.execute('test');
          fail("should fail");
        }).timeout(Duration(milliseconds: 500));
      } on TimeoutException catch (_) {
        hasTimedOut = true;
      }
      expect(hasTimedOut, isTrue);
      expect(callbackCount, 1);
      await db.close();
    });
  });
}
