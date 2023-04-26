@TestOn('vm')
library sqflite_common_ffi.test.sqflite_factory_ffi_test;

import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Set sqflite ffi support in test
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  test('simple sqflite example', () async {
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();

    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1));
    expect(await db.getVersion(), 1);
    await db.close();

    db = await databaseFactory.openDatabase('simple_version_1.db',
        options: OpenDatabaseOptions(version: 1));
    expect(await db.getVersion(), 1);
    await db.close();
  });
  test('databasesPath', () async {
    var originalDatabasesPath = await databaseFactory.getDatabasesPath();
    expect(originalDatabasesPath, isNotNull);
  });
  test('exception', () async {
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    try {
      await db.insert('test', <String, Object?>{
        'blob': Uint8List.fromList([1, 2, 3])
      });
      fail('should fail');
    } catch (e) {
      expect(e.toString(), contains('Blob(3)'));
      expect(e.toString(), isNot(contains([1, 2, 3])));
      // print(e);
    }
    try {
      var batch = db.batch();
      batch.insert('test', <String, Object?>{
        'blob': Uint8List.fromList([1, 2, 3])
      });
      await batch.commit();
      fail('should fail');
    } catch (e) {
      expect(e.toString(), isNot(contains([1, 2, 3])));
      // print(e);
    }

    await db.close();
  });
}
