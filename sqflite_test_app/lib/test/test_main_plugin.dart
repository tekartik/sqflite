import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart';
import 'package:sqflite_common_test/sqflite_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  var testContext = SqfliteLocalTestContext(
    databaseFactory: databaseFactorySqflitePlugin,
  );
  sqfliteTestGroup(testContext);
}
