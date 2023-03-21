import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

// ignore: unused_import
import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite_common/sql.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

import 'open_test.dart';

/// Run exception test.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('exception', () {
    test('Transaction failed', () async {
      //await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('transaction_failed.db');
      var db = await factory.openDatabase(path);

      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      // insert then fails to make sure the transaction is cancelled
      var hasFailed = false;
      try {
        await db.transaction((txn) async {
          await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item']);
          var afterCount = utils
              .firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM Test'));
          expect(afterCount, 1);

          hasFailed = true;
          // this failure should cancel the insertion before
          await txn.execute('DUMMY CALL');
          hasFailed = false;
        });
      } on DatabaseException catch (e) {
        // iOS: native_error: PlatformException(sqlite_error, Error Domain=FMDatabase Code=1 'near 'DUMMY': syntax error' UserInfo={NSLocalizedDescription=near 'DUMMY': syntax error}, null)
        print('native_error: $e');
      }
      verify(hasFailed);

      var afterCount =
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(afterCount, 0);

      await db.close();
    });

    test('Batch failed', () async {
      //await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('batch_failed.db');
      var db = await factory.openDatabase(path);

      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');

      var batch = db.batch();
      batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item']);
      batch.execute('DUMMY CALL');

      var hasFailed = true;
      try {
        await batch.commit();
        hasFailed = false;
      } on DatabaseException catch (e) {
        print('native_error: $e');
      }

      verify(hasFailed);

      var afterCount =
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(afterCount, 0);

      await db.close();
    });

    test('Sqlite Exception', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('exception.db');
      var db = await factory.openDatabase(path);

      // Query
      try {
        await db.rawQuery('SELECT COUNT(*) FROM Test');
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isNoSuchTableError('Test'));
        // Error Domain=FMDatabase Code=1 'no such table: Test' UserInfo={NSLocalizedDescription=no such table: Test})
      }

      // Catch without using on DatabaseException
      try {
        await db.rawQuery('malformed query');
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        //verify(e.toString().contains('sql 'malformed query' args'));
        // devPrint(e);
      }

      try {
        await db.rawQuery('malformed query with args ?', [1]);
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        print(e);
        verify(e.toString().contains('malformed query with args ?'));
      }

      try {
        await db.execute('DUMMY');
        fail('should fail'); // should fail before
      } on Exception catch (e) {
        //verify(e.isSyntaxError());
        print(e);
        verify(e.toString().contains('DUMMY'));
      }

      try {
        await db.rawInsert('DUMMY');
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        verify(e.toString().contains('DUMMY'));
      }

      try {
        await db.rawUpdate('DUMMY');
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        verify(e.toString().contains('DUMMY'));
      }

      await db.close();
    });

    test('Duplicate column Exception', () async {
      // await utils.devSetDebugModeOn(true);
      var path = inMemoryDatabasePath;
      var db = await factory.openDatabase(path);

      try {
        await db.execute('ALTER TABLE Test ADD COLUMN name TEXT');
      } on DatabaseException catch (e) {
        // devPrint(e);
        // Ffi: SqfliteFfiException(sqlite_error1, , SqliteException(1): no such table: Test} DatabaseException(SqliteException(1): no such table: Test) sql 'ALTER TABLE Test ADD COLUMN name TEXT' {details: {database: {path: :memory:, id: 1, readOnly: false, singleInstance: true}, sql: ALTER TABLE Test ADD COLUMN name TEXT}}
        // Android: DatabaseException(no such table: Test (code 1 SQLITE_ERROR): , while compiling: ALTER TABLE Test ADD COLUMN name TEXT) sql 'ALTER TABLE Test ADD COLUMN name TEXT' args []}
        expect(e.getResultCode(), 1, reason: 'error $e');
        expect(e.isNoSuchTableError('Test'), isTrue, reason: 'error $e');
        expect(e.isNoSuchTableError(), isTrue, reason: 'error $e');
      }

      await db.execute('CREATE Table Test (id INTEGER PRIMARY KEY)');
      await db.execute('ALTER TABLE Test ADD COLUMN name TEXT');

      try {
        await db.execute('ALTER TABLE Test ADD COLUMN name TEXT');
      } on DatabaseException catch (e) {
        // Integration test, not handled yet
        // Ffi: SqfliteFfiException(sqlite_error1, , SqliteException(1): duplicate column name: name} DatabaseException(SqliteException(1): duplicate column name: name) sql 'ALTER TABLE Test ADD COLUMN name TEXT' {details: {database: {path: :memory:, id: 1, readOnly: false, singleInstance: true}, sql: ALTER TABLE Test ADD COLUMN name TEXT}}
        // Android DatabaseException(duplicate column name: name (code 1 SQLITE_ERROR): , while compiling: ALTER TABLE Test ADD COLUMN name TEXT) sql 'ALTER TABLE Test ADD COLUMN name TEXT' args []}
        expect(e.getResultCode(), 1, reason: 'error $e');
        expect(e.isDuplicateColumnError('name'), isTrue, reason: 'error $e');
        expect(e.isDuplicateColumnError(), isTrue, reason: 'error $e');
      }
    });

    test('open read-only exception', () async {
      var path = await context.initDeleteDb('read_only_exception.db');
      // Make sure the path exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      // but not the db
      try {
        await File(path).delete();
      } catch (_) {}

      // Opening a non-existent database should fail
      try {
        await factory.openDatabase(path,
            options: OpenDatabaseOptions(readOnly: true));
        fail('should fail');
      } on DatabaseException catch (_) {
        /// Ffi: SqfliteFfiException(error, Bad state: file read_only_exception.db not found
      }

      // Open in read-write mode to create the database
      var db = await factory.openDatabase(path);
      // Change the user version to test read-write access
      await db.setVersion(1);
      await db.close();

      // Open in read-only
      db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(readOnly: true));
      // Change the user version to test read-only mode
      try {
        // await db.setVersion(2);
        await db.execute('PRAGMA user_version = 2');
        fail('should fail');
      } on DatabaseException catch (e) {
        // ffo: SqfliteFfiException(sqlite_error8, , SqliteException(8): attempt to write a readonly database} DatabaseException(SqliteException(8): attempt to write a readonly database) sql 'PRAGMA user_version = 2
        print(e);
        expect(e.isReadOnlyError(), isTrue);
        expect(e.getResultCode(), 8);
      }
      // Check that it has not changed
      expect(await db.getVersion(), 1);
    });

    test('Sqlite constraint Exception', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('constraint_exception.db');
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (db, version) {
                db.execute('CREATE TABLE Test (name TEXT UNIQUE)');
              }));
      await db.insert('Test', <String, Object?>{'name': 'test1'});

      try {
        await db.insert('Test', <String, Object?>{'name': 'test1'});
        fail('should fail');
      } on DatabaseException catch (e) {
        // iOS: Error Domain=FMDatabase Code=19 'UNIQUE constraint failed: Test.name' UserInfo={NSLocalizedDescription=UNIQUE constraint failed: Test.name}) s
        // Android: UNIQUE constraint failed: Test.name (code 2067))
        print(e);
        verify(e.isUniqueConstraintError());
        verify(e.isUniqueConstraintError('Test.name'));
        expect(e.getResultCode(), 2067);
      }
      await db.close();
    });

    test('Sqlite constraint not null', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('constraint_not_null_exception.db');
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (db, version) {
                db.execute(
                    'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL)');
              }));
      await db.insert('Test', <String, Object?>{'id': 1, 'name': 'test1'});
      try {
        await db.insert('Test', <String, Object?>{'id': 1});
        fail('should fail');
      } on DatabaseException catch (e) {
        print(e);
        // iOS DatabaseException(Error Domain=FMDatabase Code=1299 "NOT NULL constraint failed: Test.name"
        expect(e.getResultCode(), 1299);
        expect(e.isNotNullConstraintError(), isTrue);
        expect(e.isNotNullConstraintError('Test.name'), isTrue);
      }
      await db.close();
    });

    test('Sqlite constraint primary key', () async {
      // await context.devSetDebugModeOn(true);
      var path =
          await context.initDeleteDb('constraint_primary_key_exception.db');
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (db, version) {
                db.execute('CREATE TABLE Test (name TEXT PRIMARY KEY)');
              }));
      await db.insert('Test', <String, Object?>{'name': 'test1'});

      try {
        await db.insert('Test', <String, Object?>{'name': 'test1'});
        fail('should fail');
      } on DatabaseException catch (e) {
        // iOS: DatabaseException(Error Domain=FMDatabase Code=1555 "UNIQUE constraint failed: Test.name"
        // Android: UNIQUE constraint failed: Test.name (code 1555))
        print(e);
        expect(e.isUniqueConstraintError(), isTrue);
        expect(e.isUniqueConstraintError('Test.name'), isTrue);
        expect(e.getResultCode(), 1555);
      }

      // try in batch
      var batch = db.batch();
      batch.insert('Test', <String, Object?>{'name': 'test1'});
      try {
        await batch.commit();
        fail('should fail');
      } on DatabaseException catch (e) {
        // iOS: Error Domain=FMDatabase Code=19 'UNIQUE constraint failed: Test.name' UserInfo={NSLocalizedDescription=UNIQUE constraint failed: Test.name}) s
        // Android: UNIQUE constraint failed: Test.name (code 1555))
        print(e);
        expect(e.isUniqueConstraintError(), isTrue);
        expect(e.isUniqueConstraintError('Test.name'), isTrue);
        expect(e.getResultCode(), 1555);
      }

      // update
      await db.insert('Test', <String, Object?>{'name': 'test2'});
      try {
        await db.update('Test', <String, Object?>{'name': 'test1'},
            where: 'name = "test2"');
        fail('should fail');
      } on DatabaseException catch (e) {
        // iOS DatabaseException(Error Domain=FMDatabase Code=1555 "UNIQUE constraint failed: Test.name"
        expect(e.getResultCode(), 1555);
        expect(e.isUniqueConstraintError(), isTrue);
        expect(e.isUniqueConstraintError('Test.name'), isTrue);
      }
      await db.close();
    });

    test('Sqlite batch Exception', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('batch_exception.db');
      var db = await factory.openDatabase(path);

      // Query
      try {
        var batch = db.batch();
        batch.rawQuery('SELECT COUNT(*) FROM Test');
        await batch.commit();
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        print(e);
        // DatabaseException(Error Domain=FMDatabase Code=1 "no such table: Test"
        // ffi: SqfliteFfiException(sqlite_error, SqliteException(1): no such table: Test, SQL logic error (code 1)}
        verify(e.isNoSuchTableError('Test'));
        expect(e.getResultCode(), 1);
      }

      // Catch without using on DatabaseException
      try {
        var batch = db.batch();
        batch.rawQuery('malformed query');
        await batch.commit();
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        print(e);
        //verify(e.toString().contains('malformed query'));
        // malform only on FFI
        verify(e.toString().contains('malformed'));
        expect(e.getResultCode(), 1);
      }

      try {
        var batch = db.batch();
        batch.rawQuery('malformed query with args ?', [1]);
        await batch.commit();
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        print(e);
        // verify(e.toString().contains('malformed query with args ?'));
        // FFI only SqliteException: near 'malformed': syntax error, SQL logic error
        verify(e.toString().contains('malformed'));
        expect(e.getResultCode(), 1);
      }

      try {
        var batch = db.batch();
        batch.execute('DUMMY');
        await batch.commit();
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        // devPrint(e);
        // iOS Error Domain=FMDatabase Code=1 'near 'DUMMY': syntax error' UserInfo={NSLocalizedDescription=near 'DUMMY': syntax error})
        // ffi: SqfliteFfiException(sqlite_error, SqliteException(1): near "malformed": syntax error, SQL logic error (code 1
        verify(e.toString().contains('DUMMY'));
        expect(e.getResultCode(), 1);
      }

      try {
        var batch = db.batch();
        batch.rawInsert('DUMMY');
        await batch.commit();
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        verify(e.toString().contains('DUMMY'));
        expect(e.getResultCode(), 1);
      }

      try {
        var batch = db.batch();
        batch.rawUpdate('DUMMY');
        await batch.commit();
        fail('should fail'); // should fail before
      } on DatabaseException catch (e) {
        verify(e.isSyntaxError());
        verify(e.toString().contains('DUMMY'));
        expect(e.getResultCode(), 1);
      }

      await db.close();
    });

    test('Open onDowngrade fail', () async {
      var path = await context.initDeleteDb('open_on_downgrade_fail.db');
      var database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 2,
              onCreate: (Database db, int version) async {
                await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
              }));
      await database.close();

      // currently this is crashing...
      // should fail going back in versions
      try {
        database = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 1, onDowngrade: onDatabaseVersionChangeError));
        verify(false);
      } catch (e) {
        print(e);
      }

      // should work
      database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 2, onDowngrade: onDatabaseVersionChangeError));
      print(database);
      await database.close();
    });

    test('Access after close', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('access_after_close.db');
      var database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 3,
              onCreate: (Database db, int version) async {
                await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
              }));
      await database.close();
      try {
        await database.getVersion();
        verify(false);
      } on DatabaseException catch (e) {
        print(e);
        verify(e.isDatabaseClosedError());
      }

      try {
        await database.setVersion(1);
        fail('should fail');
      } on DatabaseException catch (e) {
        print(e);
        verify(e.isDatabaseClosedError());
      }
    });

    test('Non escaping fields', () async {
      //await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('non_escaping_fields.db');
      var db = await factory.openDatabase(path);

      var table = 'table';
      try {
        await db.execute('CREATE TABLE $table (group INTEGER)');
        fail('should fail');
      } on DatabaseException catch (e) {
        print(e);
        verify(e.isSyntaxError());
      }
      try {
        await db.execute('INSERT INTO $table (group) VALUES (1)');
        fail('should fail');
      } on DatabaseException catch (e) {
        print(e);
        verify(e.isSyntaxError());
      }
      try {
        await db.rawQuery('SELECT * FROM $table ORDER BY group DESC');
      } on DatabaseException catch (e) {
        print(e);
        verify(e.isSyntaxError());
      }

      try {
        await db.rawQuery('DELETE FROM $table');
      } on DatabaseException catch (e) {
        print(e);
        verify(e.isSyntaxError());
      }

      // Build our escape list from all the sqlite keywords
      var toExclude = <String>[];
      for (var name in _allEscapeNames) {
        try {
          await db.execute('CREATE TABLE $name (value INTEGER)');
        } on DatabaseException catch (e) {
          await db.execute('CREATE TABLE ${escapeName(name)} (value INTEGER)');

          verify(e.isSyntaxError());
          toExclude.add(name);
        }
      }
      print(json.encode(toExclude));

      await db.close();
    });

    /// Check that non alpha table and column name are properly escaped
    test('escape when needed', () async {
      // await factory.setLogLevel(sqfliteLogLevelVerbose);
      var db = await factory.openDatabase(inMemoryDatabasePath);

      var safeTableName = 'my_table';
      var safeColumnName = 'my_column';
      for (var name in [
        'semicolumn:',
        '1',
        'table',
        r'$',
        '[](){}:;?/\\&éçà^ù*-+,!̣'
      ]) {
        try {
          await db.execute('CREATE TABLE $name ($safeColumnName INTEGER)');
          fail('should fail');
        } on DatabaseException catch (_) {
          // unrecognized token: ":"
        }
        try {
          await db.execute('CREATE TABLE $safeTableName ($name INTEGER)');
          fail('should fail');
        } on DatabaseException catch (_) {
          // unrecognized token: ":"
        }

        await db.execute('CREATE TABLE "$name" ("$name" INTEGER)');
        await db.insert('"$name"', {'"$name"': 1});
        expect(await db.query('"$name"'), [
          {name: 1}
        ]);
        expect(await db.update('"$name"', {'"$name"': 2}), 1);
        expect(await db.query('"$name"'), [
          {name: 2}
        ]);
        expect(
            (await db.query('sqlite_master',
                    where: 'name = ?', whereArgs: [name]))
                .first['tbl_name'],
            name);
      }

      await db.close();
    });

    test('Bind no argument (no iOS/ffi)', () async {
      if (!Platform.isIOS) {
        // await utils.devSetDebugModeOn(true);
        var path = await context.initDeleteDb('bind_no_arg_failed.db');
        var db = await factory.openDatabase(path);

        await db.execute('CREATE TABLE Test (name TEXT)');

        await db.rawInsert('INSERT INTO Test (name) VALUES (\'?\')', []);

        await db.rawQuery('SELECT * FROM Test WHERE name = ?', []);

        await db.rawDelete('DELETE FROM Test WHERE name = ?', []);

        await db.close();
      }
    }, skip: true);

    test('crash ios (no iOS)', () async {
      // This crashes natively on iOS...can't catch it yet
      if (!Platform.isIOS) {
        //if (true) {
        // await utils.devSetDebugModeOn(true);
        var path = await context.initDeleteDb('bind_no_arg_failed.db');
        var db = await factory.openDatabase(path);

        await db.execute('CREATE TABLE Test (name TEXT)');

        await db.rawInsert('INSERT INTO Test (name) VALUES (\'?\')', []);

        await db.rawQuery('SELECT * FROM Test WHERE name = ?', []);

        await db.close();
      }
    }, skip: true);

    test('Bind null argument', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('bind_null_failed.db');
      var db = await factory.openDatabase(path);

      await db.execute('CREATE TABLE Test (name TEXT)');

      //await db.rawInsert('INSERT INTO Test (name) VALUES (\'?\')', [null]);
      // nnbd, this is no longer possible!
      /*
      try {
        await db
            .rawInsert('INSERT INTO Test (name) VALUES (?)', <dynamic>[null]);
      } on DatabaseException catch (e) {
        print('ERR: $e');
        expect(e.toString().contains("sql 'INSERT"), true);
      }

      try {
        await db.rawQuery('SELECT * FROM Test WHERE name = ?', <dynamic>[null]);
      } on DatabaseException catch (e) {
        print('ERR: $e');
        expect(e.toString().contains('SELECT * FROM Test'), true);
      }

      try {
        await db.rawDelete('DELETE FROM Test WHERE name = ?', <dynamic>[null]);
      } on DatabaseException catch (e) {
        print('ERR: $e');
        expect(e.toString().contains("sql 'DELETE FROM Test"), true);
      }
       */
      await db.close();
    });

    test('Bind no parameter', () async {
      // await factory.setLogLevel(sqfliteLogLevelVerbose);
      var path = await context.initDeleteDb('bind_no_parameter_failed.db');
      var db = await factory.openDatabase(path);

      await db.execute('CREATE TABLE Test (name TEXT)');

      try {
        await db.rawInsert(
            'INSERT INTO Test (name) VALUES (\'value\')', ['value2']);
      } on DatabaseException catch (e) {
        print('ERR: $e');
        expect(e.toString().contains('INSERT INTO Test'), true);
      }

      try {
        await db
            .rawQuery('SELECT * FROM Test WHERE name = \'value\'', ['value2']);
      } on DatabaseException catch (e) {
        print('ERR: $e');
        expect(e.toString().contains('SELECT * FROM Test'), true);
      }

      try {
        await db
            .rawDelete('DELETE FROM Test WHERE name = \'value\'', ['value2']);
      } on DatabaseException catch (e) {
        print('ERR: $e');
        expect(e.toString().contains('DELETE FROM Test'), true);
      }

      await db.close();
    });

    var supportsDeadLock = context.supportsDeadLock;
    // Using the db object in a transaction lead to a deadlock...
    test('Dead lock', () async {
      var path = await context.initDeleteDb('dead_lock.db');
      var db = await factory.openDatabase(path);

      var hasTimedOut = false;
      var callbackCount = 0;
      utils.setLockWarningInfo(
          duration: const Duration(milliseconds: 200),
          callback: () {
            callbackCount++;
          });
      try {
        await db.transaction((txn) async {
          await db.getVersion();
          fail('should fail');
        }).timeout(const Duration(milliseconds: 1500));
      } on TimeoutException catch (_) {
        hasTimedOut = true;
      }
      expect(hasTimedOut, true);
      expect(callbackCount, 1);
      await db.close();
    }, skip: !supportsDeadLock); // Multi instance dead lock
    // Using the db object in a transaction lead to a deadlock...
    test('Dead lock safe', () async {
      var path = await context.initDeleteDb('dead_lock_safe.db');
      var db = await factory.openDatabase(path);

      // Needed for ffi
      var useTimeout = true;
      var hasTimedOut = false;
      var callbackCount = 0;
      utils.setLockWarningInfo(
          duration: const Duration(milliseconds: 200),
          callback: () {
            callbackCount++;
          });
      try {
        await db.transaction((txn) async {
          var versionFuture = db.getVersion();
          if (useTimeout) {
            versionFuture =
                versionFuture.timeout(const Duration(milliseconds: 2000));
          }
          await versionFuture;
          fail('should fail');
        }).timeout(const Duration(milliseconds: 1500));
      } on TimeoutException catch (_) {
        hasTimedOut = true;
      }
      expect(hasTimedOut, true);
      expect(callbackCount, 1);
      // For FFI allow
      await db.close();
    });

    test('Thread dead lock', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('thread_dead_lock.db');
      var db1 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: false));
      var db2 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: false));
      expect(db1, isNot(db2));
      try {
        await db1.execute('BEGIN EXCLUSIVE TRANSACTION');

        try {
          // this should block the main thread
          await db2
              .execute('BEGIN EXCLUSIVE TRANSACTION')
              .timeout(const Duration(milliseconds: 500));
          fail('should timeout');
        } on TimeoutException catch (e) {
          print('caught $e');
        }

        // Try to open another db to check that the main thread is free
        var db = await factory.openDatabase(inMemoryDatabasePath);
        await db.close();
      } finally {
        await db1.close();
        await db2.close();
      }
    }, skip: !supportsDeadLock);

    test('Thread dead lock safe', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('thread_dead_lock_safe.db');
      var db1 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: false));
      var db2 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: false));
      expect(db1, isNot(db2));
      try {
        await db1.execute('BEGIN EXCLUSIVE TRANSACTION');

        try {
          // this should block the main thread
          await db2
              .execute('BEGIN EXCLUSIVE TRANSACTION')
              .timeout(const Duration(milliseconds: 500));
          fail('should timeout');
        } on TimeoutException catch (e) {
          print('caught $e');
        }

        // Try to open another db to check that the main thread is free
        var db = await factory.openDatabase(inMemoryDatabasePath);
        await db.close();
      } finally {
        await db1.close();
        await db2.close();
      }
    }, skip: !supportsDeadLock);
  });
}

var _allEscapeNames = [
  'abort',
  'action',
  'add',
  'after',
  'all',
  'alter',
  'analyze',
  'and',
  'as',
  'asc',
  'attach',
  'autoincrement',
  'before',
  'begin',
  'between',
  'by',
  'cascade',
  'case',
  'cast',
  'check',
  'collate',
  'column',
  'commit',
  'conflict',
  'constraint',
  'create',
  'cross',
  'current_date',
  'current_time',
  'current_timestamp',
  'database',
  'default',
  'deferrable',
  'deferred',
  'delete',
  'desc',
  'detach',
  'distinct',
  'drop',
  'each',
  'else',
  'end',
  'escape',
  'except',
  'exclusive',
  'exists',
  'explain',
  'fail',
  'for',
  'foreign',
  'from',
  'full',
  'glob',
  'group',
  'having',
  'if',
  'ignore',
  'immediate',
  'in',
  'index',
  'indexed',
  'initially',
  'inner',
  'insert',
  'instead',
  'intersect',
  'into',
  'is',
  'isnull',
  'join',
  'key',
  'left',
  'like',
  'limit',
  'match',
  'natural',
  'no',
  'not',
  'notnull',
  'null',
  'of',
  'offset',
  'on',
  'or',
  'order',
  'outer',
  'plan',
  'pragma',
  'primary',
  'query',
  'raise',
  'recursive',
  'references',
  'regexp',
  'reindex',
  'release',
  'rename',
  'replace',
  'restrict',
  'right',
  'rollback',
  'row',
  'savepoint',
  'select',
  'set',
  'table',
  'temp',
  'temporary',
  'then',
  'to',
  'transaction',
  'trigger',
  'union',
  'unique',
  'update',
  'using',
  'vacuum',
  'values',
  'view',
  'virtual',
  'when',
  'where',
  'with',
  'without'
];
