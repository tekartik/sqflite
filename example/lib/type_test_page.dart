import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/test_page.dart';

class TypeTestPage extends TestPage {
  TypeTestPage() : super("Type tests") {
    test("int", () async {
      //await Sqflite.setDebugModeOn(true);
      String path = await initDeleteDb("int.db");
      Database db = await openDatabase(path);
      await db.close();
    });
  }
}
