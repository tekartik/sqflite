import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_example_common/test_page.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

// ignore_for_file: avoid_print

/// Sqflite ffi test page, the sqflite isolate being shared between
/// flutter isolates using `IsolateNameServer`.
class SqfliteFfiTestPage extends TestPage {
  /// Sqflite ffi test page.
  SqfliteFfiTestPage({Key? key}) : super('Sqflite ffi tests', key: key) {
    sqfliteFfiInit();
    final factory = sqfliteDatabaseFactoryFfi;

    Future<String> initDeleteDb(String name) async {
      final path = join(await factory.getDatabasesPath(), name);
      await factory.deleteDatabase(path);
      return path;
    }

    Future<Database> openTestDb(String path) {
      return factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
            );
          },
          singleInstance: true,
          // Set to allow multiple isolates
          // to use the same instance, forcing here to false even in debug mode
          rollbackActiveTransactionOnOpen: false,
        ),
      );
    }

    test('isolate port registered', () async {
      // Any call goes through the sqflite isolate.
      await factory.getDatabasesPath();
      expect(
        IsolateNameServer.lookupPortByName(sqfliteFfiIsolatePortName),
        isNotNull,
      );
    });

    test('open insert query', () async {
      final db = await factory.openDatabase(inMemoryDatabasePath);
      try {
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
        );
        await db.insert('Test', {'name': 'one'});
        expect(await db.query('Test'), [
          {'id': 1, 'name': 'one'},
        ]);
      } finally {
        await db.close();
      }
    });

    test('insert then isolate', () async {
      final path = await initDeleteDb('ffi_isolate_compute.db');

      // Open and init in main isolate
      final db = await openTestDb(path);
      try {
        final insertFuture = db.transaction((txn) async {
          await txn.insert('Test', {'name': 'main 1'});
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await txn.insert('Test', {'name': 'main 2'});
        });
        // Start compute, sharing the sqflite isolate
        final computeFuture = compute(_simpleInsertCompute, path);

        // Perform transaction with delay in main isolate
        await Future.wait([insertFuture, computeFuture]);

        final results = await db.query('Test', orderBy: 'id ASC');
        final names = results.map((map) => map['name']).toList();
        expect(names, ['main 1', 'main 2', 'compute 1', 'compute 2']);
      } finally {
        await db.close();
      }
    });

    test('insert in isolate then main', () async {
      final path = await initDeleteDb('ffi_isolate_compute_2.db');

      // Open and init in main isolate
      final db = await openTestDb(path);
      try {
        // Start compute first
        final computeFuture = compute(_simpleInsertCompute, path);

        // Delay main insertion a bit
        await Future<void>.delayed(const Duration(milliseconds: 200));

        final insertFuture = db.transaction((txn) async {
          await txn.insert('Test', {'name': 'main 1'});
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await txn.insert('Test', {'name': 'main 2'});
        });

        await Future.wait([insertFuture, computeFuture]);

        final results = await db.query('Test', orderBy: 'id ASC');
        final names = results.map((map) => map['name']).toList();
        expect(names, ['compute 1', 'compute 2', 'main 1', 'main 2']);
      } finally {
        await db.close();
      }
    });
  }
}

/// Simple insert for compute testing.
///
/// `sqfliteDatabaseFactoryFfi` here looks up the sqflite isolate send port
/// registered by the main isolate using `IsolateNameServer` and reuses it.
Future<void> _simpleInsertCompute(String path) async {
  final db = await sqfliteDatabaseFactoryFfi.openDatabase(
    path,
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
  // Don't close the database, it is shared with the main isolate!
}
