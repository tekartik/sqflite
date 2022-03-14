import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_example/main.dart' as example;
import 'package:sqflite_example/utils.dart';

Future<void> main() async {
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
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // Use sqflite databases path provider (ffi implementation is lame))
  if (isSqfliteCompatible) {
    await databaseFactory.setDatabasesPath(await original!.getDatabasesPath());
  }
  example.main();
}
