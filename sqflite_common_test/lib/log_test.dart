import 'dart:async';

import 'package:test/test.dart';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/sqflite_test.dart';

/// Run log test
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  /*
  @deprecated
  Future sqfliteSetVerbose([bool verbose]) async {
    verbose ??= true;
    try {
      // ignore: deprecated_member_use
      await Sqflite.devSetOptions(
          // ignore: deprecated_member_use
          SqfliteOptions(
              logLevel:
                  verbose ? sqfliteLogLevelVerbose : sqfliteLogLevelNone));
    } catch (e) {
      print(e);
    }
  }*/

  group('log', () {
    test('open', () async {
      // Can use either of
      // ignore: deprecated_member_use_from_same_package
      // await sqfliteSetVerbose(true);
      // await Sqflite.setDebugModeOn(true);

      // Our database path
      String path;
      // Our database once opened
      Database db;

      try {
        /// Let's use FOREIGN KEY CONSTRAIN
        Future onConfigure(Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        }

        Future openCloseV1() async
        // Open 1st version
        {
          /// Create tables
          void _createTableCompanyV1(Batch batch) {
            batch.execute('DROP TABLE IF EXISTS Company');
            batch.execute('''CREATE TABLE Company (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT
)''');
          }

// First version of the database
          db = await factory.openDatabase(path,
              options: OpenDatabaseOptions(
                  version: 1,
                  onCreate: (db, version) async {
                    var batch = db.batch();
                    _createTableCompanyV1(batch);
                    await batch.commit();
                  },
                  onConfigure: onConfigure,
                  onDowngrade: onDatabaseDowngradeDelete));

          await db.close();
          db = null;
        }

        // Open 2nd version
        Future openCloseV2() async {
          /// Let's use FOREIGN KEY constraints
          Future onConfigure(Database db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          }

          /// Create Company table V2
          void _createTableCompanyV2(Batch batch) {
            batch.execute('DROP TABLE IF EXISTS Company');
            batch.execute('''CREATE TABLE Company (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  description TEXT
)''');
          }

          /// Update Company table V1 to V2
          void _updateTableCompanyV1toV2(Batch batch) {
            batch.execute('ALTER TABLE Company ADD description TEXT');
          }

          /// Create Employee table V2
          void _createTableEmployeeV2(Batch batch) {
            batch.execute('DROP TABLE IF EXISTS Employee');
            batch.execute('''CREATE TABLE Employee (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  companyId INTEGER,
  FOREIGN KEY (companyId) REFERENCES Company(id) ON DELETE CASCADE
  
)''');
          }

// 2nd version of the database
          db = await factory.openDatabase(path,
              options: OpenDatabaseOptions(
                  version: 2,
                  onConfigure: onConfigure,
                  onCreate: (db, version) async {
                    var batch = db.batch();
                    // We create all the tables
                    _createTableCompanyV2(batch);
                    _createTableEmployeeV2(batch);
                    await batch.commit();
                  },
                  onUpgrade: (db, oldVersion, newVersion) async {
                    var batch = db.batch();
                    if (oldVersion == 1) {
                      // We update existing table and create the new tables
                      _updateTableCompanyV1toV2(batch);
                      _createTableEmployeeV2(batch);
                    }
                    await batch.commit();
                  },
                  onDowngrade: onDatabaseDowngradeDelete));

          await db.close();
          db = null;
        }

        Future _readTest() async {
          db ??= await factory.openDatabase(path);
          expect(await db.query('Company'), [
            {'name': 'Watch', 'description': 'Black Wristatch', 'id': 1}
          ]);
          expect(await db.query('Employee'), [
            {'name': '1st Employee', 'companyId': 1, 'id': 1}
          ]);
        }

        Future _test() async {
          db = await factory.openDatabase(path);
          try {
            var companyId = await db.insert('Company', <String, dynamic>{
              'name': 'Watch',
              'description': 'Black Wristatch'
            });
            await db.insert('Employee', <String, dynamic>{
              'name': '1st Employee',
              'companyId': companyId
            });
            await _readTest();
          } finally {
            await db?.close();
            db = null;
          }
        }

        {
          // Test1
          path =
              await context.initDeleteDb('upgrade_add_table_and_column_doc.db');
          await openCloseV1();
          await openCloseV2();
          await _test();
        }
        {
          // Test2
          path =
              await context.initDeleteDb('upgrade_add_table_and_column_doc.db');
          await openCloseV2();
          await _test();
        }

        {
          // Test3
          await _readTest();
          await openCloseV2();
          await _readTest();
        }
        {
          // Test4 - don't delete before
          await openCloseV1();
          await openCloseV2();
          await _readTest();
        }
      } finally {
        await db?.close();
        // ignore: deprecated_member_use_from_same_package
        // await sqfliteSetVerbose(false);
      }
    });
  });
}
