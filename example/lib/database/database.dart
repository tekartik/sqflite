import 'dart:async';

import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// return the path
Future<String> initDeleteDb(String dbName) async {
  var databasePath = await getDatabasesPath();
  // print(databasePath);
  String path = join(databasePath, dbName);

  // make sure the folder exists
  if (await new Directory(dirname(path)).exists()) {
    await deleteDatabase(path);
  } else {
    try {
      await new Directory(dirname(path)).create(recursive: true);
    } catch (e) {
      print(e);
    }
  }
  return path;
}
