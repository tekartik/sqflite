import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// delete the db, create the folder and returnes its path
Future<String> initDeleteDb(String dbName) async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, dbName);
  if (await databaseExists(path)) {
    await deleteDatabase(path);
  }  
  return path;
}