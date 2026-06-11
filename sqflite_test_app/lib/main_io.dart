import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:sqflite_example_common/main.dart';
import 'package:sqflite_test_app/page/sqflite_ffi_test_page.dart';

import 'main_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  extraRoutes = <String, WidgetBuilder>{
    '/test/sqflite_ffi': (_) => SqfliteFfiTestPage(),
  };
  if (Platform.isWindows || Platform.isLinux) {
    mainFfi();
    return;
  } else {
    mainExampleApp();
  }
}
