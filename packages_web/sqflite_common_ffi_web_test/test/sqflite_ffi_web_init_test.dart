@TestOn('browser')
library;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/wasm.dart' show IndexedDbFileSystem;
import 'package:test/test.dart';

/// Basic worker (one worker per factory) built by `tool/setup_web_tests.dart`.
DatabaseFactory _basicWorkerFactory({
  required String indexedDbName,
  Uri? sqlite3WasmUri,
}) => createDatabaseFactoryFfiWeb(
  options: SqfliteFfiWebOptions(
    // ignore: invalid_use_of_visible_for_testing_member
    forceAsBasicWorker: true,
    sharedWorkerUri: Uri.parse('sqflite_sw_v1.js'),
    indexedDbName: indexedDbName,
    sqlite3WasmUri: sqlite3WasmUri,
  ),
);

Future<void> main() async {
  group('worker init', () {
    test('two first calls at once', () async {
      // A new worker: both calls arrive before sqlite3.wasm is loaded. Each
      // loaded its own sqlite3 and IndexedDB image
      // (sqflite_common_ffi_web <= 1.2.0+1).
      var factory = _basicWorkerFactory(indexedDbName: 'sqflite_init_race');
      var dbs = await Future.wait([
        factory.openDatabase('/init_race_a.db'),
        factory.openDatabase('/init_race_b.db'),
      ]);
      var db = dbs[0];
      try {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS Test (id INTEGER PRIMARY KEY)',
        );
        await db.insert('Test', {
          'id': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        expect(await factory.databaseExists('/init_race_a.db'), isTrue);
        var bytes = await factory.readDatabaseBytes('/init_race_a.db');
        expect(bytes.sublist(0, 4), [83, 81, 76, 105]); // SQLi
      } finally {
        for (var db in dbs) {
          await db.close();
        }
      }
    });

    test('missing sqlite3.wasm', () async {
      var factory = _basicWorkerFactory(
        indexedDbName: 'sqflite_init_missing_wasm',
        sqlite3WasmUri: Uri.parse('missing_sqlite3.wasm'),
      );
      // The load error is the error of the call (it was a null result,
      // sqflite_common_ffi_web <= 1.2.0+1).
      await expectLater(
        () => factory.openDatabase('/init_missing_wasm.db'),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.toString(),
            'toString()',
            contains('missing_sqlite3.wasm'),
          ),
        ),
      );
    });
  });

  test('inMemory option', () async {
    // Ignored, the databases were stored in IndexedDB
    // (sqflite_common_ffi_web <= 1.2.0+1).
    var indexedDbName = 'sqflite_in_memory_option';
    var factory = createDatabaseFactoryFfiWeb(
      noWebWorker: true,
      options: SqfliteFfiWebOptions(
        inMemory: true,
        indexedDbName: indexedDbName,
      ),
    );
    var db = await factory.openDatabase('/in_memory_option.db');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS Test (id INTEGER PRIMARY KEY)',
    );
    await db.close();
    var fs = await IndexedDbFileSystem.open(dbName: indexedDbName);
    try {
      expect(fs.xAccess('/in_memory_option.db', 0), 0);
    } finally {
      await fs.close();
    }
  });
}
