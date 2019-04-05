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
  });
}
