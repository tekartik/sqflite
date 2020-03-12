import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/mixin/factory.dart';

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
