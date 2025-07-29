import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_example_common/database/database.dart';
import 'package:sqflite_example_common/main.dart';
import 'package:sqflite_test_app/database/database.dart';

Future<void> main() async {
  await mainFfi();
}

/// Run using ffi (io or web)
Future<void> mainFfi({bool? noWorker, bool? webBasicWorker}) async {
  await initFfi(noWorker: noWorker, webBasicWorker: webBasicWorker);
  await runFfi();
}

/// Init Ffi for io or web
///
/// if [noWorker] is true, no isolate is used on io and no web worker is used on the web.
Future<void> initFfi({bool? noWorker, bool? webBasicWorker}) async {
  noWorker ??= false;
  // getDatabasesPath implementation is lame, use the default one
  // but we could also use path_provider
  var isSqfliteCompatible =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  //DatabaseFactory? original;
  // Save original for iOS & Android

  if (kIsWeb) {
    if (noWorker) {
      databaseFactoryOrNull = databaseFactoryFfiWebNoWebWorker;
    } else {
      webBasicWorker ??= false;
      if (webBasicWorker) {
        databaseFactoryOrNull = databaseFactoryFfiWebBasicWebWorker;
      } else {
        // default (not supported on io
        databaseFactoryOrNull = databaseFactoryFfiWeb;
      }
    }
    // Platform handler for the example app
    platformHandler = platformHandlerWeb;
  } else {
    sqfliteFfiInit();
    if (noWorker) {
      databaseFactoryOrNull = databaseFactoryFfiNoIsolate;
    } else {
      databaseFactoryOrNull = databaseFactoryFfi;
    }
  }
  WidgetsFlutterBinding.ensureInitialized();
  // Use sqflite databases path provider (ffi implementation is lame))
  if (isSqfliteCompatible) {
    await databaseFactory.setDatabasesPath(
      await databaseFactorySqflitePlugin.getDatabasesPath(),
    );
  }
}

/// Run example app.
Future<void> runFfi() async {
  mainExampleApp();
}
