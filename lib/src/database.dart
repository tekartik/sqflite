import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/constant.dart';

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
}
