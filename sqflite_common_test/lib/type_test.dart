import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

class _Data {
  late Database db;
}

final _Data _data = _Data();

// Get the value field from a given
Future<dynamic> _getValue(int id) async {
  return ((await _data.db.query('Test', where: '_id = $id')).first)['value'];
}

// insert the value field and return the id
Future<int> _insertValue(dynamic value) async {
  return await _data.db.insert('Test', <String, Object?>{'value': value});
}

// insert the value field and return the id
Future<int> _updateValue(int id, dynamic value) async {
  return await _data.db
      .update('Test', <String, Object?>{'value': value}, where: '_id = $id');
}

/// Run type tests.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('type', () {
    test('int', () async {
      //await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_int.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute(
                    'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value INTEGER)');
              }));

      // text
      var id = await _insertValue('test');
      expect(await _getValue(id), 'test');

      // null
      id = await _insertValue(null);
      expect(await _getValue(id), null);

      id = await _insertValue(1);
      expect(await _getValue(id), 1);

      id = await _insertValue(-1);
      expect(await _getValue(id), -1);

      // less than 32 bits
      id = await _insertValue(pow(2, 31));
      expect(await _getValue(id), pow(2, 31));

      // more than 32 bits
      id = await _insertValue(pow(2, 33));
      //devPrint('2^33: ${await getValue(id)}');
      expect(await _getValue(id), pow(2, 33));

      id = await _insertValue(pow(2, 62));
      //devPrint('2^62: ${pow(2, 62)} ${await getValue(id)}');
      expect(await _getValue(id), pow(2, 62),
          reason: '2^62: ${pow(2, 62)} ${await _getValue(id)}');

      var value = pow(2, 63).round() - 1;
      id = await _insertValue(value);
      //devPrint('${value} ${await getValue(id)}');
      expect(await _getValue(id), value,
          reason: '$value ${await _getValue(id)}');

      value = -(pow(2, 63)).round();
      id = await _insertValue(value);
      //devPrint('${value} ${await getValue(id)}');
      expect(await _getValue(id), value,
          reason: '$value ${await _getValue(id)}');
      /*
      id = await insertValue(pow(2, 63));
      devPrint('2^63: ${pow(2, 63)} ${await getValue(id)}');
      assert(await getValue(id) == pow(2, 63), '2^63: ${pow(2, 63)} ${await getValue(id)}');

      // more then 64 bits
      id = await insertValue(pow(2, 65));
      assert(await getValue(id) == pow(2, 65));

      // more then 128 bits
      id = await insertValue(pow(2, 129));
      assert(await getValue(id) == pow(2, 129));
      */
      await _data.db.close();
    });

    test('real', () async {
      //await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_real.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute(
                    'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value REAL)');
              }));
      // text
      var id = await _insertValue('test');
      expect(await _getValue(id), 'test');

      // null
      id = await _insertValue(null);
      expect(await _getValue(id), null);

      id = await _insertValue(-1);
      expect(await _getValue(id), -1);
      id = await _insertValue(-1.1);
      expect(await _getValue(id), -1.1);
      // big float
      id = await _insertValue(1 / 3);
      expect(await _getValue(id), 1 / 3);
      id = await _insertValue(pow(2, 63) + .1);
      try {
        expect(await _getValue(id), pow(2, 63) + 0.1);
      } on TestFailure catch (_) {
        // we might still get the positive value
        // This happens when use the server app
        expect(await _getValue(id), -(pow(2, 63) + 0.1));
      }

      // integer?
      id = await _insertValue(pow(2, 62));
      expect(await _getValue(id), pow(2, 62));
      await _data.db.close();
    });

    test('text', () async {
      //await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_text.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute(
                    'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value TEXT)');
              }));
      var id = await _insertValue('simple text');
      expect(await _getValue(id), 'simple text');
      // null
      id = await _insertValue(null);
      expect(await _getValue(id), null);

      // utf-8
      id = await _insertValue('àöé');
      expect(await _getValue(id), 'àöé');

      await _data.db.close();
    });

    test('blob', () async {
      // await context.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_blob.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute(
                    'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value BLOB)');
              }));
      int id;
      dynamic value;
      try {
        // insert text in blob
        id = await _insertValue('simple text');
        expect(await _getValue(id), 'simple text');

        // null
        id = await _insertValue(null);
        expect(await _getValue(id), null);

        // UInt8List - default
        var byteData = ByteData(1);
        byteData.setInt8(0, 1);
        var blob = byteData.buffer.asUint8List();
        id = await _insertValue(blob);
        //print(await getValue(id));
        var result = (await _getValue(id)) as List;
        // print(result.runtimeType);
        // this is not true when sqflite server
        expect(result, const TypeMatcher<Uint8List>());

        // expect(result is List, true);
        expect(result.length, 1);
        expect(result, [1]);

        // Insert blob manually

        id = await _data.db
            .rawInsert("INSERT INTO Test(value) VALUES ( X'deadbeef' )");
        var blobRead = await _getValue(id);
        expect(blobRead, const TypeMatcher<Uint8List>());
        // print('${blobRead.length}');
        expect(await _getValue(id), [0xDE, 0xAD, 0xBE, 0xEF],
            reason: '${await _getValue(id)}');
        // empty array not supported
        //id = await insertValue([]);
        //print(await getValue(id));
        //assert(eq.equals(await getValue(id), []));

        final blob1234 = Uint8List.fromList([1, 2, 3, 4]);
        id = await _insertValue(blob1234);
        // print(await _getValue(id));
        // print('${(await _getValue(id)).length}');
        expect(await _getValue(id), blob1234, reason: '${await _getValue(id)}');

        if (!context.strict) {
          final blob1234Int = [1, 2, 3, 4];
          id = await _insertValue(blob1234Int);
          // print(await _getValue(id));
          // print('${(await _getValue(id)).length}');
          expect(await _getValue(id), blob1234Int,
              reason: '${await _getValue(id)}');
        }

        // test hex feature on sqlite
        var hexResult = await _data.db
            .rawQuery('SELECT hex(value) FROM Test WHERE _id = ?', [id]);
        expect(hexResult[0].values.first, '01020304');

        // try blob lookup - does work but not on Android
        var rows = await _data.db
            .rawQuery('SELECT * FROM Test WHERE value = ?', [blob1234]);
        expect(rows.length, 1);

        // try blob lookup using hex
        rows = await _data.db.rawQuery(
            'SELECT * FROM Test WHERE hex(value) = ?', [utils.hex(blob1234)]);
        expect(rows.length, context.strict ? 1 : 2);
        expect(rows.last['_id'], id);

        // Insert empty blob
        final blobEmpty = Uint8List(0);

        id = await _data.db.rawInsert("INSERT INTO Test(value) VALUES ( X'' )");
        blobRead = await _getValue(id);
        expect(blobRead, const TypeMatcher<Uint8List>());
        // print('${blobRead.length}');
        expect(blobRead, blobEmpty, reason: '$blobRead');

        id = await _insertValue(blobEmpty);
        value = await _getValue(id);
        expect(value, const TypeMatcher<Uint8List>());
        expect(value, isEmpty);
        // print(await _getValue(id));
        // print('${(await _getValue(id)).length}');
        expect(value, blobEmpty, reason: '${await _getValue(id)}');
      } finally {
        await _data.db.close();
      }
    });

    test('null', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_null.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute(
                    'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value TEXT)');
              }));
      try {
        var id = await _insertValue(null);
        expect(await _getValue(id), null);

        // Make a string
        expect(await _updateValue(id, 'dummy'), 1);
        expect(await _getValue(id), 'dummy');

        expect(await _updateValue(id, null), 1);
        expect(await _getValue(id), null);
      } finally {
        await _data.db.close();
      }
    });

    test('date_time', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_date_time.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute(
                    'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value TEXT)');
              }));
      try {
        var failed = false;
        try {
          await _insertValue(DateTime.fromMillisecondsSinceEpoch(1234567890));
        } catch (_) {
          // } on ArgumentError catch (_) { not throwing the same exception
          failed = true;
        }
        expect(failed, true);
      } finally {
        await _data.db.close();
      }
    });

    test('sql timestamp', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_sql_timestamp.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute('CREATE TABLE Test (_id INTEGER PRIMARY KEY,'
                    ' value TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL)');
              }));
      try {
        var id = await _data.db.insert('Test', <String, Object?>{'_id': 1});
        expect(DateTime.parse(await _getValue(id) as String), isNotNull);
      } finally {
        await _data.db.close();
      }

      _data.db = await factory.openDatabase(inMemoryDatabasePath);
      try {
        var dateTimeText = (await _data.db
                .rawQuery("SELECT datetime(1092941466, 'unixepoch')"))
            .first
            .values
            .first as String;
        expect(dateTimeText, '2004-08-19 18:51:06');
        expect(DateTime.parse(dateTimeText).toIso8601String(),
            '2004-08-19T18:51:06.000');
      } finally {
        await _data.db.close();
      }
    });

    test('sql numeric', () async {
      // await Sqflite.devSetDebugModeOn(true);
      var path = await context.initDeleteDb('type_sql_numeric.db');
      _data.db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (Database db, int version) async {
                await db.execute('CREATE TABLE Test (_id INTEGER PRIMARY KEY,'
                    ' value NUMERIC)');
              }));
      try {
        var id = await _insertValue(1);
        expect(await _getValue(id), 1);
        var value = await _getValue(id);
        expect(value, const TypeMatcher<int>());

        id = await _insertValue(-1);
        expect(await _getValue(id), -1);
        id = await _insertValue(-1.1);
        value = await _getValue(id);
        expect(value, const TypeMatcher<double>());
        expect(value, -1.1);

        // big float
        id = await _insertValue(1 / 3);
        expect(await _getValue(id), 1 / 3);
        id = await _insertValue(pow(2, 63) + .1);
        try {
          expect(await _getValue(id), pow(2, 63) + 0.1);
        } on TestFailure catch (_) {
          // we might still get the positive value
          // This happens when use the server app
          expect(await _getValue(id), -(pow(2, 63) + 0.1));
        }

        // integer?
        id = await _insertValue(pow(2, 62));
        expect(await _getValue(id), pow(2, 62));

        // text
        id = await _insertValue('test');
        expect(await _getValue(id), 'test');

        // int text
        id = await _insertValue('18');
        expect(await _getValue(id), 18);

        // double text
        id = await _insertValue('18.1');
        expect(await _getValue(id), 18.1);

        // empty text
        id = await _insertValue('');
        expect(await _getValue(id), '');

        // null
        id = await _insertValue(null);
        expect(await _getValue(id), null);
      } finally {
        await _data.db.close();
      }
    });
    test('bool', () async {
      try {
        //await Sqflite.devSetDebugModeOn(true);
        var path = await context.initDeleteDb('type_bool.db');
        _data.db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(
                version: 1,
                onCreate: (Database db, int version) async {
                  await db.execute(
                      'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value BOOL)');
                }));

        // text
        var id = await _insertValue('test');
        expect(await _getValue(id), 'test');
      } finally {
        await _data.db.close();
      }
    });
  });
}
