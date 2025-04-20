import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_test/all_test.dart';
import 'package:sqflite_common_test/sqflite_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  var testContext = SqfliteLocalTestContext(
    databaseFactory: kIsWeb ? databaseFactoryFfiWeb : databaseFactoryFfi,
  );
  sqfliteTestGroup(testContext);
}
