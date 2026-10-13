@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/sqflite_ffi_impl.dart' show ffiDbs;
import 'package:test/test.dart';

/// Expect [action] to fail with a closed database error.
Future<void> expectDatabaseClosedError(
  Future<Object?> Function() action,
) async {
  try {
    await action();
    fail('should fail');
  } on DatabaseException catch (e) {
    expect(e.isDatabaseClosedError(), isTrue, reason: e.toString());
  }
}

void main() {
  sqfliteFfiInit();
  // No isolate, to check its databases.
  var factory = databaseFactoryFfiNoIsolate;
  late Directory dir;
  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('sqflite_ffi_close');
  });
  tearDownAll(() {
    dir.deleteSync(recursive: true);
  });

  group('close', () {
    test('closed and deleted databases are released', () async {
      var count = ffiDbs.length;
      for (var i = 0; i < 5; i++) {
        var db = await factory.openDatabase(inMemoryDatabasePath);
        await db.close();
      }
      var path = join(dir.path, 'released.db');
      for (var i = 0; i < 5; i++) {
        await factory.openDatabase(path);
        await factory.deleteDatabase(path);
      }
      expect(ffiDbs.length, count);
    });

    test('closed database errors', () async {
      var db = await factory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE t (id INTEGER)');
      var batch = db.batch()..rawInsert('INSERT INTO t (id) VALUES (1)');
      await db.close();
      // Closing twice is fine.
      await db.close();
      await expectDatabaseClosedError(() => db.rawQuery('SELECT 1'));
      await expectDatabaseClosedError(() => batch.commit());
      await expectDatabaseClosedError(() => batch.apply());
    });

    test('deleted single instance database errors', () async {
      var path = join(dir.path, 'deleted.db');
      var db = await factory.openDatabase(path);
      await db.execute('CREATE TABLE t (id INTEGER)');
      var batch = db.batch()..rawInsert('INSERT INTO t (id) VALUES (1)');
      await factory.deleteDatabase(path);
      await expectDatabaseClosedError(() => db.rawQuery('SELECT 1'));
      await expectDatabaseClosedError(() => batch.apply());
      // Closing a deleted database is fine.
      await db.close();
      db = await factory.openDatabase(path);
      expect(await db.rawQuery('SELECT 1 AS v'), [
        {'v': 1},
      ]);
      await db.close();
    });
  });
}
