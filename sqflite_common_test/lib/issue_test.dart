// ignore_for_file: unawaited_futures

import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Experimental tests.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  // In this bug, on Android, it seems after spawning multiple transactions
  // we sometimes get in a locked state.
  test('issue893', () async {
    //await Sqflite.setDebugModeOn(true);
    // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);
    var path = inMemoryDatabasePath;
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)',
          );
        },
      ),
    );
    Future<void> doInsert() async {
      await db.transaction((txn) async {
        // ignore: unused_local_variable
        var id = await txn.rawInsert('INSERT INTO Test (name) VALUES (?)', [
          'test',
        ]);
        // print('inserted $id');
      });
    }

    for (var i = 0; i < 200; i++) {
      unawaited(doInsert());
    }

    await doInsert();
    await db.close();
  });
}
