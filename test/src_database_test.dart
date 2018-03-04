import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/utils.dart';

class MockDatabase extends SqfliteDatabase {
  MockDatabase() : super(null, null);

  @override
  Future<T> invokeMethod<T>(String method, [arguments]) {
    // return super.invokeMethod(method, arguments);
    print('$method: $arguments');
    return null;
  }
}

main() {
  group("database", () {
    test("synchronized", () async {
      var db = new MockDatabase();
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

    group('concurrency', () {
      test('concurrent 1', () async {
        var db = new MockDatabase();
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
        var db = new MockDatabase();
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
        var db = new MockDatabase();
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
        var db = new MockDatabase();
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
  });
}
