import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Documentation test.

void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('database_factory', () {
    test('databaseExists', () async {
      var path = await context.initDeleteDb('database_exists.db');
      expect(await factory.databaseExists(path), isFalse);
      var db = await factory.openDatabase(path);
      await db.close();
      expect(await factory.databaseExists(path), isTrue);
    });

    test('deleteDatabase', () async {
      var path = await context.initDeleteDb('database_exists.db');
      var db = await factory.openDatabase(path);
      await db.close();
      expect(await factory.databaseExists(path), isTrue);
      await factory.deleteDatabase(path);
      expect(await factory.databaseExists(path), isFalse);

      // Delete while open
      db = await factory.openDatabase(path);
      expect(await factory.databaseExists(path), isTrue);
      await factory.deleteDatabase(path);
      expect(await factory.databaseExists(path), isFalse);
      try {
        await db.getVersion();
        fail('should fail, db was close by calling deleteDatabase');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
      await db.close();
    });

    test('setDatabasesPath', () async {
      var originalDatabasesPath = await factory.getDatabasesPath();
      try {
        var path = context.pathContext.normalize(
            context.pathContext.absolute(context.pathContext.current));
        await factory.setDatabasesPath(path);
        expect(await factory.getDatabasesPath(), path);
      } finally {
        try {
          await factory.setDatabasesPath(originalDatabasesPath);
        } catch (_) {}
      }
    });
    test('read/write', () async {
      var path = await context.initDeleteDb('database_read_bytes.db');
      var writtenPath = await context.initDeleteDb('database_written_bytes.db');
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (db, version) async {
                await db.execute(
                    'CREATE TABLE Test(id INTEGER PRIMARY KEY, value TEXT)');
              }));
      var textValue = 'value_to_read';
      await db.insert('Test', {'id': 1, 'value': textValue});
      expect(await db.query('Test'), [
        {'id': 1, 'value': textValue}
      ]);
      await db.close();
      var bytes = await factory.readDatabaseBytes(path);
      //expect(bytes.length, 8192);
      expect(bytes.sublist(0, 4), [
        83,
        81,
        76,
        105,
      ]);

      await factory.writeDatabaseBytes(writtenPath, bytes);
      db = await factory.openDatabase(writtenPath);
      expect(await db.query('Test'), [
        {'id': 1, 'value': textValue}
      ]);
      await db.close();
    });
  });
}
