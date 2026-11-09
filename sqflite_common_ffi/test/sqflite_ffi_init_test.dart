@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

var _initCount = 0;

void _countingInit() {
  _initCount++;
}

void _throwingInit() {
  throw StateError('my init failed');
}

void main() {
  sqfliteFfiInit();

  // Must be the first test of the file: the sqflite isolate (one per test
  // file isolate) is created by the first ffi call.
  test('isolate ffiInit error', () async {
    var factory = createDatabaseFactoryFfi(ffiInit: _throwingInit);
    // It used to wait forever, each call tries again.
    for (var i = 0; i < 2; i++) {
      try {
        await factory
            .openDatabase(inMemoryDatabasePath)
            .timeout(const Duration(seconds: 30));
        fail('should fail');
      } on DatabaseException catch (e) {
        expect(e.toString(), contains('my init failed'));
      }
    }
    // The sqflite isolate can still be created afterwards.
    var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });

  test('noIsolate ffiInit called once', () async {
    var factory = createDatabaseFactoryFfi(
      ffiInit: _countingInit,
      noIsolate: true,
    );
    var db = await factory.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
    await db.insert('t', {'id': 1});
    expect(await db.query('t'), [
      {'id': 1},
    ]);
    await db.close();
    expect(_initCount, 1);
  });
}
