import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_example/main.dart' as example;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Only need windows
  if (Platform.isWindows) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  databaseFactory = databaseFactoryFfi;
  sqfliteFfiInit();
  example.main();
}
