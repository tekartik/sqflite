import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

main() {
  group("database", () {
    test("open", () async {
      // Can't do unit test plugin
      /*
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      print(documentsDirectory);

      //String path = join(documentsDirectory.path, "test1.db");
      String path = "test.db";
      Database database = await openDatabase(path);

      print(database);

      await database.close();
      */
    });
  });
}
