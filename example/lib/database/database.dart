import 'dart:async';

import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// return the path
Future<String> initDeleteDb(String dbName) async {
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  print(documentsDirectory);

  String path = join(documentsDirectory.path, dbName);

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
