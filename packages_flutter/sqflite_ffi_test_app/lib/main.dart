import 'package:flutter/material.dart';
import 'package:sqflite_example_common/main.dart';
import 'package:sqflite_ffi_test_app/page/sqflite_ffi_test_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  extraRoutes = <String, WidgetBuilder>{
    '/test/sqflite_ffi': (_) => SqfliteFfiTestPage(),
  };
  // The sqflite_ffi plugin has registered `sqfliteDatabaseFactoryFfi` as the
  // default database factory so the example app tests run on ffi too.
  mainExampleApp();
}
