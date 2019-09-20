import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/utils.dart';
import 'package:test/test.dart';

void main() {
  group('sqflite', () {
    test('open null', () async {
      var exception;
      try {
        await openDatabase(null);
      } catch (e) {
        exception = e;
      }
      expect(exception, isNotNull);
    });
    test('exists', () async {
      expect(await databaseExists(inMemoryDatabasePath), isFalse);
      var path = 'test_exists.db';
      await deleteDatabase(path);
      expect(await databaseExists(path), isFalse);
      var db = await openDatabase(path);
      try {
        expect(await databaseExists(path), isTrue);
      } finally {
        await db?.close();
      }
    });
    test('close in transaction', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = 'test_close_in_transaction.db';
      var factory = databaseFactory;
      await deleteDatabase(path);
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(version: 1));
      try {
        await db.execute("BEGIN TRANSACTION");
        await db.close();

        db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(version: 1));
      } finally {
        await db.close();
      }
    });

    /// Check if a file is a valid database file
    ///
    /// An empty file is a valid empty sqlite file
    Future<bool> isDatabase(String path) async {
      Database db;
      bool isDatabase = false;
      try {
        db = await openReadOnlyDatabase(path);
        var version = await db.getVersion();
        if (version != null) {
          isDatabase = true;
        }
      } catch (_) {} finally {
        await db?.close();
      }
      return isDatabase;
    }

    test('read_only missing database', () async {
      var path = 'test_missing_database.db';
      await deleteDatabase(path);
      try {
        var db = await openReadOnlyDatabase(path);
        fail('should fail ${db?.path}');
      } on DatabaseException catch (_) {}

      expect(await isDatabase(path), isFalse);
    });

    test('read_only empty file', () async {
      var path = 'empty_file_database.db';
      await deleteDatabase(path);
      var fullPath = join(await getDatabasesPath(), path);
      await Directory(dirname(fullPath)).create(recursive: true);
      await File(fullPath).writeAsString('');

      // Open is fine, that is the native behavior
      var db = await openReadOnlyDatabase(fullPath);
      expect(await File(fullPath).readAsString(), '');

      await db.getVersion();

      await db.close();
      expect(await File(fullPath).readAsString(), '');
      expect(await isDatabase(fullPath), isTrue);
    });

    test('read_only missing bad format', () async {
      var path = 'test_bad_format_database.db';
      await deleteDatabase(path);
      var fullPath = join(await getDatabasesPath(), path);
      await Directory(dirname(fullPath)).create(recursive: true);
      await File(fullPath).writeAsString('test');

      // Open is fine, that is the native behavior
      var db = await openReadOnlyDatabase(fullPath);
      expect(await File(fullPath).readAsString(), 'test');
      try {
        var version = await db.getVersion();
        print(await db.query('sqlite_master'));
        fail('getVersion should fail ${db?.path} ${version}');
      } on DatabaseException catch (_) {
        // Android: DatabaseException(file is not a database (code 26 SQLITE_NOTADB)) sql 'PRAGMA user_version' args []}
      }
      await db.close();
      expect(await File(fullPath).readAsString(), 'test');

      expect(await isDatabase(fullPath), isFalse);
      expect(await isDatabase(fullPath), isFalse);

      expect(await File(fullPath).readAsString(), 'test');
    });

    test('multiple database', () async {
      //await Sqflite.devSetDebugModeOn(true);
      int count = 10;
      var dbs = List<Database>(count);
      for (int i = 0; i < count; i++) {
        var path = 'test_multiple_$i.db';
        await deleteDatabase(path);
        dbs[i] =
            await openDatabase(path, version: 1, onCreate: (db, version) async {
          await db
              .execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
          expect(
              await db
                  .rawInsert("INSERT INTO Test (name) VALUES (?)", ['test_$i']),
              1);
        });
      }

      for (int i = 0; i < count; i++) {
        var db = dbs[i];
        try {
          var name = (await db.query('Test', columns: ['name']))
              .first
              .values
              .first as String;
          expect(name, 'test_$i');
        } finally {
          await db.close();
        }
      }

      for (int i = 0; i < count; i++) {
        var db = dbs[i];
        await db.close();
      }
    });

    test('version', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = 'test_version.db';
      await deleteDatabase(path);
      var db = await openDatabase(path, version: 1);
      try {
        expect(await db.getVersion(), 1);
        unawaited(db.close());

        db = await openDatabase(path, version: 2);
        expect(await db.getVersion(), 2);
        unawaited(db.close());

        db = await openDatabase(path, version: 1);
        expect(await db.getVersion(), 1);
        unawaited(db.close());

        db = await openDatabase(path, version: 1);
        expect(await db.getVersion(), 1);
        expect(await isDatabase(path), isTrue);
      } finally {
        await db.close();
      }
      expect(await isDatabase(path), isTrue);
    });

    test('duplicated_column', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = 'test_duplicated_column.db';
      await deleteDatabase(path);
      var db = await openDatabase(path);
      try {
        await db.execute('CREATE TABLE Test (col1 INTEGER, col2 INTEGER)');
        await db.insert('Test', {'col1': 1, 'col2': 2});

        var result = await db.rawQuery(
            'SELECT t.col1, col1, t.col2, col2 AS col1 FROM Test AS t');
        expect(result, [
          {'col1': 2, 'col2': 2}
        ]);
      } finally {
        await db.close();
      }
    });

    test('indexed_param', () async {
      final db = await openDatabase(':memory:');
      expect(await db.rawQuery('SELECT ?1 + ?2', [3, 4]), [
        {'?1 + ?2': 7}
      ]);
      await db.close();
    });
  });
}
