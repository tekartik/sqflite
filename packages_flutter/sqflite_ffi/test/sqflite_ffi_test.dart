import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

/// Insert two rows from another isolate, sharing the sqflite isolate
/// through [IsolateNameServer].
Future<void> _insertInIsolate(String path) async {
  final db = await sqfliteDatabaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(rollbackActiveTransactionOnOpen: false),
  );
  await db.transaction((txn) async {
    await txn.insert('Test', {'name': 'isolate 1'});
    await txn.insert('Test', {'name': 'isolate 2'});
  });
  // Don't close the database, it is shared with the main isolate.
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final factory = sqfliteDatabaseFactoryFfi;

  // Run first, before the sqflite isolate is created in this isolate.
  test('stale registered port replaced', () async {
    // Simulate a registration left over by a dead isolate (e.g. after a
    // hot restart): nobody is listening on this port.
    final deadReceivePort = ReceivePort();
    final deadSendPort = deadReceivePort.sendPort;
    deadReceivePort.close();
    expect(
      IsolateNameServer.registerPortWithName(
        deadSendPort,
        sqfliteFfiIsolatePortName,
      ),
      isTrue,
    );

    // The factory should still work, spawning a new sqflite isolate and
    // replacing the stale registration.
    final db = await factory.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();

    final registeredPort = IsolateNameServer.lookupPortByName(
      sqfliteFfiIsolatePortName,
    );
    expect(registeredPort, isNotNull);
    expect(registeredPort, isNot(deadSendPort));
  });

  test('plugin registration sets the default factory', () async {
    expect(databaseFactoryOrNull, isNull);
    try {
      // Normally called automatically at startup through the generated
      // plugin registrant.
      SqfliteFfiPlugin.registerWith();
      expect(databaseFactoryOrNull, sqfliteDatabaseFactoryFfi);

      // Already set, should not override.
      SqfliteFfiPlugin.registerWith();
      expect(databaseFactoryOrNull, sqfliteDatabaseFactoryFfi);
    } finally {
      databaseFactoryOrNull = null;
    }
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

  test('isolate send port registered', () async {
    // Any call goes through the sqflite isolate.
    await factory.getDatabasesPath();
    expect(
      IsolateNameServer.lookupPortByName(sqfliteFfiIsolatePortName),
      isNotNull,
    );
  });

  test('sqflite isolate shared with other isolates', () async {
    final path = join(
      await factory.getDatabasesPath(),
      'sqflite_ffi_shared_isolate.db',
    );
    await factory.deleteDatabase(path);
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
          );
        },
        // Set to allow multiple isolates to use the same instance, forcing
        // here to false even in debug mode.
        rollbackActiveTransactionOnOpen: false,
      ),
    );
    try {
      // Start a transaction in the main isolate, lasting longer than the
      // background isolate startup.
      final insertFuture = db.transaction((txn) async {
        await txn.insert('Test', {'name': 'main 1'});
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await txn.insert('Test', {'name': 'main 2'});
      });
      final isolateFuture = compute(_insertInIsolate, path);
      await Future.wait([insertFuture, isolateFuture]);

      // Since the sqflite isolate is shared, the database instance is the
      // same and the background isolate transaction waits for the main
      // isolate one.
      final results = await db.query('Test', orderBy: 'id ASC');
      final names = results.map((row) => row['name']).toList();
      expect(names, ['main 1', 'main 2', 'isolate 1', 'isolate 2']);
    } finally {
      await db.close();
    }
  });
}
