import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'test_page.dart';

class _Data {
  Database db;
}

class TypeTestPage extends TestPage {
  final _Data data = new _Data();

  // Get the value field from a given
  Future<dynamic> getValue(int id) async {
    return ((await data.db.query("Test", where: "_id = $id")).first)["value"];
  }

  // insert the value field and return the id
  Future<int> insertValue(dynamic value) async {
    return await data.db.insert("Test", {"value": value});
  }

  // insert the value field and return the id
  Future<int> updateValue(int id, dynamic value) async {
    return await data.db.update("Test", {"value": value}, where: "_id = $id");
  }

  TypeTestPage() : super("Type tests") {
    test("int", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("type_int.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(
            "CREATE TABLE Test (_id INTEGER PRIMARY KEY, value INTEGER)");
      });
      int id = await insertValue(-1);
      expect(await getValue(id), -1);

      // less than 32 bits
      id = await insertValue(pow(2, 31));
      expect(await getValue(id), pow(2, 31));

      // more than 32 bits
      id = await insertValue(pow(2, 33));
      //devPrint("2^33: ${await getValue(id)}");
      expect(await getValue(id), pow(2, 33));

      id = await insertValue(pow(2, 62));
      //devPrint("2^62: ${pow(2, 62)} ${await getValue(id)}");
      expect(await getValue(id), pow(2, 62),
          reason: "2^62: ${pow(2, 62)} ${await getValue(id)}");

      int value = pow(2, 63) - 1;
      id = await insertValue(value);
      //devPrint("${value} ${await getValue(id)}");
      expect(await getValue(id), value,
          reason: "${value} ${await getValue(id)}");

      value = -(pow(2, 63)).round();
      id = await insertValue(value);
      //devPrint("${value} ${await getValue(id)}");
      expect(await getValue(id), value,
          reason: "${value} ${await getValue(id)}");
      /*
      id = await insertValue(pow(2, 63));
      devPrint("2^63: ${pow(2, 63)} ${await getValue(id)}");
      assert(await getValue(id) == pow(2, 63), "2^63: ${pow(2, 63)} ${await getValue(id)}");

      // more then 64 bits
      id = await insertValue(pow(2, 65));
      assert(await getValue(id) == pow(2, 65));

      // more then 128 bits
      id = await insertValue(pow(2, 129));
      assert(await getValue(id) == pow(2, 129));
      */
      await data.db.close();
    });

    test("real", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("type_real.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value REAL)");
      });
      int id = await insertValue(-1.1);
      expect(await getValue(id), -1.1);
      // big float
      id = await insertValue(1 / 3);
      expect(await getValue(id), 1 / 3);
      id = await insertValue(pow(2, 63) + .1);
      expect(await getValue(id), pow(2, 63) + 0.1);

      // integer?
      id = await insertValue(pow(2, 62));
      expect(await getValue(id), pow(2, 62));
      await data.db.close();
    });

    test("text", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("type_text.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value TEXT)");
      });
      int id = await insertValue("simple text");
      expect(await getValue(id), "simple text");
      // null
      id = await insertValue(null);
      expect(await getValue(id), null);

      // utf-8
      id = await insertValue("àöé");
      expect(await getValue(id), "àöé");

      await data.db.close();
    });

    test("blob", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("type_blob.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value BLOB)");
      });
      try {
        // insert text in blob
        int id = await insertValue("simple text");
        expect(await getValue(id), "simple text");

        // UInt8List - default
        ByteData byteData = new ByteData(1);
        byteData.setInt8(0, 1);
        id = await insertValue(byteData.buffer.asUint8List());
        //print(await getValue(id));
        expect(await getValue(id), [1]);

        // empty array not supported
        //id = await insertValue([]);
        //print(await getValue(id));
        //assert(eq.equals(await getValue(id), []));

        id = await insertValue([1, 2, 3, 4]);
        //print(await getValue(id));
        expect(await getValue(id), [1, 2, 3, 4],
            reason: "${await getValue(id)}");
      } finally {
        await data.db.close();
      }
    });

    test("null", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("type_null.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value TEXT)");
      });
      int id = await insertValue(null);
      expect(await getValue(id), null);

      // Make a string
      expect(await updateValue(id, "dummy"), 1);
      expect(await getValue(id), "dummy");

      expect(await updateValue(id, null), 1);
      expect(await getValue(id), null);
    });

    test("date_time", () async {
      // await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("type_date_time.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value TEXT)");
      });
      bool failed = false;
      try {
        await insertValue(new DateTime.fromMillisecondsSinceEpoch(1234567890));
      } on ArgumentError catch (_) {
        failed = true;
      }
      expect(failed, true);
    });
  }
}
