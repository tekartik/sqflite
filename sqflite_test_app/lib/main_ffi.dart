import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_example/database/database.dart';
import 'package:sqflite_example/main.dart';
import 'package:sqflite_example/utils.dart';
import 'package:sqflite_test_app/database/database.dart';

Future<void> main() async {
  await mainFfi();
}

/// Run using ffi (io or web)
Future<void> mainFfi() async {
  await initFfi();
  await runFfi();
}

/// Init Ffi for io or web
Future<void> initFfi() async {
  // getDatabasesPath implementation is lame, use the default one
  // but we could also use path_provider
  var isSqfliteCompatible =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  DatabaseFactory? original;
  // Save original for iOS & Android
  if (isSqfliteCompatible) {
    original = databaseFactory;
  }

  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    // Platform handler for the example app
    platformHandler = platformHandlerWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Use sqflite databases path provider (ffi implementation is lame))
  if (isSqfliteCompatible) {
    await databaseFactory.setDatabasesPath(await original!.getDatabasesPath());
  }
}

/// Run example app.
Future<void> runFfi() async {
  mainExampleApp();
}
