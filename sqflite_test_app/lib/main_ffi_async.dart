import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:sqflite_example_common/main.dart';

Future<void> main() async {
  await mainFfiAsync();
}

/// Run using ffi (io or web)
Future<void> mainFfiAsync() async {
  await initFfiAsync();
  await runFfiAsync();
}

/// Init Ffi for io or web
///
/// if [noWorker] is true, no isolate is used on io and no web worker is used on the web.
Future<void> initFfiAsync() async {
  // getDatabasesPath implementation is lame, use the default one
  // but we could also use path_provider
  var isSqfliteCompatible =
      (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  //DatabaseFactory? original;
  // Save original for iOS & Android

  sqfliteFfiInit();
  databaseFactoryOrNull = databaseFactoryFfiAsync;

  WidgetsFlutterBinding.ensureInitialized();
  // Use sqflite databases path provider (ffi implementation is lame))
  if (isSqfliteCompatible) {
    await databaseFactory.setDatabasesPath(
        await databaseFactorySqflitePlugin.getDatabasesPath());
  }
}

/// Run example app.
Future<void> runFfiAsync() async {
  mainExampleApp();
}
