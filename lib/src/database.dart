import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/sqflite_impl.dart';

class SqfliteDatabase extends Database {
  String get path => _path;
  String _path;

  // Its internal id
  int id;

  SqfliteDatabase(this._path, this.id);

  Map<String, dynamic> get baseDatabaseMethodArguments {
    var map = <String, dynamic>{
      paramId: id,
    };
    return map;
  }

  @override
  Batch batch() {
    return new SqfliteBatch(this);
  }

  @override
  Future devInvokeMethod(String method, [arguments]) {
    return invokeMethod(
        method,
        (arguments ?? <String, dynamic>{})
          ..addAll(baseDatabaseMethodArguments));
  }

  @override
  Future devInvokeSqlMethod(String method, String sql, [List arguments]) {
    return devInvokeMethod(
        method, <String, dynamic>{paramSql: sql, paramSqlArguments: arguments});
  }
}
