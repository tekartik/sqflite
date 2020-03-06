import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/mixin/factory.dart';

Future<void> main() async {
  final factory = buildDatabaseFactory(
      invokeMethod: (String method, [dynamic arguments]) async {
    dynamic result;
    print('$method: $arguments');
    return result;
  });
  final db = await factory.openDatabase(inMemoryDatabasePath);
  await db?.getVersion();
}
