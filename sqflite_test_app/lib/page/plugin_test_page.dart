import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example_common/test_page.dart';

// ignore_for_file: avoid_print

/// Raw test page.
class PluginTestPage extends TestPage {
  /// Raw test page.
  PluginTestPage({Key? key}) : super('Plugin tests', key: key) {
    final factory = databaseFactory;

    if (Platform.isIOS) {
      test('darwinCreateUnprotectedFolder', () async {
        print('darwinCreateUnprotectedFolder');
        var parent = join(
          await factory.getDatabasesPath(),
          'darwinUnprotectedParent',
        );
        var unprotected = 'unprotected';

        if (Directory(parent).existsSync()) {
          await Directory(parent).delete(recursive: true);
        }
        var unprotectedPath = join(parent, unprotected);
        expect(Directory(unprotectedPath).existsSync(), isFalse);
        await SqfliteDarwin.createUnprotectedFolder(parent, unprotected);
        expect(Directory(unprotectedPath).existsSync(), isTrue);

        // Doc

        /// Default location for database (or use path_provider)
        var databasesPath = await factory.getDatabasesPath();

        late String dir;

        /// If you want to allow opening the db while your device is locked
        /// (push notification, background fetch) create an unprotected folder
        /// where the db will be created.
        if (Platform.isIOS) {
          dir = join(databasesPath, 'unprotected');
          if (!Directory(dir).existsSync()) {
            await SqfliteDarwin.createUnprotectedFolder(parent, unprotected);
          }
        } else {
          // ok for other platforms
          dir = databasesPath;
        }

        var db = await factory.openDatabase(
          join(dir, 'my_database.db'),
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              // ...
            },
          ),
        );

        await db.close();
      });
    }
    test('insert then isolate', () async {
      final path = await initDeleteDb('plugin_isolate_compute.db');

      // Open and init in main isolate
      var db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) {
            db.execute(
              'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
            );
          },
          singleInstance: true,
          // Set to allow multiple isolate
          // to use the same instance, forcing here to false even in debug mode
          rollbackActiveTransactionOnOpen: false,
        ),
      );
      try {
        var insertFuture = db.transaction((txn) async {
          await txn.insert('Test', {'name': 'main 1'});
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await txn.insert('Test', {'name': 'main 2'});
        });
        // Start compute
        final computeFuture = compute(
          _simpleInsertCompute,
          _InsertComputeParams(token: RootIsolateToken.instance!, path: path),
        );

        // Perform transaction with delay in main isolate
        await Future.wait([insertFuture, computeFuture]);

        final results = await db.query('Test', orderBy: 'id ASC');
        var names = results.map((map) => map['name']).toList();
        expect(names, ['main 1', 'main 2', 'compute 1', 'compute 2']);
      } finally {
        await db.close();
      }
    });
    test('insert in isolate then main', () async {
      final path = await initDeleteDb('plugin_isolate_compute_2.db');

      // Open and init in main isolate
      var db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) {
            db.execute(
              'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
            );
          },
          singleInstance: true,
          rollbackActiveTransactionOnOpen: false,
        ),
      );
      try {
        // Start compute first
        final computeFuture = compute(
          _simpleInsertCompute,
          _InsertComputeParams(token: RootIsolateToken.instance!, path: path),
        );

        // Delay main insertion a bit
        await Future<void>.delayed(const Duration(milliseconds: 200));

        var insertFuture = db.transaction((txn) async {
          await txn.insert('Test', {'name': 'main 1'});
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await txn.insert('Test', {'name': 'main 2'});
        });

        await Future.wait([insertFuture, computeFuture]);

        final results = await db.query('Test', orderBy: 'id ASC');
        var names = results.map((map) => map['name']).toList();
        expect(names, ['compute 1', 'compute 2', 'main 1', 'main 2']);
      } finally {
        await db.close();
      }
    });
  }
}

class _InsertComputeParams {
  _InsertComputeParams({required this.token, required this.path});

  final RootIsolateToken token;
  final String path;
}

/// Simple insert for compute testing.
Future<void> _simpleInsertCompute(_InsertComputeParams params) async {
  // Initialize the background binary messenger using the root token
  BackgroundIsolateBinaryMessenger.ensureInitialized(params.token);
  final db = await databaseFactory.openDatabase(
    params.path,
    options: OpenDatabaseOptions(
      // Force false even in debug mode
      rollbackActiveTransactionOnOpen: false,
    ),
  );
  await db.transaction((txn) async {
    await txn.insert('Test', {'name': 'compute 1'});
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await txn.insert('Test', {'name': 'compute 2'});
  });
  // Don't clean the database!
}
