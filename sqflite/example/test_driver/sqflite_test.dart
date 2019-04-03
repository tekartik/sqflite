import 'package:flutter_test/flutter_test.dart';
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
  });
}
