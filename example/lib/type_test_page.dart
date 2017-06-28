import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/test_page.dart';

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

  TypeTestPage() : super("Type tests") {
    test("int", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("int.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(
            "CREATE TABLE Test (_id INTEGER PRIMARY KEY, value INTEGER)");
      });
      int id = await insertValue(-1);
      assert(await getValue(id) == -1);
      // more than 32 bits
      id = await insertValue(pow(2, 33));
      assert(await getValue(id) == pow(2, 33));
      id = await insertValue(pow(2, 63));
      assert(await getValue(id) == pow(2, 63));

      // more then 64 bits
      id = await insertValue(pow(2, 65));
      assert(await getValue(id) == pow(2, 65));

      // more then 128 bits
      id = await insertValue(pow(2, 129));
      assert(await getValue(id) == pow(2, 129));

      await data.db.close();
    });

    test("real", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("int.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value REAL)");
      });
      int id = await insertValue(-1.1);
      assert(await getValue(id) == -1.1);
      // big float
      id = await insertValue(1 / 3);
      assert(await getValue(id) == 1 / 3);
      id = await insertValue(pow(2, 63) + .1);
      assert(await getValue(id) == pow(2, 63) + 0.1);

      // integer?
      id = await insertValue(pow(2, 129));
      assert(await getValue(id) == pow(2, 129));
      await data.db.close();
    });

    test("text", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("int.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value TEXT)");
      });
      int id = await insertValue("simple text");
      assert(await getValue(id) == "simple text");
      // null
      id = await insertValue(null);
      assert(await getValue(id) == null);

      // utf-8
      id = await insertValue("àöé");
      assert(await getValue(id) == "àöé");

      await data.db.close();
    });

    test("blob", () async {
      //await Sqflite.devSetDebugModeOn(true);
      String path = await initDeleteDb("int.db");
      data.db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db
            .execute("CREATE TABLE Test (_id INTEGER PRIMARY KEY, value BLOB)");
      });
      try {
        int id = await insertValue("simple text");
        assert(await getValue(id) == "simple text");

        var eq = const DeepCollectionEquality();

        ByteData byteData = new ByteData(1);
        byteData.setInt8(0, 1);
        id = await insertValue(byteData.buffer.asUint8List());
        print(await getValue(id));
        assert(eq.equals(await getValue(id), [1]));

        id = await insertValue([]);
        print(await getValue(id));
        assert(eq.equals(await getValue(id), []));

        id = await insertValue([1, 2, 3, 4]);
        print(await getValue(id));
        assert(eq.equals(await getValue(id), [1, 2, 3, 4]));
      } finally {
        await data.db.close();
      }
    });
  }
}
