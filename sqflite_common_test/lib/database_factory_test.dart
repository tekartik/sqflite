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
  });
}
