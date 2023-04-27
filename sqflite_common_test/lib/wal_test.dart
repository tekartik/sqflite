import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'src/core_import.dart';

export 'package:sqflite_common/sqflite_dev.dart';

/// Run open test.
void walTests(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('wal', () {
    test('wal files path', () async {
      if (io.Platform.isLinux) {
        // await utils.devSetDebugModeOn(false);
        var databasesPath = await factory.getDatabasesPath();
        // Use a specific folder.
        var walFolder = join(databasesPath, 'wal_test');
        var walDir = io.Directory(walFolder);
        try {
          await walDir.delete(recursive: true);
        } catch (_) {}
        await walDir.create(recursive: true);
        var dbPath = join(walFolder, 'wal_test.db');

        var db = await factory.openDatabase(dbPath,
            options: OpenDatabaseOptions(
                version: 1,
                singleInstance: false,
                onConfigure: (db) {
                  // make sure we have a wal file
                  db.execute('PRAGMA journal_mode = WAL');
                },
                onCreate: (db, version) async {
                  await db.execute(
                      'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
                }));

        try {
          await db.transaction((txn) async {
            await txn.insert('Test', {'name': 'test'});

            await factory.deleteDatabase(dbPath);
            expect(await walDir.list().toList(), isEmpty);
          });
        } catch (e) {
          expect(e, isNot(isA<TestFailure>()));
        }
        try {
          await db.close();
        } catch (_) {}
      }
    });
  });
}
