import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Run open test.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  test('Open demo (doc)', () async {
    // await utils.devSetDebugModeOn(true);

    var path = await context.initDeleteDb('open_read_only.db');

    {
      Future onConfigure(Database db) async {
        // Add support for cascade delete
        await db.execute('PRAGMA foreign_keys = ON');
      }

      var db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(onConfigure: onConfigure),
      );
      await db.close();
    }

    {
      Future onCreate(Database db, int version) async {
        // Database is created, delete the table
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
        );
      }

      Future onUpgrade(Database db, int oldVersion, int newVersion) async {
        // Database version is updated, alter the table
        await db.execute('ALTER TABLE Test ADD name TEXT');
      }

      // Special callback used for onDowngrade here to recreate the database
      var db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
          onDowngrade: onDatabaseDowngradeDelete,
        ),
      );
      await db.close();
    }

    {
      Future onOpen(Database db) async {
        // Database is open, print its version
        print('db version ${await db.getVersion()}');
      }

      var db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(onOpen: onOpen),
      );
      await db.close();
    }
  });
}
