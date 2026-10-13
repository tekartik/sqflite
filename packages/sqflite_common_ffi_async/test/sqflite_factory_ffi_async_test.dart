@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:test/test.dart';

void main() {
  // Set sqflite ffi support in test
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfiAsyncTest;
  test('simple sqflite example', () async {
    var path = 'sqfite_ffi_async.db';
    var db = await databaseFactory.openDatabase(path);
    expect(await db.getVersion(), 0);
    await db.close();

    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
    expect(await db.getVersion(), 1);
    await db.close();

    db = await databaseFactory.openDatabase(
      'simple_version_1.db',
      options: OpenDatabaseOptions(version: 1),
    );
    expect(await db.getVersion(), 1);
    await db.close();
  });
  test('basic sqflite example', () async {
    var path = 'sqfite_ffi_async_basic.db';
    await databaseFactory.deleteDatabase(path);
    var database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
        },
      ),
    );
    await database.insert('Test', {'id': 1});
    await database.close();
  });
  test('in memory simple sqflite example', () async {
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();

    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
    expect(await db.getVersion(), 1);
    await db.close();
    db = await databaseFactory.openDatabase(
      'simple_version_1.db',
      options: OpenDatabaseOptions(version: 1),
    );
    expect(await db.getVersion(), 1);
    await db.close();
  }, skip: 'in-memory');
  test('query cursor error', () async {
    var db = await databaseFactory.openDatabase('sqflite_ffi_async_error.db');
    try {
      // Same exception type as rawQuery.
      await expectLater(
        () => db.rawQueryCursor('SELECT * FROM missing', null),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        () => db.rawQuery('SELECT * FROM missing'),
        throwsA(isA<DatabaseException>()),
      );
    } finally {
      await db.close();
    }
  });
  test('databasesPath', () async {
    var originalDatabasesPath = await databaseFactory.getDatabasesPath();
    expect(originalDatabasesPath, isNotNull);
  });
  test('exception', () async {
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    try {
      await db.insert('test', <String, Object?>{
        'blob': Uint8List.fromList([1, 2, 3]),
      });
      fail('should fail');
    } on DatabaseException catch (e) {
      // The blob is shown by its size, not its content.
      expect(e.toString(), contains('Blob(3)'));
      expect(e.toString(), isNot(contains('[1, 2, 3]')));
      // print(e);
    }
    try {
      var batch = db.batch();
      batch.insert('test', <String, Object?>{
        'blob': Uint8List.fromList([1, 2, 3]),
      });
      await batch.commit();
      fail('should fail');
    } on DatabaseException catch (e) {
      expect(e.toString(), isNot(contains('[1, 2, 3]')));
      // print(e);
    }

    await db.close();
  }, skip: 'in memory TODO');
}
