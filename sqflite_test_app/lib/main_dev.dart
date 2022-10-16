import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/main.dart';
import 'package:sqflite_test_app/main_ffi.dart';

// Special entry point for dev where logs are activated
Future<void> main() async {
  await mainDev();
}

/// Special entry point for dev where logs are activated
Future<void> mainDev({bool? noWorker}) async {
  // sqliteFfiWebDebugWebWorker = devWarning(true);

  /// Use ffi on the web
  if (kIsWeb || Platform.isWindows || Platform.isLinux) {
    await initFfi(noWorker: noWorker);
  } else {
    // Use regular sqflite
  }

  WidgetsFlutterBinding.ensureInitialized();
  // Force logs in dev mode
  // ignore: deprecated_member_use
  await databaseFactory.debugSetLogLevel(sqfliteLogLevelVerbose);
  mainExampleApp();
}
