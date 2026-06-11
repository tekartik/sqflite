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
        var path = context.isWeb
            ? '/some_top_path'
            : context.pathContext.normalize(
                context.pathContext.absolute(context.pathContext.current),
              );
        await factory.setDatabasesPath(path);
        expect(await factory.getDatabasesPath(), path);
      } finally {
        try {
          await factory.setDatabasesPath(originalDatabasesPath);
        } catch (_) {}
      }
    });
    group('sandbox', () {
      test('open/exists/delete', () async {
        var sandboxPath = await context.createDirectory('sandbox_test');
        var sandboxed = factory.sandbox(path: sandboxPath);
        expect(await sandboxed.getDatabasesPath(), sandboxPath);

        var dbName = 'sandbox_demo.db';
        var delegatePath = context.pathContext.join(sandboxPath, dbName);
        await sandboxed.deleteDatabase(dbName);
        expect(await sandboxed.databaseExists(dbName), isFalse);

        var db = await sandboxed.openDatabase(
          dbName,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                'CREATE TABLE Test(id INTEGER PRIMARY KEY, value TEXT)',
              );
            },
          ),
        );
        await db.insert('Test', {'id': 1, 'value': 'sandboxed'});
        await db.close();

        // The database is visible in the delegate factory under the sandbox
        // root.
        expect(await sandboxed.databaseExists(dbName), isTrue);
        expect(await factory.databaseExists(delegatePath), isTrue);

        // Open through the delegate factory.
        db = await factory.openDatabase(delegatePath);
        expect(await db.query('Test'), [
          {'id': 1, 'value': 'sandboxed'},
        ]);
        await db.close();

        await sandboxed.deleteDatabase(dbName);
        expect(await sandboxed.databaseExists(dbName), isFalse);
        expect(await factory.databaseExists(delegatePath), isFalse);
      });

      test('default path', () async {
        var sandboxed = factory.sandbox();
        expect(
          await sandboxed.getDatabasesPath(),
          await factory.getDatabasesPath(),
        );
      });

      test('in memory', () async {
        var sandboxed = factory.sandbox(path: 'sandbox_test');
        var db = await sandboxed.openDatabase(inMemoryDatabasePath);
        await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
        await db.close();
      });

      test('escape attempt', () async {
        var sandboxPath = await context.createDirectory('sandbox_test');
        var sandboxed = factory.sandbox(path: sandboxPath);
        var p = context.pathContext;
        await expectLater(
          () => sandboxed.openDatabase(p.join('..', 'escape.db')),
          throwsArgumentError,
        );
        await expectLater(
          () =>
              sandboxed.databaseExists(p.join(sandboxPath, '..', 'escape.db')),
          throwsArgumentError,
        );
        await expectLater(
          () => sandboxed.deleteDatabase('.'),
          throwsArgumentError,
        );
      });

      test('setDatabasesPath', () async {
        var sandboxPath = await context.createDirectory('sandbox_test');
        var sandboxed = factory.sandbox(path: sandboxPath);
        var p = context.pathContext;
        var subPath = p.join(sandboxPath, 'sub');
        await sandboxed.setDatabasesPath(subPath);
        expect(await sandboxed.getDatabasesPath(), subPath);
        await context.createDirectory(subPath);
        var dbName = 'sandbox_sub_demo.db';
        await sandboxed.deleteDatabase(dbName);
        var db = await sandboxed.openDatabase(dbName);
        await db.close();
        expect(await factory.databaseExists(p.join(subPath, dbName)), isTrue);
        await sandboxed.deleteDatabase(dbName);

        // Cannot escape the sandbox root.
        var factoryDatabasesPath = await factory.getDatabasesPath();
        await expectLater(
          () => sandboxed.setDatabasesPath(factoryDatabasesPath),
          throwsArgumentError,
        );
      });
    });
    test('read/write', () async {
      var path = await context.initDeleteDb('database_read_bytes.db');
      var writtenPath = await context.initDeleteDb('database_written_bytes.db');
      var db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE Test(id INTEGER PRIMARY KEY, value TEXT)',
            );
          },
        ),
      );
      var textValue = 'value_to_read';
      await db.insert('Test', {'id': 1, 'value': textValue});
      expect(await db.query('Test'), [
        {'id': 1, 'value': textValue},
      ]);
      await db.close();
      var bytes = await factory.readDatabaseBytes(path);
      //expect(bytes.length, 8192);
      expect(bytes.sublist(0, 4), [83, 81, 76, 105]);

      await factory.writeDatabaseBytes(writtenPath, bytes);
      db = await factory.openDatabase(writtenPath);
      expect(await db.query('Test'), [
        {'id': 1, 'value': textValue},
      ]);
      await db.close();
    });
  });
}
