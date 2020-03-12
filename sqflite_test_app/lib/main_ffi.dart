import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_example/main.dart' as example;
import 'package:sqflite_test_app/setup_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  sqfliteFfiInitAsMockMethodCallHandler();
  example.main();
}
