import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlite3/wasm.dart';

const _dbName = 'sqflite_databases'; 

/// delete the db, create the folder and returnes its path
Future<String> initDeleteDb(String dbName) async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, dbName);
  if (await databaseExists(path)) {
    await deleteDatabase(path);
  }  
  return path;
}

/// Write the db file directly to the file system
Future<void> writeFileAsBytes(String path, List<int> bytes, {bool flush = false}) async {
  final fs = await IndexedDbFileSystem.open(dbName: _dbName); 
  if (fs.exists(path)) fs.deleteFile(path);
  fs.write(path, Uint8List.fromList(bytes), 0);
  if (flush) await fs.flush();
}