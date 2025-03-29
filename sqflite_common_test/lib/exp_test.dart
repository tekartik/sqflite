// ignore_for_file: unawaited_futures

import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

import 'open_test.dart';

/// Experimental tests.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  test('order_by', () async {
    //await Sqflite.setDebugModeOn(true);
    var path = await context.initDeleteDb('order_by_exp.db');
    var db = await factory.openDatabase(path);

    var table = 'test';
    await db.execute(
      'CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)',
    );
    // inserted in a wrong order to check ASC/DESC
    await db.execute(
      'INSERT INTO $table (column_1, column_2) VALUES (11, 180)',
    );
    await db.execute(
      'INSERT INTO $table (column_1, column_2) VALUES (10, 180)',
    );
    await db.execute(
      'INSERT INTO $table (column_1, column_2) VALUES (10, 2000)',
    );

    var expectedResult = [
      {'column_1': 10, 'column_2': 2000},
      {'column_1': 10, 'column_2': 180},
      {'column_1': 11, 'column_2': 180},
    ];

    var result = await db.rawQuery(
      'SELECT * FROM $table ORDER BY column_1 ASC, column_2 DESC',
    );
    //print(JSON.encode(result));
    expect(result, expectedResult);
    result = await db.query(table, orderBy: 'column_1 ASC, column_2 DESC');
    expect(result, expectedResult);

    await db.close();
  });

  test('in', () async {
    //await Sqflite.devSetDebugModeOn(true);
    var path = await context.initDeleteDb('simple_exp.db');
    var db = await factory.openDatabase(path);

    var table = 'test';
    await db.execute(
      'CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)',
    );
    await db.execute(
      'INSERT INTO $table (column_1, column_2) VALUES (1, 1001)',
    );
    await db.execute(
      'INSERT INTO $table (column_1, column_2) VALUES (2, 1002)',
    );
    await db.execute(
      'INSERT INTO $table (column_1, column_2) VALUES (2, 1012)',
    );
    await db.execute(
      'INSERT INTO $table (column_1, column_2) VALUES (3, 1003)',
    );

    var expectedResult = [
      {'column_1': 1, 'column_2': 1001},
      {'column_1': 2, 'column_2': 1002},
      {'column_1': 2, 'column_2': 1012},
    ];

    // testing with value in the In clause
    var result = await db.query(
      table,
      where: 'column_1 IN (1, 2)',
      orderBy: 'column_1 ASC, column_2 ASC',
    );
    //print(JSON.encode(result));
    expect(result, expectedResult);

    // testing with value as arguments
    result = await db.query(
      table,
      where: 'column_1 IN (?, ?)',
      whereArgs: <Object>['1', '2'],
      orderBy: 'column_1 ASC, column_2 ASC',
    );
    expect(result, expectedResult);

    await db.close();
  });

  test('Raw escaping', () async {
    //await Sqflite.devSetDebugModeOn(true);
    var path = await context.initDeleteDb('raw_escaping_fields.db');
    var db = await factory.openDatabase(path);

    var table = 'table';
    await db.execute('CREATE TABLE "$table" ("group" INTEGER)');
    // inserted in a wrong order to check ASC/DESC
    await db.execute('INSERT INTO "$table" ("group") VALUES (1)');

    var expectedResult = [
      {'group': 1},
    ];

    var result = await db.rawQuery(
      'SELECT "group" FROM "$table" ORDER BY "group" DESC',
    );
    print(result);
    expect(result, expectedResult);
    result = await db.rawQuery("SELECT * FROM '$table' ORDER BY `group` DESC");
    //print(JSON.encode(result));
    expect(result, expectedResult);

    await db.rawDelete("DELETE FROM '$table'");

    await db.close();
  });

  test('Escaping fields', () async {
    //await Sqflite.devSetDebugModeOn(true);
    var path = await context.initDeleteDb('escaping_fields.db');
    var db = await factory.openDatabase(path);

    var table = 'group';
    await db.execute('CREATE TABLE "$table" ("group" TEXT)');
    // inserted in a wrong order to check ASC/DESC

    await db.insert(table, <String, Object?>{'group': 'group_value'});
    await db.update(table, <String, Object?>{
      'group': 'group_new_value',
    }, where: "\"group\" = 'group_value'");

    var expectedResult = [
      {'group': 'group_new_value'},
    ];

    var result = await db.query(
      table,
      columns: ['group'],
      orderBy: '"group" DESC',
    );
    //print(JSON.encode(result));
    expect(result, expectedResult);

    await db.delete(table);

    await db.close();
  });

  test('Functions', () async {
    //await Sqflite.devSetDebugModeOn(true);
    var path = await context.initDeleteDb('exp_functions.db');
    var db = await factory.openDatabase(path);

    var table = 'functions';
    await db.execute("CREATE TABLE '$table' (one TEXT, another TEXT)");
    await db.insert(table, <String, Object?>{'one': '1', 'another': '2'});
    await db.insert(table, <String, Object?>{'one': '1', 'another': '3'});
    await db.insert(table, <String, Object?>{'one': '2', 'another': '2'});

    var result = await db.rawQuery('''
      select one, GROUP_CONCAT(another) as my_col
      from $table
      GROUP BY one''');
    //print('result :$result');
    expect(result, [
      {'one': '1', 'my_col': '2,3'},
      {'one': '2', 'my_col': '2'},
    ]);

    result = await db.rawQuery('''
      select one, GROUP_CONCAT(another)
      from $table
      GROUP BY one''');
    // print('result :$result');
    expect(result, [
      {'one': '1', 'GROUP_CONCAT(another)': '2,3'},
      {'one': '2', 'GROUP_CONCAT(another)': '2'},
    ]);

    // user alias
    result = await db.rawQuery('''
      select t.one, GROUP_CONCAT(t.another)
      from $table as t
      GROUP BY t.one''');
    //print('result :$result');
    expect(result, [
      {'one': '1', 'GROUP_CONCAT(t.another)': '2,3'},
      {'one': '2', 'GROUP_CONCAT(t.another)': '2'},
    ]);

    await db.close();
  });

  test('Alias', () async {
    //await Sqflite.devSetDebugModeOn(true);
    var path = await context.initDeleteDb('exp_alias.db');
    var db = await factory.openDatabase(path);

    try {
      var table = 'alias';
      await db.execute(
        'CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)',
      );
      await db.insert(table, <String, Object?>{'column_1': 1, 'column_2': 2});

      var result = await db.rawQuery('''
      select t.column_1, t.column_1 as 't.column1', column_1 as column_alias_1, column_2
      from $table as t''');
      print('result :$result');
      expect(result, [
        {'t.column1': 1, 'column_1': 1, 'column_alias_1': 1, 'column_2': 2},
      ]);
    } finally {
      await db.close();
    }
  });

  test('Dart2 query', () async {
    // await Sqflite.devSetDebugModeOn(true);
    var path = await context.initDeleteDb('exp_dart2_query.db');
    var db = await factory.openDatabase(path);

    try {
      var table = 'test';
      await db.execute(
        'CREATE TABLE $table (column_1 INTEGER, column_2 INTEGER)',
      );
      await db.insert(table, <String, Object?>{'column_1': 1, 'column_2': 2});

      var result = await db.rawQuery('''
         select column_1, column_2
         from $table as t
      ''');
      print('result: $result');
      // test output types
      print('result.first: ${result.first}');
      var first = result.first;
      print('result.first.keys: ${first.keys}');
      var keys = result.first.keys;
      var values = result.first.values;
      verify(keys.first == 'column_1' || keys.first == 'column_2');
      verify(values.first == 1 || values.first == 2);
      print('result.last.keys: ${result.last.keys}');
      keys = result.last.keys;
      values = result.last.values;
      verify(keys.last == 'column_1' || keys.last == 'column_2');
      verify(values.last == 1 || values.last == 2);
    } finally {
      await db.close();
    }
  });
  /*

    Save code that modify a map from a result - unused
    var rawResult = await rawQuery(builder.sql, builder.arguments);

    // Super slow if we escape a name, please avoid it
    // This won't be called if no keywords were used
    if (builder.hasEscape) {
      for (Map map in rawResult) {
        var keys = new Set<String>();

        for (String key in map.keys) {
          if (isEscapedName(key)) {
            keys.add(key);
          }
        }
        if (keys.isNotEmpty) {
          for (var key in keys) {
            var value = map[key];
            map.remove(key);
            map[unescapeName(key)] = value;
          }
        }
      }
    }
    return rawResult;
    */
  test('Issue#48', () async {
    // Sqflite.devSetDebugModeOn(true);
    // devPrint("issue #48");
    // Try to query on a non-indexed field
    var path = await context.initDeleteDb('exp_issue_48.db');
    var db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
            'CREATE TABLE npa (id INT, title TEXT, identifier TEXT)',
          );
          await db.insert('npa', <String, Object?>{
            'id': 128,
            'title': 'title 1',
            'identifier': '0001',
          });
          await db.insert('npa', <String, Object?>{
            'id': 215,
            'title': 'title 1',
            'identifier': '0008120150514',
          });
        },
      ),
    );
    var resultSet = await db.query(
      'npa',
      columns: ['id', 'title', 'identifier'],
      where: '"identifier" = ?',
      whereArgs: <Object>['0008120150514'],
    );
    // print(resultSet);
    expect(resultSet.length, 1);
    // but the results is always - empty QueryResultSet[].
    // If i'm trying to do the same with the id field and integer value like
    resultSet = await db.query(
      'npa',
      columns: ['id', 'title', 'identifier'],
      where: '"id" = ?',
      whereArgs: <Object>[215],
    );
    // print(resultSet);
    expect(resultSet.length, 1);
    await db.close();
  });

  test('Issue#52', () async {
    // Sqflite.devSetDebugModeOn(true);
    // Try to insert string with quote
    var path = await context.initDeleteDb('exp_issue_52.db');
    var db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE test (id INT, value TEXT)');
          await db.insert('test', <String, Object?>{
            'id': 1,
            'value': 'without quote',
          });
          await db.insert('test', <String, Object?>{
            'id': 2,
            'value': "with ' quote",
          });
        },
      ),
    );
    var resultSet = await db.query(
      'test',
      where: 'value = ?',
      whereArgs: <Object>["with ' quote"],
    );
    expect(resultSet.length, 1);
    expect(resultSet.first['id'], 2);

    resultSet = await db.rawQuery('SELECT * FROM test WHERE value = ?', [
      "with ' quote",
    ]);
    expect(resultSet.length, 1);
    expect(resultSet.first['id'], 2);
    await db.close();
  });

  test('sql dump file', () async {
    // await Sqflite.devSetDebugModeOn(true);

    // try to import an sql dump file (not working)
    var path = await context.initDeleteDb('sql_file.db');
    var db = await factory.openDatabase(path);
    try {
      var table = 'test';
      var sql = '''
CREATE TABLE test (value INTEGER);
INSERT INTO test (value) VALUES (1);
INSERT INTO test (value) VALUES (10);
''';
      await db.execute(sql);

      // that should be the expected result
      // var expectedResult = [
      //   {'value': 1},
      //   {'value': 10}
      // ];
      var result = await db.rawQuery('SELECT * FROM $table');

      // This is empty on Android, [{'value': 1}, {'value': 10}] on Linux
      // However (at least on Android)
      // result is empty, only the first statement is executed
      print(json.encode(result));
      // expect(result, []);
    } finally {
      await db.close();
    }
  });

  test('Issue#107', () async {
    // Sqflite.devSetDebugModeOn(true);
    // Try to insert string with quote
    var path = await context.initDeleteDb('exp_issue_107.db');
    var db = await factory.openDatabase(path);
    try {
      print('0');
      await db.execute(
        'CREATE TABLE `groups` (`id`	INTEGER NOT NULL UNIQUE, `service_id`	INTEGER, `official`	BOOLEAN, `type`	TEXT, `access`	TEXT, `ads`	BOOLEAN, `mute`	BOOLEAN, `read`	INTEGER, `background`	TEXT, `last_message_time`	INTEGER, `last_message_id`	INTEGER, `deleted_to`	INTEGER, `is_admin`	BOOLEAN, `is_owner`	BOOLEAN, `description`	TEXT, `pin`	BOOLEAN, `name`	TEXT, `opposite_id`	INTEGER, `badge`	INTEGER, `member_count`	INTEGER, `identifier`	TEXT, `join_link`	TEXT, `hash`	TEXT, `service_info`	TEXT, `seen`	INTEGER, `pinned_message`	INTEGER, `delivery`	INTEGER, PRIMARY KEY(`id`) ) WITHOUT ROWID;',
      );
      await db.execute('CREATE INDEX groups_id ON groups ( service_id )');
    } finally {
      await db.close();
    }
  }, skip: '5.0 crashes');

  test('Issue#107_alt', () async {
    // Sqflite.devSetDebugModeOn(true);
    // Try to insert string with quote
    var path = await context.initDeleteDb('exp_issue_107_alt.db');
    var db = await factory.openDatabase(path);
    try {
      await db.execute(
        'CREATE TABLE `groups` (`id` INTEGER PRIMARY KEY, `service_id`INTEGER, `official`	BOOLEAN, `type`	TEXT, `access`	TEXT, `ads`	BOOLEAN, `mute`	BOOLEAN, `read`	INTEGER, `background`	TEXT, `last_message_time`	INTEGER, `last_message_id`	INTEGER, `deleted_to`	INTEGER, `is_admin`	BOOLEAN, `is_owner`	BOOLEAN, `description`	TEXT, `pin`	BOOLEAN, `name`	TEXT, `opposite_id`	INTEGER, `badge`	INTEGER, `member_count`	INTEGER, `identifier`	TEXT, `join_link`	TEXT, `hash`	TEXT, `service_info`	TEXT, `seen`	INTEGER, `pinned_message`	INTEGER, `delivery`	INTEGER) WITHOUT ROWID',
      );
      await db.execute('CREATE INDEX `groups_id` ON groups ( `id` ASC )');
    } finally {
      await db.close();
    }
  });

  test('Issue#107_alt', () async {
    // Sqflite.devSetDebugModeOn(true);
    // Try to insert string with quote
    var path = await context.initDeleteDb('exp_issue_107_alt.db');
    var db = await factory.openDatabase(path);
    try {
      await db.execute(
        'CREATE TABLE `groups` (`id` INTEGER PRIMARY KEY, `service_id`INTEGER, `official`	BOOLEAN, `type`	TEXT, `access`	TEXT, `ads`	BOOLEAN, `mute`	BOOLEAN, `read`	INTEGER, `background`	TEXT, `last_message_time`	INTEGER, `last_message_id`	INTEGER, `deleted_to`	INTEGER, `is_admin`	BOOLEAN, `is_owner`	BOOLEAN, `description`	TEXT, `pin`	BOOLEAN, `name`	TEXT, `opposite_id`	INTEGER, `badge`	INTEGER, `member_count`	INTEGER, `identifier`	TEXT, `join_link`	TEXT, `hash`	TEXT, `service_info`	TEXT, `seen`	INTEGER, `pinned_message`	INTEGER, `delivery`	INTEGER) WITHOUT ROWID',
      );
      await db.execute('CREATE INDEX `groups_id` ON groups ( `id` ASC )');
    } finally {
      await db.close();
    }
  });

  test('Issue#155', () async {
    // await factory.setLogLevel(sqfliteLogLevelVerbose);
    // Try to insert string with quote
    var path = await context.initDeleteDb('exp_issue_155.db');
    var db = await factory.openDatabase(path);
    try {
      await db.execute('CREATE TABLE test (value TEXT UNIQUE)');
      var table = 'test';
      var map = <String, Object?>{'value': 'test'};
      await db.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace);
      expect(
        utils.firstIntValue(await db.query(table, columns: ['COUNT(*)'])),
        1,
      );
    } finally {
      await db.close();
    }
  });

  test('Issue#272 indexed_param', () async {
    final db = await factory.openDatabase(':memory:');
    expect(await db.rawQuery('SELECT ?1 + ?2', [3, 4]), [
      {'?1 + ?2': 7},
    ]);
    await db.close();
  });

  test('open_close_transaction', () async {
    // Sqflite.devSetDebugModeOn(true);
    // Try to insert string with quote
    late Database db;
    try {
      var path = await context.initDeleteDb('open_close_transaction.db');
      db = await factory.openDatabase(path);
      db.close();
      try {
        await db.transaction((_) async {});
        fail('should fail');
      } on DatabaseException catch (_) {}
      db = await factory.openDatabase(path);
    } finally {
      await db.close();
    }
  });

  test('read_only', () async {
    late Database db;
    try {
      var path = await context.initDeleteDb('read_only.db');
      db = await factory.openDatabase(path);
      await db.execute('PRAGMA user_version = 4');
      await db.close();
      db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: false),
      );
      await db.execute('PRAGMA user_version = 4');
      await db.close();
      db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      try {
        await db.execute('PRAGMA user_version = 4');
        fail('should fail');
      } on DatabaseException catch (_) {}
      db = await factory.openDatabase(path);
    } finally {
      await db.close();
    }
  });

  test('as', () async {
    var path = await context.initDeleteDb('exp_as.db');
    var db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE test (id INT, value TEXT)');
          await db.insert('test', <String, Object?>{
            'id': 1,
            'value': 'without quote',
          });
          await db.insert('test', <String, Object?>{
            'id': 2,
            'value': "with ' quote",
          });
        },
      ),
    );
    var resultSet = await db.rawQuery('SELECT r.id FROM test r');
    expect(resultSet, [
      {'id': 1},
      {'id': 2},
    ]);
    var dbItem = resultSet.first;
    // ignore: unused_local_variable
    var resourceId = dbItem['id'];
    // print(resourceId);

    {
      resultSet = await db.rawQuery('SELECT r.id AS r_id FROM test r');
      expect(resultSet, [
        {'r_id': 1},
        {'r_id': 2},
      ]);
      // print(resultSet.first.keys);
      dbItem = resultSet.first;
      // ignore: unused_local_variable
      var resourceId = dbItem['r_id'];
      // print(dbItem.keys);
      // print(resourceId);
    }
    await db.close();
  });
  test('wal', () async {
    var path = await context.initDeleteDb('exp_wal.db');
    var db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA journal_mode=WAL');
          await db.rawQuery('PRAGMA journal_mode=WAL');
        },
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE test (id INTEGER)');
          await db.insert('test', <String, Object?>{'id': 1});
        },
      ),
    );
    try {
      var resultSet = await db.rawQuery('SELECT id FROM test');
      expect(resultSet, [
        {'id': 1},
      ]);
    } finally {
      await db.close();
    }
  });

  /// Open multiple database at once
  test('stress test', () async {
    // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);
    var count = 10;
    var opCount = 10;
    var path = List.generate(count, (i) => 'stress_${i + 1}.db');
    for (var i = 0; i < count; i++) {
      path[i] = await context.initDeleteDb(path[i]);
    }
    Future<void> doStuff(String path) async {
      var db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
          },
        ),
      );
      for (var i = 0; i < opCount; i++) {
        await db.insert('Test', <String, Object?>{'id': i});
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await db.query('Test');
      }
      await db.close();
    }

    var futures = <Future>[];
    for (var i = 0; i < count; i++) {
      futures.add(doStuff(path[i]));
    }
    await Future.wait(futures);
  });
}
