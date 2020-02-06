import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/mixin/factory.dart';

Future<void> main() async {
  final DatabaseFactory factory = buildDatabaseFactory(
      invokeMethod: (String method, [dynamic arguments]) async {
    dynamic result;
    print('$method: $arguments');
    return result;
  });
  final Database db = await factory.openDatabase(inMemoryDatabasePath);
  print('db version: ${await db.getVersion()}');
  print(Platform.environment);
}
