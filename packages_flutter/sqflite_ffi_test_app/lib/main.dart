import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_example_common/main.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';
import 'package:sqflite_ffi_test_app/databases_path.dart';
import 'package:sqflite_ffi_test_app/page/sqflite_ffi_test_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The sqflite_ffi plugin has registered `sqfliteDatabaseFactoryFfi` as the
  // default database factory so the example app tests run on ffi too.
  if (!kIsWeb) {
    await databaseFactory.setDatabasesPath(await appDatabasesPath());
  }
  extraRoutes = <String, WidgetBuilder>{
    '/test/sqflite_ffi': (_) => SqfliteFfiTestPage(),
  };
  mainExampleApp();
}
