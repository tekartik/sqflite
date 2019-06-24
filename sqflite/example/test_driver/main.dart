import 'dart:async';

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_example/src/common_import.dart';

import 'sqflite_impl_test.dart' as sqflite_impl_test;
import 'sqflite_test.dart' as sqflite_test;

void main() {
  final Completer<String> completer = Completer<String>();
  enableFlutterDriverExtension(handler: (_) => completer.future);
  tearDownAll(() => completer.complete(null));

  group('driver', () {
    sqflite_test.main();
    sqflite_impl_test.main();
  });
}
