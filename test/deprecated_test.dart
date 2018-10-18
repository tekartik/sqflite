import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'src_database_test.dart';

void main() {
  group("deprecated", () {
    test("transaction", () async {
      final MockDatabase db = mockDatabaseFactory.newEmptyDatabase();
      await db.execute("test");
      await db.insert("test", <String, dynamic>{'test': 1});
      await db.update("test", <String, dynamic>{'test': 1});
      await db.delete("test");
      await db.query("test");

      await db.transaction((Transaction txn) async {
        await txn.execute("test");
        await txn.insert("test", <String, dynamic>{'test': 1});
        await txn.update("test", <String, dynamic>{'test': 1});
        await txn.delete("test");
        await txn.query("test");
      });

      final Batch batch = db.batch();
      batch.execute("test");
      batch.insert("test", <String, dynamic>{'test': 1});
      batch.update("test", <String, dynamic>{'test': 1});
      batch.delete("test");
      batch.query("test");
      // ignore: deprecated_member_use
      await batch.apply();
    });

    test('wrong database', () async {
      final MockDatabase db2 = mockDatabaseFactory.newEmptyDatabase();
      final MockDatabase db = await mockDatabaseFactory.openDatabase(null,
          options: OpenDatabaseOptions());

      final Batch batch = db2.batch();

      await db.transaction((Transaction txn) async {
        try {
          // ignore: deprecated_member_use
          await txn.applyBatch(batch);
          fail("should fail");
        } on ArgumentError catch (_) {}
      });
      await db.close();
      expect(db.methods,
          <String>['openDatabase', 'execute', 'execute', 'closeDatabase']);
      expect(db.sqls, <String>[null, 'BEGIN IMMEDIATE', 'COMMIT', null]);
    });
  });
  test('simple', () async {
    final MockDatabase db = await mockDatabaseFactory.openDatabase(null);

    final Batch batch = db.batch();
    batch.execute("test");
    // ignore: deprecated_member_use
    await batch.apply();
    // ignore: deprecated_member_use
    await batch.apply();
    await db.close();
    expect(db.methods, <String>[
      'openDatabase',
      'execute',
      'batch',
      'execute',
      'execute',
      'batch',
      'execute',
      'closeDatabase'
    ]);
    expect(db.sqls, <String>[
      null,
      'BEGIN IMMEDIATE',
      'test',
      'COMMIT',
      'BEGIN IMMEDIATE',
      'test',
      'COMMIT',
      null
    ]);
  });

  test('in_transaction', () async {
    final MockDatabase db = await mockDatabaseFactory.openDatabase(null);

    final Batch batch = db.batch();

    await db.transaction((Transaction txn) async {
      batch.execute("test");

      // ignore: deprecated_member_use
      await txn.applyBatch(batch);
      // ignore: deprecated_member_use
      await txn.applyBatch(batch);
    });
    await db.close();
    expect(db.methods, <String>[
      'openDatabase',
      'execute',
      'batch',
      'batch',
      'execute',
      'closeDatabase'
    ]);
    expect(db.sqls,
        <String>[null, 'BEGIN IMMEDIATE', 'test', 'test', 'COMMIT', null]);
  });
}
