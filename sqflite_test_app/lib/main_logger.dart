import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_example_common/main.dart';
import 'package:sqflite_test_app/main_ffi.dart';

/// Use regular sqflite, should work on Android, iOS and MacOS
void main() {
  if (kIsWeb || Platform.isWindows || Platform.isLinux) {
    initFfi();
  }
  // Wrap with logger
  // ignore: experimental_member_use
  databaseFactory = SqfliteDatabaseFactoryLogger(databaseFactory);
  mainExampleApp();
}
