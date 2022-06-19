import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Raw tests.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('raw', () {
    /*
      test('Options', () async {
        // utils.devSetDebugModeOn(true);

        var path =await context.initDeleteDb('raw_query_format.db');
        var db =await factory.openDatabase(path);

        var batch =db.batch();

        batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 1']);
        batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item 2']);
        await batch.commit();

        var sqfliteOptions = new SqfliteOptions()
          ..queryAsMapList = true;
        // ignore: deprecated_member_use
        await utils.devSetOptions(sqfliteOptions);
        String sql = 'SELECT id, name FROM Test';
        // ignore: deprecated_member_use
        var result = await db.devInvokeSqlMethod('query', sql);
        List expected = [
          {'id': 1, 'name': 'item 1'},
          {'id': 2, 'name': 'item 2'}
        ];
        print('result as map list $result');
        expect(result, expected);

        // empty
        sql = 'SELECT id, name FROM Test WHERE id=1234';
        // ignore: deprecated_member_use
        result = await db.devInvokeSqlMethod('query', sql);
        expected = [];
        print('result as map list $result');
        expect(result, expected);

        sqfliteOptions = new SqfliteOptions()
          ..queryAsMapList = false;
        // ignore: deprecated_member_use
        await utils.devSetOptions(sqfliteOptions);

        sql = 'SELECT id, name FROM Test';
        // ignore: deprecated_member_use
        var resultSet = await db.devInvokeSqlMethod('query', sql);
        var expectedResultSetMap = {
          'columns': ['id', 'name'],
          'rows': [
            [1, 'item 1'],
            [2, 'item 2']
          ]
        };
        print('result as r/c $resultSet');
        expect(resultSet, expectedResultSetMap);

        // empty
        sql = 'SELECT id, name FROM Test WHERE id=1234';
        // ignore: deprecated_member_use
        resultSet = await db.devInvokeSqlMethod('query', sql);
        expectedResultSetMap = {};
        print('result as r/c $resultSet');
        expect(resultSet, expectedResultSetMap);

        await db.close();
      });
      */
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

    /*
      test('Debug mode (log)', () async {
        //await utils.devSetDebugModeOn(false);
        var path =await context.initDeleteDb('debug_mode.db');
        var db =await factory.openDatabase(path);

        bool debugModeOn = await utils.getDebugModeOn();
        await utils.setDebugModeOn(true);
        await db.setVersion(1);
        await utils.setDebugModeOn(false);
        // this message should not appear
        await db.setVersion(2);
        await utils.setDebugModeOn(true);
        await db.setVersion(3);
        // restore
        await utils.setDebugModeOn(debugModeOn);

        await db.close();
      }, skip: true);
      */

    test('Demo', () async {
      // await utils.devSetDebugModeOn();
      var path = await context.initDeleteDb('simple_demo.db');
      var database = await factory.openDatabase(path);

      //int version = await database.update('PRAGMA user_version');
      //print('version: ${await database.update('PRAGMA user_version')}');
      print('version: ${await database.rawQuery('PRAGMA user_version')}');

      //print('drop: ${await database.update('DROP TABLE IF EXISTS Test')}');
      await database.execute('DROP TABLE IF EXISTS Test');

      print('dropped');
      await database.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
      print('table created');
      var id = await database.rawInsert(
          "INSERT INTO Test(name, value, num) VALUES('some name',1234,?)",
          [456.789]);
      print('inserted1: $id');
      id = await database.rawInsert(
          'INSERT INTO Test(name, value) VALUES(?, ?)',
          ['another name', 12345678]);
      print('inserted2: $id');
      var count = await database.rawUpdate(
          'UPDATE Test SET name = ?, VALUE = ? WHERE name = ?',
          ['updated name', '9876', 'some name']);
      print('updated: $count');
      expect(count, 1);
      var list = await database.rawQuery('SELECT * FROM Test');
      var expectedList = [
        <String, Object?>{
          'name': 'updated name',
          'id': 1,
          'value': 9876,
          'num': 456.789
        },
        <String, Object?>{
          'name': 'another name',
          'id': 2,
          'value': 12345678,
          'num': null
        }
      ];

      print('list: ${json.encode(list)}');
      print('expected $expectedList');
      expect(list, expectedList);

      count = await database
          .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
      print('deleted: $count');
      expect(count, 1);
      list = await database.rawQuery('SELECT * FROM Test');
      expectedList = [
        <String, Object?>{
          'name': 'updated name',
          'id': 1,
          'value': 9876,
          'num': 456.789
        },
      ];

      print('list: ${json.encode(list)}');
      print('expected $expectedList');
      expect(list, expectedList);

      await database.close();
    });

    test('Demo clean', () async {
      // Get a location
      var databasesPath = await factory.getDatabasesPath();

      // Make sure the directory exists
      try {
        await Directory(databasesPath).create(recursive: true);
      } catch (_) {}

      var path = join(databasesPath, 'demo.db');

      // Delete the database
      await factory.deleteDatabase(path);

      // open the database
      var database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                // When creating the db, create the table
                await db.execute(
                    'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
              }));

      // Insert some records in a transaction
      await database.transaction((txn) async {
        var id1 = await txn.rawInsert(
            "INSERT INTO Test(name, value, num) VALUES('some name', 1234, 456.789)");
        print('inserted1: $id1');
        var id2 = await txn.rawInsert(
            'INSERT INTO Test(name, value, num) VALUES(?, ?, ?)',
            ['another name', 12345678, 3.1416]);
        print('inserted2: $id2');
      });

      // Update some record
      var count = await database.rawUpdate(
          'UPDATE Test SET name = ?, VALUE = ? WHERE name = ?',
          ['updated name', '9876', 'some name']);
      print('updated: $count');

      // Get the records
      var list = await database.rawQuery('SELECT * FROM Test');
      var expectedList = <Map>[
        <String, Object?>{
          'name': 'updated name',
          'id': 1,
          'value': 9876,
          'num': 456.789
        },
        <String, Object?>{
          'name': 'another name',
          'id': 2,
          'value': 12345678,
          'num': 3.1416
        }
      ];
      print(list);
      print(expectedList);
      //assert(const DeepCollectionEquality().equals(list, expectedList));
      expect(list, expectedList);

      // Count the records
      count = utils
          .firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM Test'))!;
      expect(count, 2);

      // Delete a record
      count = await database
          .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
      expect(count, 1);

      // Close the database
      await database.close();
    });

    test('BatchQuery', () async {
      // await utils.devSetDebugModeOn();
      var path = await context.initDeleteDb('batch.db');
      var db = await factory.openDatabase(path);

      // empty batch
      var batch = db.batch();
      batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
      var results = await batch.commit();
      expect(results, [null, 1]);

      var dbResult = await db.rawQuery('SELECT id, name FROM Test');
      // devPrint('dbResult $dbResult');
      expect(dbResult, [
        {'id': 1, 'name': 'item1'}
      ]);

      // one query
      batch = db.batch();
      batch.rawQuery('SELECT id, name FROM Test');
      batch.query('Test', columns: ['id', 'name']);
      results = await batch.commit();
      // devPrint('select $results ${results?.first}');
      expect(results, [
        [
          {'id': 1, 'name': 'item1'}
        ],
        [
          {'id': 1, 'name': 'item1'}
        ]
      ]);
      await db.close();
    });
    test('Batch', () async {
      // await utils.devSetDebugModeOn();
      var path = await context.initDeleteDb('batch.db');
      var db = await factory.openDatabase(path);

      // empty batch
      var batch = db.batch();
      var results = await batch.commit();
      expect(results.length, 0);
      expect(results, []);

      // one create table
      batch = db.batch();
      batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      results = await batch.commit();
      // devPrint('1 $results ${results?.first}');
      expect(results, [null]);
      expect(results[0], null);

      // one insert
      batch = db.batch();
      batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
      results = await batch.commit();
      expect(results, [1]);

      // one query
      batch = db.batch();
      batch.rawQuery('SELECT id, name FROM Test');
      batch.query('Test', columns: ['id', 'name']);
      results = await batch.commit();
      // devPrint('select $results ${results?.first}');
      expect(results, [
        [
          {'id': 1, 'name': 'item1'}
        ],
        [
          {'id': 1, 'name': 'item1'}
        ]
      ]);

      // two insert
      batch = db.batch();
      batch.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item2']);
      batch.insert('Test', <String, Object?>{'name': 'item3'});
      results = await batch.commit();
      expect(results, [2, 3]);

      // update
      batch = db.batch();
      batch.rawUpdate(
          'UPDATE Test SET name = ? WHERE name = ?', ['new_item', 'item1']);
      batch.update('Test', <String, Object?>{'name': 'new_other_item'},
          where: 'name != ?', whereArgs: <String>['new_item']);
      results = await batch.commit();
      expect(results, [1, 2]);

      // delete
      batch = db.batch();
      batch.rawDelete('DELETE FROM Test WHERE name = ?', ['new_item']);
      batch.delete('Test',
          where: 'name = ?', whereArgs: <String>['new_other_item']);
      results = await batch.commit();
      expect(results, [1, 2]);

      // No result
      batch = db.batch();
      batch.insert('Test', <String, Object?>{'name': 'item'});
      batch.update('Test', <String, Object?>{'name': 'new_item'},
          where: 'name = ?', whereArgs: <String>['item']);
      batch.delete('Test', where: 'name = ?', whereArgs: <Object>['item']);
      results = await batch.commit(noResult: true);
      expect(results, []);

      await db.close();
    });

    test('Batch in transaction', () async {
      // await utils.devSetDebugModeOn();
      var path = await context.initDeleteDb('batch_in_transaction.db');
      var db = await factory.openDatabase(path);

      dynamic results;

      await db.transaction((txn) async {
        var batch1 = txn.batch();
        batch1.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        var batch2 = txn.batch();
        batch2.rawInsert('INSERT INTO Test (name) VALUES (?)', ['item1']);
        results = await batch1.commit();
        expect(results, [null]);

        results = await batch2.commit();
        expect(results, [1]);
      });

      await db.close();
    });

    test('Open twice', () async {
      // utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_twice.db');
      var db = await factory.openDatabase(path);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      var db2 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(readOnly: true));

      var count =
          utils.firstIntValue(await db2.rawQuery('SELECT COUNT(*) FROM Test'));
      expect(count, 0);
      await db.close();
      await db2.close();
    });

    test('text primary key', () async {
      // utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('text_primary_key.db');
      var db = await factory.openDatabase(path);
      // This table has no primary key however sqlite generates an hidden row id
      await db.execute('CREATE TABLE Test (name TEXT PRIMARY KEY)');
      var id = await db.insert('Test', <String, Object?>{'name': 'test'});
      expect(id, 1);
      id = await db.insert('Test', <String, Object?>{'name': 'other'});
      expect(id, 2);
      // row id is not retrieve by default
      var list = await db.query('Test');
      expect(list, [
        {'name': 'test'},
        {'name': 'other'}
      ]);
      list = await db.query('Test', columns: ['name', 'rowid']);
      expect(list, [
        {'name': 'test', 'rowid': 1},
        {'name': 'other', 'rowid': 2}
      ]);

      await db.close();
    });

    test('without rowid', () async {
      // utils.devSetDebugModeOn(true);
      // this fails on iOS

      late Database db;
      try {
        var path = await context.initDeleteDb('without_rowid.db');
        db = await factory.openDatabase(path);
        // This table has no primary key and we ask sqlite not to generate
        // a rowid
        await db
            .execute('CREATE TABLE Test (name TEXT PRIMARY KEY) WITHOUT ROWID');
        var id = await db.insert('Test', <String, Object?>{'name': 'test'});
        // it seems to always return 1 on Android, 0 on iOS...
        if (context.isIOS) {
          expect(id, 0);
        } else if (context.isAndroid) {
          expect(id, 1);
        } else if (context.supportsWithoutRowId) {
          expect(id, 0);
        } else {
          // Don't know: expect(id, 1);
        }
        id = await db.insert('Test', <String, Object?>{'name': 'other'});
        // it seems to always return 1
        if (context.isIOS) {
          expect(id, 0);
        } else if (context.isAndroid) {
          expect(id, 1);
        } else if (context.supportsWithoutRowId) {
          expect(id, 0);
        } else {
          // Don't know: expect(id, 1);
        }
        // notice the order is based on the primary key
        var list = await db.query('Test');
        expect(list, [
          {'name': 'other'},
          {'name': 'test'}
        ]);
      } finally {
        await db.close();
      }
    });

    test('Reference query', () async {
      var path = await context.initDeleteDb('reference_query.db');
      var db = await factory.openDatabase(path);
      try {
        var batch = db.batch();

        batch.execute('CREATE TABLE Other (id INTEGER PRIMARY KEY, name TEXT)');
        batch.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, other REFERENCES Other(id))');
        batch.rawInsert('INSERT INTO Other (name) VALUES (?)', ['other 1']);
        batch.rawInsert(
            'INSERT INTO Test (other, name) VALUES (?, ?)', [1, 'item 2']);
        await batch.commit();

        var result = await db.query('Test',
            columns: ['other', 'name'], where: 'other = 1');
        print(result);
        expect(result, [
          {'other': 1, 'name': 'item 2'}
        ]);
        result = await db.query('Test',
            columns: ['other', 'name'],
            where: 'other = ?',
            whereArgs: <Object>[1]);
        print(result);
        expect(result, [
          {'other': 1, 'name': 'item 2'}
        ]);
      } finally {
        await db.close();
      }
    });

    group('in_opened_memory_db', () {
      late Database db;

      setUp(() async {
        db = await factory.openDatabase(inMemoryDatabasePath);
      });
      tearDown(() async {
        await db.close();
      });

      test('insert conflict ignore', () async {
        await db.execute('''
      CREATE TABLE test (
        name TEXT PRIMARY KEY
      )''');
        var key1 = await db.insert('test', {'name': 'name 1'},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        var key2 = await db.insert('test', {'name': 'name 2'},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        // Conflict, key3 should be null
        var key3 = await db.insert('test', {'name': 'name 1'},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        expect([key1, key2, key3], [1, 2, 0]);
      });

      test('binding null', () async {
        for (var value in [null, 2]) {
          expect(
              utils.firstIntValue(await db.rawQuery(
                  'SELECT CASE WHEN 0 = 1 THEN 1 ELSE ? END', [value])),
              value);
        }
      });

      test('Modifying result', () async {
        await db.execute('''
      CREATE TABLE test (
        name TEXT PRIMARY KEY
      )''');
        await db.insert('test', {'name': 'name 1'});
        var list = await db.query('test');
        try {
          list.add(<String, Object?>{'name': 'some data'});
          fail('should fail');
        } on UnsupportedError catch (e) {
          expect(e.message, contains('read-only'));
          // read only
        }
        late Map<String, dynamic> map;
        try {
          map = list.first;
          // This crashes
          map['name'] = 'other';
        } on UnsupportedError catch (e) {
          expect(e.message, contains('read-only'));
          // read only
        }
        // Ok!
        list = List.from(list);
        list.add(<String, Object?>{'name': 'insert data'});

        // Ok!
        map = Map.from(map);
        map['name'] = 'other';
      });
    });
  });
}
