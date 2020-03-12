import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_example/main.dart' as example;
import 'package:sqflite_test_app/setup_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Only need windows
  if (Platform.isWindows) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  sqfliteFfiInit();
  sqfliteFfiInitAsMockMethodCallHandler();
  example.main();
}
