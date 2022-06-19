import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Documentation test.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  var databaseFactory = factory;

  /// Copy shortcut implementation
  Future<Database> openDatabase(String path,
      {int? version,
      OnDatabaseConfigureFn? onConfigure,
      OnDatabaseCreateFn? onCreate,
      OnDatabaseVersionChangeFn? onUpgrade,
      OnDatabaseVersionChangeFn? onDowngrade,
      OnDatabaseOpenFn? onOpen,
      bool readOnly = false,
      bool singleInstance = true}) {
    final options = OpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen,
        readOnly: readOnly,
        singleInstance: singleInstance);
    return databaseFactory.openDatabase(path, options: options);
  }

  group('doc', () {
    test('upgrade_add_table', () async {
      //await Sqflite.setDebugModeOn(true);

      // Our database path
      late String path;
      // Our database once opened
      Database? db;

      try {
        /// Let's use FOREIGN KEY CONSTRAIN
        Future onConfigure(Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        }

        Future openCloseV1() async
        // Open 1st version
        {
          /// Create tables
          void createTableCompanyV1(Batch batch) {
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
                    createTableCompanyV1(batch);
                    await batch.commit();
                  },
                  onConfigure: onConfigure,
                  onDowngrade: onDatabaseDowngradeDelete));

          await db!.close();
          db = null;
        }

        // Open 2nd version
        Future openCloseV2() async {
          /// Let's use FOREIGN KEY constraints
          Future onConfigure(Database db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          }

          /// Create Company table V2
          void createTableCompanyV2(Batch batch) {
            batch.execute('DROP TABLE IF EXISTS Company');
            batch.execute('''CREATE TABLE Company (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  description TEXT
)''');
          }

          /// Update Company table V1 to V2
          void updateTableCompanyV1toV2(Batch batch) {
            batch.execute('ALTER TABLE Company ADD description TEXT');
          }

          /// Create Employee table V2
          void createTableEmployeeV2(Batch batch) {
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
                    createTableCompanyV2(batch);
                    createTableEmployeeV2(batch);
                    await batch.commit();
                  },
                  onUpgrade: (db, oldVersion, newVersion) async {
                    var batch = db.batch();
                    if (oldVersion == 1) {
                      // We update existing table and create the new tables
                      updateTableCompanyV1toV2(batch);
                      createTableEmployeeV2(batch);
                    }
                    await batch.commit();
                  },
                  onDowngrade: onDatabaseDowngradeDelete));

          await db!.close();
          db = null;
        }

        Future readTest() async {
          db ??= await factory.openDatabase(path);
          expect(await db!.query('Company'), [
            {'name': 'Watch', 'description': 'Black Wristatch', 'id': 1}
          ]);
          expect(await db!.query('Employee'), [
            {'name': '1st Employee', 'companyId': 1, 'id': 1}
          ]);
        }

        Future insertTest() async {
          db = await factory.openDatabase(path);
          try {
            var companyId = await db!.insert('Company', <String, Object?>{
              'name': 'Watch',
              'description': 'Black Wristatch'
            });
            await db!.insert('Employee', <String, Object?>{
              'name': '1st Employee',
              'companyId': companyId
            });
            await readTest();
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
          await insertTest();
        }
        {
          // Test2
          path =
              await context.initDeleteDb('upgrade_add_table_and_column_doc.db');
          await openCloseV2();
          await insertTest();
        }

        {
          // Test3
          await readTest();
          await openCloseV2();
          await readTest();
        }
        {
          // Test4 - don't delete before
          await openCloseV1();
          await openCloseV2();
          await readTest();
        }
      } finally {
        await db?.close();
      }
    });

    test('record map', () async {
      var map = <String, Object?>{
        'title': 'Table',
        'size': <String, Object?>{'width': 80, 'height': 80}
      };

      map = <String, Object?>{'title': 'Table', 'width': 80, 'height': 80};

      map = <String, Object?>{
        'title': 'Table',
        'size': jsonEncode(<String, Object?>{'width': 80, 'height': 80})
      };
      final map2 = <String, Object?>{
        'title': 'Table',
        'size': '{"width":80,"height":80}'
      };
      expect(map, map2);
    });

    test('data_types', () async {
      var path = inMemoryDatabasePath;

      {
        /// Create tables
        void createTableCompanyV1(Batch batch) {
          batch.execute('''
CREATE TABLE Product (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  width INTEGER,
  height INTEGER
)''');
        }

// First version of the database
        var db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  var batch = db.batch();
                  createTableCompanyV1(batch);
                  await batch.commit();
                },
                onDowngrade: onDatabaseDowngradeDelete));

        var map = <String, Object?>{
          'title': 'Table',
          'width': 80,
          'height': 80
        };
        await db.insert('Product', map);
        await db.close();
      }

      {
        /// Create tables
        void createProductTable(Batch batch) {
          batch.execute('''
CREATE TABLE Product (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  size TEXT
)''');
        }

// First version of the database
        var db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  var batch = db.batch();
                  createProductTable(batch);
                  await batch.commit();
                },
                onDowngrade: onDatabaseDowngradeDelete));

        var map = <String, Object?>{
          'title': 'Table',
          'size': '{"width":80,"height":80}'
        };
        await db.insert('Product', map);
        await db.close();
      }
    });
    test('upsert', () async {
      // await factory.setLogLevel(sqfliteLogLevelVerbose);
      var path = inMemoryDatabasePath;

      {
        /// Create tables
        void createTableProduct(Batch batch) {
          batch.execute('''
CREATE TABLE Product (
  id TEXT PRIMARY KEY,
  title TEXT
)''');
        }

// First version of the database
        var db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  var batch = db.batch();
                  createTableProduct(batch);
                  await batch.commit();
                },
                onDowngrade: onDatabaseDowngradeDelete));

        Future<bool> exists(Transaction txn, Product product) async {
          return firstIntValue(await txn.query('Product',
                  columns: ['COUNT(*)'],
                  where: 'id = ?',
                  whereArgs: [product.id!])) ==
              1;
        }

        Future update(Transaction txn, Product product) async {
          await txn.update('Product', product.toMap(),
              where: 'id = ?', whereArgs: [product.id!]);
        }

        Future insert(Transaction txn, Product product) async {
          await txn.insert('Product', product.toMap()..['id'] = product.id);
        }

        Future upsertRecord(Product product) async {
          await db.transaction((txn) async {
            if (await exists(txn, product)) {
              await update(txn, product);
            } else {
              await insert(txn, product);
            }
          });
        }

        var product = Product()
          ..id = 'table'
          ..title = 'Table';
        await upsertRecord(product);
        await upsertRecord(product);

        var result = await db.query('Product');
        expect(result.length, 1, reason: 'list $result');
        await db.close();
      }
    });

    test('upsert_with_exception', () async {
      var path = inMemoryDatabasePath;

      {
        /// Create tables
        void createTableProduct(Batch batch) {
          batch.execute('''
CREATE TABLE Product (
  id TEXT PRIMARY KEY,
  title TEXT
)''');
        }

// First version of the database
        var db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  var batch = db.batch();
                  createTableProduct(batch);
                  await batch.commit();
                },
                onDowngrade: onDatabaseDowngradeDelete));

        Future update(Product product) async {
          await db.update('Product', product.toMap(),
              where: 'id = ?', whereArgs: [product.id!]);
        }

        Future insert(Product product) async {
          await db.insert('Product', product.toMap()..['id'] = product.id);
        }

        Future upsertRecord(Product product) async {
          try {
            await insert(product);
          } on DatabaseException catch (e) {
            if (e.isUniqueConstraintError()) {
              await update(product);
            } else {
              throw TestFailure('expected unique constraint $e');
            }
          }
        }

        var product = Product()
          ..id = 'table'
          ..title = 'Table';
        await upsertRecord(product);
        await upsertRecord(product);

        var result = await db.query('Product');
        expect(result.length, 1, reason: 'list $result');
        await db.close();
      }
    });

    test('Logging', () async {
      try {
        // ignore: deprecated_member_use
        await databaseFactory.setLogLevel(sqfliteLogLevelVerbose);
        var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
        await db.getVersion();
        await db.close();
      } finally {
        // ignore: deprecated_member_use
        await databaseFactory.setLogLevel(sqfliteLogLevelNone);
      }
    });

    test('BLOB lookup', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE test (id BLOB, value INTEGER)',
          );
        },
      );
      final id = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      await db.insert('test', {'id': id, 'value': 1});
      var result = await db.query('test', where: 'id = ?', whereArgs: [id]);
      print('regular blob lookup (failing on Android)): $result');

      // The compatible way to lookup for BLOBs (even work on Android) using the hex function
      result = await db
          .query('test', where: 'hex(id) = ?', whereArgs: [utils.hex(id)]);
      print('correct blob lookup: $result');

      expect(result.first['value'], 1);
    });
  });
}

/// Test product.
class Product {
  /// id.
  String? id;

  /// title.
  String? title;

  /// Export as a map.
  Map<String, Object?> toMap() {
    return <String, Object?>{'title': title};
  }
}
