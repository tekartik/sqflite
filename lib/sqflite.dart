import 'dart:async';

import 'package:flutter/services.dart';

final String _paramPath = "path";
final String _paramId = "id";

final String _methodCloseDatabase = "closeDatabase";

class Sqflite {
  static const MethodChannel _channel =
      const MethodChannel('com.tekartik.sqflite');

  static Future<String> get platformVersion =>
      _channel.invokeMethod('getPlatformVersion');
}


class Database {
  String _path;
  int _id;
  Database._(this._path, this._id);

  @override
  String toString() {
    return "$_id $_path";

  }

  Future close() async {
    await Sqflite._channel.invokeMethod(
    _methodCloseDatabase, <String, dynamic>{
    _paramId: _id
    });
  }
}

class DatabaseException implements Exception {
  String msg;
  DatabaseException(this.msg);
}

Future<Database> openDatabase(String path, {int version}) async {
    int databaseId = await Sqflite._channel.invokeMethod(
        "openDatabase", <String, dynamic>{
      "path": path,
      "version": version ?? 1
    });

  return new Database._(path, databaseId);
}