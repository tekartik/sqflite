import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:synchronized/synchronized.dart';
import 'package:test/test.dart';

import 'src/core_import.dart';

export 'package:sqflite_common/sqflite_dev.dart';

/// Verify a condition in a test.
bool verify(bool condition, [String? message]) {
  message ??= 'verify failed';
  expect(condition, true, reason: message);
  return condition;
}

class _OpenCallbacks {
  _OpenCallbacks(this.databaseFactory) {
    onConfigure = (Database db) {
      //print('onConfigure');
      //verify(!onConfigureCalled, 'onConfigure must be called once');
      expect(onConfigureCalled, false,
          reason:
              'onConfigure already called'); // onConfigure must be called once
      onConfigureCalled = true;
    };

    onCreate = (Database db, int version) {
      //print('onCreate');
      expect(onConfigureCalled, true, reason: 'onConfigure not called');
      expect(onCreateCalled, false, reason: 'onCreate already called');
      onCreateCalled = true;
    };

    onOpen = (Database db) {
      //print('onOpen');
      expect(onConfigureCalled, isTrue,
          reason: 'onConfigure must be called before onOpen');
      expect(onOpenCalled, isFalse, reason: 'onOpen already called');
      onOpenCalled = true;
    };

    onUpgrade = (Database db, int oldVersion, int newVersion) {
      verify(onConfigureCalled!, 'onConfigure not called in onUpgrade');
      verify(!onUpgradeCalled, 'onUpgradeCalled already called');
      onUpgradeCalled = true;
    };

    onDowngrade = (Database db, int oldVersion, int newVersion) {
      verify(onConfigureCalled!, 'onConfigure not called');
      verify(!onDowngradeCalled, 'onDowngrade already called');
      onDowngradeCalled = true;
    };

    reset();
  }

  final DatabaseFactory databaseFactory;
  bool? onConfigureCalled;
  bool? onOpenCalled;
  bool? onCreateCalled;
  late bool onDowngradeCalled;
  late bool onUpgradeCalled;

  late OnDatabaseCreateFn onCreate;
  OnDatabaseConfigureFn? onConfigure;
  late OnDatabaseVersionChangeFn onDowngrade;
  late OnDatabaseVersionChangeFn onUpgrade;
  late OnDatabaseOpenFn onOpen;

  void reset() {
    onConfigureCalled = false;
    onOpenCalled = false;
    onCreateCalled = false;
    onDowngradeCalled = false;
    onUpgradeCalled = false;
  }

  Future<Database> open(String path, {required int version}) async {
    reset();
    return await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: version,
            onCreate: onCreate,
            onConfigure: onConfigure!,
            onDowngrade: onDowngrade,
            onUpgrade: onUpgrade,
            onOpen: onOpen));
  }
}

/// Run open test.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('open', () {
    test('Databases path', () async {
      // await utils.devSetDebugModeOn(false);
      var databasesPath = await factory.getDatabasesPath();
      // On Android we know it is current a 'databases' folder in the package folder
      print('databasesPath: $databasesPath');
      if (platform.isAndroid) {
        expect(basename(databasesPath), 'databases');
      } else if (platform.isIOS) {
        expect(basename(databasesPath), 'Documents');
      }
      var path =
          context.pathContext.join(databasesPath, 'in_default_directory.db');
      await factory.deleteDatabase(path);
      var db = await factory.openDatabase(path);
      await db.close();
    });

    Future<bool> checkFileExists(String path) async {
      var exists = false;
      try {
        var db = await factory.openDatabase(path,
            options:
                OpenDatabaseOptions(readOnly: true, singleInstance: false));
        exists = true;
        await db.close();
      } catch (_) {}
      return exists;
    }

    test('Delete database', () async {
      // await context.devSetDebugModeOn(true);
      //await context..devSetDebugModeOn(false);
      var path = await context.initDeleteDb('delete_database.db');
      expect(await checkFileExists(path), isFalse, reason: path);
      var db = await factory.openDatabase(path);
      await db.close();

      expect(await checkFileExists(path), isTrue);

      await factory.deleteDatabase(path);
      expect(await checkFileExists(path), isFalse);
    });

    test('Delete database while open', () async {
      var path = await context.initDeleteDb('delete_open_database.db');
      var db = await factory.openDatabase(path);
      await db.getVersion();

      await factory.deleteDatabase(path);
      try {
        await db.getVersion();
        fail('Should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }

      db = await factory.openDatabase(path);
      await db.getVersion();
    });

    test('Open no version', () async {
      //await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_no_version.db');
      expect(await checkFileExists(path), false);
      var db = await factory.openDatabase(path);
      verify(await checkFileExists(path));
      await db.close();
    });

    test('Open version 0', () async {
      //await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_version_0.db');
      expect(await checkFileExists(path), false);
      try {
        await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 0,
                onCreate: (Database db, int version) async {
                  fail('Should fail');
                }));
      } on ArgumentError catch (_) {}
      expect(await checkFileExists(path), false);
    });

    test('open in sub directory', () async {
      // await context.devSetDebugModeOn(true);
      var path =
          await context.deleteDirectory(join('sub_that_should_not_exists'));
      var dbPath = join(path, 'open.db');
      var db = await factory.openDatabase(dbPath);
      try {} finally {
        await db.close();
      }
    });

    test('open in sub sub directory', () async {
      // await context.devSetDebugModeOn(true);
      var path = await context
          .deleteDirectory(join('sub2_that_should_not_exists', 'sub_sub'));
      var dbPath = join(path, 'open.db');
      var db = await factory.openDatabase(dbPath);
      try {} finally {
        await db.close();
      }
    });

    test('isOpen', () async {
      //await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('is_open.db');
      expect(await checkFileExists(path), false);
      var db = await factory.openDatabase(path);
      expect(db.isOpen, true);
      verify(await checkFileExists(path));
      await db.close();
      expect(db.isOpen, false);
    });

    test('Open no version onCreate', () async {
      // should fail
      var path = await context.initDeleteDb('open_no_version_on_create.db');
      if (!context.isWeb) {
        verify(!(File(path).existsSync()));
      }
      Database? db;
      try {
        db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(onCreate: (Database db, int version) {
          // never called
          verify(false);
        }));
        verify(false);
      } on ArgumentError catch (_) {}
      verify(!File(path).existsSync());
      expect(db, null);
    });

    test('Open onCreate', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_test2.db');
      var onCreate = false;
      var onCreateTransaction = false;
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                expect(version, 1);
                onCreate = true;

                await db.transaction((txn) async {
                  await txn
                      .execute('CREATE TABLE Test2 (id INTEGER PRIMARY KEY)');
                  onCreateTransaction = true;
                });
              }));
      verify(onCreate);
      expect(onCreateTransaction, true);
      await db.close();
    });

    test('Open 2 databases', () async {
      //await utils.devSetDebugModeOn(true);
      var path1 = await context.initDeleteDb('open_db_1.db');
      var path2 = await context.initDeleteDb('open_db_2.db');
      var db1 = await factory.openDatabase(path1,
          options: OpenDatabaseOptions(version: 1));
      var db2 = await factory.openDatabase(path2,
          options: OpenDatabaseOptions(version: 1));
      await db1.close();
      await db2.close();
    });

    test('Open onUpgrade', () async {
      var onUpgrade = false;
      var path = await context.initDeleteDb('open_on_upgrade.db');
      var database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
              }));
      try {
        await database
            .insert('Test', <String, Object?>{'id': 1, 'name': 'test'});
        fail('should fail');
      } on DatabaseException catch (e) {
        print(e);
      } catch (e) {
        print('Exception: $e');
        rethrow;
      }
      await database.close();

      database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 2,
              onUpgrade: (Database db, int oldVersion, int newVersion) async {
                expect(oldVersion, 1);
                expect(newVersion, 2);
                await db.execute('ALTER TABLE Test ADD name TEXT');
                onUpgrade = true;
              }));
      expect(onUpgrade, isTrue);

      expect(
          await database
              .insert('Test', <String, Object?>{'id': 1, 'name': 'test'}),
          1);
      await database.close();
    });

    test('Open onDowngrade', () async {
      var path = await context.initDeleteDb('open_on_downgrade.db');
      var database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 2,
              onCreate: (Database db, int version) async {
                await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
              },
              onDowngrade: (Database db, int oldVersion, int newVersion) async {
                verify(false, 'should not be called');
              }));
      await database.close();

      var onDowngrade = false;
      database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onDowngrade: (Database db, int oldVersion, int newVersion) async {
                expect(oldVersion, 2);
                expect(newVersion, 1);
                await db.execute('ALTER TABLE Test ADD name TEXT');
                onDowngrade = true;
              }));
      verify(onDowngrade);

      await database.close();
    });

    test('Open bad path', () async {
      // Don't test on windows as it creates the path...
      if (!context.isWindows) {
        try {
          await factory.openDatabase('/invalid_path');
          fail('should fail');
        } on DatabaseException catch (e) {
          expect(e.toString(), contains('open_failed'));
          // expect(e.isOpenFailedError(), isTrue, reason: e.toString());
        }
      }
    });

    test('Open on configure', () async {
      var path = await context.initDeleteDb('open_on_configure.db');

      var onConfigured = false;
      var onConfiguredTransaction = false;
      Future onConfigure(Database db) async {
        onConfigured = true;
        await db.execute('CREATE TABLE Test1 (id INTEGER PRIMARY KEY)');
        await db.transaction((txn) async {
          await txn.execute('CREATE TABLE Test2 (id INTEGER PRIMARY KEY)');
          onConfiguredTransaction = true;
        });
      }

      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(onConfigure: onConfigure));
      expect(onConfigured, true);
      expect(onConfiguredTransaction, true);

      await db.close();
    });

    test('Open onDowngrade delete', () async {
      // await utils.devSetDebugModeOn(false);
      // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);

      var path = await context.initDeleteDb('open_on_downgrade_delete.db');
      var database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 3,
              onCreate: (Database db, int version) async {
                await db.execute('CREATE TABLE Test(id INTEGER PRIMARY KEY)');
              }));
      await database.close();

      // should fail going back in versions
      var onCreated = false;
      var onOpened = false;
      var onConfiguredOnce = false; // onConfigure will be called twice here
      // since the database is re-opened
      var onConfigured = false;
      database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 2,
              onConfigure: (Database db) {
                // Must not be configured nor created yet
                verify(!onConfigured);
                verify(!onCreated);
                if (!onConfiguredOnce) {
                  // first time
                  onConfiguredOnce = true;
                } else {
                  onConfigured = true;
                }
              },
              onCreate: (Database db, int version) {
                verify(onConfigured);
                verify(!onCreated);
                verify(!onOpened);
                onCreated = true;
                expect(version, 2);
              },
              onOpen: (Database db) {
                verify(onCreated);
                onOpened = true;
              },
              onDowngrade: onDatabaseDowngradeDelete));
      await database.close();

      expect(onCreated, true);
      expect(onOpened, true);
      expect(onConfigured, true);

      onCreated = false;
      onOpened = false;

      database = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 2,
              onCreate: (Database db, int version) {
                expect(false, 'should not be called');
              },
              onOpen: (Database db) {
                onOpened = true;
              },
              onDowngrade: onDatabaseDowngradeDelete));
      expect(onOpened, true);
      await database.close();
    });

    test('Version 0 callback', () async {
      // await utils.devSetDebugModeOn(false);
      var path = await context.initDeleteDb('open_all_callbacks_v0.db');

      var openCallbacks = _OpenCallbacks(factory);
      try {
        await openCallbacks.open(path, version: 0);
        fail('Should fail');
      } catch (e) {
        expect(e, const TypeMatcher<ArgumentError>());
      }
    });

    test('All open callback', () async {
      // await utils.devSetDebugModeOn(false);
      var path = await context.initDeleteDb('open_all_callbacks.db');

      var step = 1;
      var openCallbacks = _OpenCallbacks(factory);
      var db = await openCallbacks.open(path, version: 1);
      verify(openCallbacks.onConfigureCalled!, 'onConfiguredCalled $step');
      verify(openCallbacks.onCreateCalled!, 'onCreateCalled $step');
      verify(openCallbacks.onOpenCalled!, 'onOpenCalled $step');
      verify(!openCallbacks.onUpgradeCalled, 'onUpdateCalled $step');
      verify(!openCallbacks.onDowngradeCalled, 'onDowngradCalled $step');
      await db.close();

      ++step;
      db = await openCallbacks.open(path, version: 3);
      verify(openCallbacks.onConfigureCalled!, 'onConfiguredCalled $step');
      verify(!openCallbacks.onCreateCalled!, 'onCreateCalled $step');
      verify(openCallbacks.onOpenCalled!, 'onOpenCalled $step');
      verify(openCallbacks.onUpgradeCalled, 'onUpdateCalled $step');
      verify(!openCallbacks.onDowngradeCalled, 'onDowngradCalled $step');
      await db.close();

      ++step;
      db = await openCallbacks.open(path, version: 2);
      verify(openCallbacks.onConfigureCalled!, 'onConfiguredCalled $step');
      verify(!openCallbacks.onCreateCalled!, 'onCreateCalled $step');
      verify(openCallbacks.onOpenCalled!, 'onOpenCalled $step');
      verify(!openCallbacks.onUpgradeCalled, 'onUpdateCalled $step');
      verify(openCallbacks.onDowngradeCalled, 'onDowngradCalled $step');
      await db.close();

      openCallbacks.onDowngrade = onDatabaseDowngradeDelete;
      var configureCount = 0;
      var callback = openCallbacks.onConfigure;
      // allow being called twice
      openCallbacks.onConfigure = (Database db) {
        if (configureCount == 1) {
          openCallbacks.onConfigureCalled = false;
        }
        configureCount++;
        callback!(db);
      };
      ++step;
      db = await openCallbacks.open(path, version: 1);

      /*
      verify(openCallbacks.onConfigureCalled,'onConfiguredCalled $step');
      verify(configureCount == 2, 'onConfigure count');
      verify(openCallbacks.onCreateCalled, 'onCreateCalled $step');
      verify(openCallbacks.onOpenCalled, 'onOpenCalled $step');
      verify(!openCallbacks.onUpgradeCalled, 'onUpdateCalled $step');
      verify(!openCallbacks.onDowngradeCalled, 'onDowngradCalled $step');
      */
      await db.close();
    });

    test('Open batch', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_batch.db');

      Future onConfigure(Database db) async {
        var batch = db.batch();
        batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
        await batch.commit();
      }

      Future onCreate(Database db, int version) async {
        var batch = db.batch();
        batch.rawInsert("INSERT INTO Test(value) VALUES('value1')");
        await batch.commit();
      }

      Future onOpen(Database db) async {
        var batch = db.batch();
        batch.rawInsert("INSERT INTO Test(value) VALUES('value2')");
        await batch.commit();
      }

      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onConfigure: onConfigure,
              onCreate: onCreate,
              onOpen: onOpen));
      expect(
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test')),
          2);

      await db.close();
    });

    test('Open read-only', () async {
      // await context.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_read_only.db');

      Future onCreate(Database db, int version) async {
        var batch = db.batch();
        batch.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
        batch.rawInsert("INSERT INTO Test(value) VALUES('value1')");
        await batch.commit();
      }

      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(version: 1, onCreate: onCreate));
      expect(
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test')),
          1);

      await db.close();

      db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(readOnly: true));
      expect(
          utils.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Test')),
          1);

      try {
        await db.rawInsert("INSERT INTO Test(value) VALUES('value1')");
        fail('should fail');
      } on DatabaseException catch (e) {
        // Error DatabaseException(attempt to write a readonly database (code 8)) running Open read-only
        expect(e.isReadOnlyError(), true);
      }

      var batch = db.batch();
      batch.rawQuery('SELECT COUNT(*) FROM Test');
      await batch.commit();

      await db.close();
    });

    test('Open demo (doc)', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_read_only.db');

      {
        Future onConfigure(Database db) async {
          // Add support for cascade delete
          await db.execute('PRAGMA foreign_keys = ON');
        }

        var db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(onConfigure: onConfigure));
        await db.close();
      }

      {
        Future onCreate(Database db, int version) async {
          // Database is created, delete the table
          await db.execute(
              'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
        }

        Future onUpgrade(Database db, int oldVersion, int newVersion) async {
          // Database version is updated, alter the table
          await db.execute('ALTER TABLE Test ADD name TEXT');
        }

        // Special callback used for onDowngrade here to recreate the database
        var db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: onCreate,
                onUpgrade: onUpgrade,
                onDowngrade: onDatabaseDowngradeDelete));
        await db.close();
      }

      {
        Future onOpen(Database db) async {
          // Database is open, print its version
          print('db version ${await db.getVersion()}');
        }

        var db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
              onOpen: onOpen,
            ));
        await db.close();
      }

      // asset (use existing copy if any)
      {
        // Check if we have an existing copy first
        var databasesPath = await factory.getDatabasesPath();
        var path = join(databasesPath, 'demo_asset_example.db');

        // try opening (will work if it exists)
        Database? db;
        try {
          db = await factory.openDatabase(path,
              options: OpenDatabaseOptions(readOnly: true));
        } catch (e) {
          print('Error $e');
        }

        await db?.close();
      }
    });

    test('Database locked (doc)', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('open_locked.db');
      var helper = Helper(factory, path);

      // without the synchronized fix, this could faild
      for (var i = 0; i < 100; i++) {
        unawaited(helper.getDb());
      }
      var db = (await helper.getDb())!;
      await db.close();
    });

    test('single/multi instance (using factory)', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('instances_test.db');
      var db1 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: false));
      var db2 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: true));
      var db3 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: true));
      verify(db1 != db2);
      verify(db2 == db3);
      await db1.close();
      await db2.close();
      await db3.close(); // safe to close the same instance
    });

    test('single/multi instance', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('instances_test.db');
      var db1 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: false));
      var db2 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: true));
      var db3 = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: true));
      verify(db1 != db2);
      verify(db2 == db3);
      await db1.close();
      await db2.close();
      await db3.close(); // safe to close the same instance
    });

    /// Use single instance to force its value (which default to true).
    Future<void> testInMemoryDatabase(String path,
        {bool? singleInstance}) async {
      await factory.deleteDatabase(path);
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(singleInstance: singleInstance ?? true));
      try {
        await db
            .execute('CREATE TABLE IF NOT EXISTS Test(id INTEGER PRIMARY KEY)');
        await db.insert('Test', <String, Object?>{'id': 1});
        expect(await db.query('Test'), [
          {'id': 1}
        ]);

        await db.close();

        // reopen, content should be gone
        db = await factory.openDatabase(path);
        try {
          await db.query('Test');
          fail('fail');
        } on DatabaseException catch (e) {
          print(e);
        }
      } finally {
        await db.close();
      }
    }

    test('In memory database', () async {
      await testInMemoryDatabase(inMemoryDatabasePath);
      // This is also supported as it is converted to :memory:
      await testInMemoryDatabase('file::memory:');
    });

    if (context.supportsUri) {
      group('uri', () {
        test('uri in memory', () async {
          await testInMemoryDatabase('file:memdb1?mode=memory');
          await testInMemoryDatabase('file:memdb1?mode=memory',
              singleInstance: false);
        });

        test('uri int shared cache', () async {
          var dbFactory = factory; // .debugQuickLoggerWrapper();
          var path = 'file:memdb2?mode=memory&cache=shared';
          await dbFactory.deleteDatabase(path);
          var db1 = await dbFactory.openDatabase(path,
              options: OpenDatabaseOptions(singleInstance: false));
          var db2 = await dbFactory.openDatabase(path,
              options: OpenDatabaseOptions(singleInstance: false));

          verify(db1 != db2);
          await db1.execute(
              'CREATE TABLE IF NOT EXISTS Test(id INTEGER PRIMARY KEY)');
          await db1.insert('Test', <String, Object?>{'id': 1});
          expect(await db2.query('Test'), [
            {'id': 1}
          ]);
          await db1.close();
          await db2.close();
        }, skip: 'uri mode not consistently working with shared cache');

        test('uri absolute', () async {
          var path = await context.initDeleteDb('uri_absolute.db');
          var uri = Uri.file(path);
          var uriPath = uri.toString();
          var db = await factory.openDatabase(uriPath);
          try {
            await db.execute(
                'CREATE TABLE IF NOT EXISTS Test(id INTEGER PRIMARY KEY)');
            await db.insert('Test', <String, Object?>{'id': 1});
            expect(await db.query('Test'), [
              {'id': 1}
            ]);

            await db.close();

            // reopen, content should be there
            db = await factory.openDatabase(uriPath);
            await db.query('Test');
          } finally {
            await db.close();
          }
        });
      });
    }
    test('Not in memory database', () async {
      // await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('not_in_memory.db');

      var db = await factory.openDatabase(path);
      await db
          .execute('CREATE TABLE IF NOT EXISTS Test(id INTEGER PRIMARY KEY)');
      await db.insert('Test', <String, Object?>{'id': 1});
      expect(await db.query('Test'), [
        {'id': 1}
      ]);
      await db.close();

      // reopen, content should be done
      db = await factory.openDatabase(path);
      expect(await db.query('Test'), [
        {'id': 1}
      ]);
      await db.close();
    });

    test('close in transaction', () async {
      //await utils.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('close_in_transaction.db');

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

    test('multiple open different database', () async {
      // await context.devSetDebugModeOn(true);
      var path1 = await context.initDeleteDb('multiple_open_1.db');
      var path2 = await context.initDeleteDb('multiple_open_2.db');

      var onCreateCompleter1 = Completer<void>();
      var onCreateCompleter2 = Completer<void>();

      Database? db1;
      Database? db2;

      try {
        // Don't wait here
        var futureDb1 = factory.openDatabase(path1,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  // wait for db2
                  await onCreateCompleter2.future;
                  // mark as called
                  onCreateCompleter1.complete();
                }));
        db2 = await factory.openDatabase(path2,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  // mark as called
                  onCreateCompleter2.complete();
                  // wait for db1;
                  await onCreateCompleter1.future;
                }));
        db1 = await futureDb1;
        await onCreateCompleter1.future;
        await onCreateCompleter2.future;
      } finally {
        await db1?.close();
        await db2?.close();
      }
    });

    test('multiple open same database', () async {
      // await context.devSetDebugModeOn(true);
      var path1 = await context.initDeleteDb('multiple_open_same.db');
      var path2 = path1;

      var onCreateCompleter1 = Completer<void>();
      var onCreateCompleter2 = Completer<void>();

      Database? db1;
      Database db2;

      try {
        // Don't wait here
        var futureDb1 = factory.openDatabase(path1,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  // wait for db2
                  try {
                    await onCreateCompleter2.future
                        .timeout(const Duration(milliseconds: 1000));
                    fail('should fail before with a timeout exception');
                  } on TimeoutException catch (_) {
                    // expected
                  }
                  // mark as called
                  onCreateCompleter1.complete();
                }));
        db2 = await factory.openDatabase(path2,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  fail('should never be called');
                },
                onOpen: (db) async {
                  fail('should never be called');
                }));
        db1 = await futureDb1;
        // same db!
        expect(db1, db2);
        await onCreateCompleter1.future;
      } finally {
        await db1?.close();
      }
    });
  });
}

/// Open helper.
class Helper {
  /// Open helper.
  Helper(this.databaseFactory, this.path);

  /// Factory.
  final DatabaseFactory databaseFactory;

  /// Database path.
  final String path;
  Database? _db;
  final _lock = Lock();

  /// Get the opened database.
  Future<Database?> getDb() async {
    if (_db == null) {
      await _lock.synchronized(() async {
        // Check again once entering the synchronized block
        _db ??= await databaseFactory.openDatabase(path);
      });
    }
    return _db;
  }
}
