// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/src/common_import.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('sqflite', () {
    group('open', () {
      test('missing directory', () async {
        //await devVerbose();
        var path = join('test_missing_sub_dir', 'simple.db');
        try {
          await Directory(join(await getDatabasesPath(), dirname(path)))
              .delete(recursive: true);
        } catch (_) {}
        var db =
            await openDatabase(path, version: 1, onCreate: (db, version) async {
          expect(await db.getVersion(), 0);
        });
        expect(await db.getVersion(), 1);
        await db.close();
      });
      test('failure', () {
        // This one seems ignored
        // fail('regular test failure');
      });
      test('in_memory', () async {
        var db = await openDatabase(inMemoryDatabasePath, version: 1,
            onCreate: (db, version) async {
          expect(await db.getVersion(), 0);
        });
        expect(await db.getVersion(), 1);
        await db.close();
      });
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
        await db.close();
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
        await db.execute('BEGIN TRANSACTION');
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
      var isDatabase = false;
      Database? db;
      try {
        db = await openReadOnlyDatabase(path);
        await db.getVersion();
        isDatabase = true;
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
        fail('should fail ${db.path}');
      } on DatabaseException catch (_) {}

      expect(await isDatabase(path), isFalse);
    });

    test('read_only empty file', () async {
      var path = 'empty_file_database.db';
      await deleteDatabase(path);
      var fullPath = join((await getDatabasesPath()), path);
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
      var fullPath = join((await getDatabasesPath()), path);
      await Directory(dirname(fullPath)).create(recursive: true);
      await File(fullPath).writeAsString('test');

      // Open is fine, that is the native behavior
      var db = await openReadOnlyDatabase(fullPath);
      expect(await File(fullPath).readAsString(), 'test');
      try {
        var version = await db.getVersion();
        print(await db.query('sqlite_master'));
        fail('getVersion should fail ${db.path} $version');
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
      var count = 10;
      var dbs = List<Database?>.filled(count, null, growable: false);
      for (var i = 0; i < count; i++) {
        var path = 'test_multiple_$i.db';
        await deleteDatabase(path);
        dbs[i] =
            await openDatabase(path, version: 1, onCreate: (db, version) async {
          await db
              .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
          expect(
              await db
                  .rawInsert('INSERT INTO Test (name) VALUES (?)', ['test_$i']),
              1);
        });
      }

      for (var i = 0; i < count; i++) {
        var db = dbs[i]!;
        try {
          var name = (await db.query('Test', columns: ['name']))
              .first
              .values
              .first as String?;
          expect(name, 'test_$i');
        } finally {
          await db.close();
        }
      }

      for (var i = 0; i < count; i++) {
        var db = dbs[i]!;
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

    test('deleteDatabase', () async {
      // await devVerbose();
      late Database db;
      try {
        var path = 'test_delete_database.db';
        await deleteDatabase(path);
        db = await openDatabase(path);
        expect(await db.getVersion(), 0);
        await db.setVersion(1);

        // delete without closing every time
        await deleteDatabase(path);
        db = await openDatabase(path);
        expect(await db.getVersion(), 0);
        await db.execute('BEGIN TRANSACTION');
        await db.setVersion(2);

        await deleteDatabase(path);
        db = await openDatabase(path);
        expect(await db.getVersion(), 0);
        await db.setVersion(3);

        await deleteDatabase(path);
        db = await openDatabase(path);
        expect(await db.getVersion(), 0);
      } finally {
        await db.close();
      }
    });
  });
}
