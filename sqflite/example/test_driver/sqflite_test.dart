import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'package:sqflite/sqflite.dart';

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
      } finally {
        await db.close();
      }
    });
  });
}
