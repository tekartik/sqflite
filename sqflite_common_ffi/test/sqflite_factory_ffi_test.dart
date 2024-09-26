// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Set sqflite ffi support in test
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi; //.debugQuickLoggerWrapper();

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

  test('Defensive mode', () async {
    // This should fail...
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    Future<void> createTable() async {
      await db.execute('CREATE TABLE Test(value TEXT)');
    }

    Future<void> alterTable() async {
      await db.update('sqlite_master', {'sql': 'CREATE TABLE Test(value BLOB)'},
          where: 'name = \'Test\' and type = \'table\'');
    }

    try {
      await createTable();
      await alterTable();
    } catch (e) {
      print('Error update sqflite_master without protection (expected): $e');
    } finally {
      await db.close();
    }

    // This could fail...
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    try {
      await createTable();
      await db.execute('PRAGMA writable_schema = ON');
      await alterTable();
    } catch (e) {
      print(
          'Error update sqflite_master (could happen without defensive mode): $e');
    } finally {
      await db.close();
    }

    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    try {
      await createTable();
      // Workaround for iOS 14 / PR https://github.com/tekartik/sqflite/pull/1058
      await db.execute('PRAGMA sqflite -- db_config_defensive_off');
      await db.execute('PRAGMA writable_schema = ON');
      await alterTable();
    } finally {
      await db.close();
    }
  });
}
