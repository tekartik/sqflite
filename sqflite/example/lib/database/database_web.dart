import 'dart:async';
import 'dart:convert';
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
  fs.createFile(path);
  fs.write(path, Uint8List.fromList(bytes), 0);
  if (flush) await fs.flush();
}

/// Read a file as bytes
Future<Uint8List> readFileAsBytes(String path) async {
  final fs = await IndexedDbFileSystem.open(dbName: _dbName); 
  var size = fs.sizeOfFile(path);
  var target = Uint8List(size);
  fs.read(path, target, 0);
  return target;
}

/// Write a file as a string
Future<void> writeFileAsString(String path, String text, {bool flush = false}) async {
  var bytes = const Utf8Encoder().convert(text);
  await writeFileAsBytes(path, bytes, flush: flush);
}

/// Read a file as a string
Future<String> readFileAsString(String path) async {
  var bytes = await readFileAsBytes(path);
  var text = const Utf8Decoder().convert(bytes);
  return text;
}

/// Check if a path exists.
Future<bool> pathExists(String path) async {
  final fs = await IndexedDbFileSystem.open(dbName: _dbName); 
  return fs.exists(path);
}

/// Create a directory, on the web this is a noop since files are referred to directly by path
Future<void> createDirectory(String path) async {
  
}

/// Delete a directory, on the web this is a noop since files are referred to directly by path
Future<void> deleteDirectory(String path) async {
  
}

/// Check if a directory exists, all directories potentially exist on the web since files are referred to directly by path
Future<bool> existsDirectory(String path) async {
  return true;
}