import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_example/src/common_import.dart';
import 'package:sqflite_test_app/setup_flutter.dart';

class SqfliteDriverTestContext extends SqfliteLocalTestContext {
  SqfliteDriverTestContext() : super(databaseFactory: databaseFactory);
}

var testContext = SqfliteDriverTestContext();
void main() {
  final completer = Completer<String>();
  enableFlutterDriverExtension(handler: (_) => completer.future);

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    sqfliteFfiInitAsMockMethodCallHandler();
  }

  tearDownAll(() => completer.complete(''));

  group('driver', () {
    all.run(testContext);
  });
}
