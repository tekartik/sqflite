@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
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

  group('files', () {
    late String dir;
    setUpAll(() async {
      dir = join(await databaseFactory.getDatabasesPath(), 'ffi_async_files');
      await Directory(dir).create(recursive: true);
    });
    Future<Database> openTestDb(String path, {void Function()? onCreated}) {
      return databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            onCreated?.call();
            await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
          },
        ),
      );
    }

    test('openDatabase creates the file', () async {
      var path = join(dir, 'open_creates.db');
      await databaseFactory.deleteDatabase(path);
      var db = await databaseFactory.openDatabase(path);
      // sqlite_async opened its connections on the first statement only.
      expect(await databaseFactory.databaseExists(path), isTrue);
      await db.close();
    });

    test('delete an open database then open it again', () async {
      var path = join(dir, 'delete_open.db');
      await databaseFactory.deleteDatabase(path);
      var db = await openTestDb(path);
      await db.insert('Test', {'id': 1});
      await databaseFactory.deleteDatabase(path);
      // Closed by the delete.
      await expectLater(
        () => db.getVersion(),
        throwsA(isA<DatabaseException>()),
      );
      var created = false;
      // sqlite_async shares its pool by path: this used to reopen the
      // deleted file.
      db = await openTestDb(path, onCreated: () => created = true);
      await db.insert('Test', {'id': 2});
      expect(created, isTrue);
      expect(await db.query('Test'), [
        {'id': 2},
      ]);
      expect(File(path).existsSync(), isTrue);
      await db.close();
    });

    test('readDatabaseBytes of an open database', () async {
      var path = join(dir, 'bytes_open.db');
      var copyPath = join(dir, 'bytes_copy.db');
      await databaseFactory.deleteDatabase(path);
      await databaseFactory.deleteDatabase(copyPath);
      var db = await openTestDb(path);
      for (var i = 1; i <= 10; i++) {
        await db.insert('Test', {'id': i});
      }
      // WAL mode: the changes are in the -wal file until a checkpoint.
      var bytes = await databaseFactory.readDatabaseBytes(path);
      await databaseFactory.writeDatabaseBytes(copyPath, bytes);
      var copy = await databaseFactory.openDatabase(copyPath);
      try {
        expect(await copy.query('Test'), hasLength(10));
      } finally {
        await copy.close();
        await db.close();
      }
    });

    test('writeDatabaseBytes in a new directory', () async {
      var path = join(dir, 'bytes_src.db');
      await databaseFactory.deleteDatabase(path);
      var db = await openTestDb(path);
      await db.close();
      var bytes = await databaseFactory.readDatabaseBytes(path);
      var subDir = join(dir, 'new_dir');
      try {
        await Directory(subDir).delete(recursive: true);
      } catch (_) {}
      var copyPath = join(subDir, 'copy.db');
      // Created as with databaseFactoryFfi.
      await databaseFactory.writeDatabaseBytes(copyPath, bytes);
      db = await databaseFactory.openDatabase(copyPath);
      expect(await db.getVersion(), 1);
      await db.close();
    });

    test('file::memory:', () async {
      // In memory, as inMemoryDatabasePath (no temporary file).
      var db = await databaseFactory.openDatabase('file::memory:');
      expect(db.path, inMemoryDatabasePath);
      await db.close();
    });
  });
}
