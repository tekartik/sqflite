import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/database.dart';
import 'package:synchronized/synchronized.dart';

SqfliteDatabaseFactory _databaseFactory;

DatabaseFactory get databaseFactory => sqlfliteDatabaseFactory;

SqfliteDatabaseFactory get sqlfliteDatabaseFactory =>
    _databaseFactory ??= new SqfliteDatabaseFactory();

Future<Database> openReadOnlyDatabase(String path) async {
  var options = new SqfliteOpenDatabaseOptions(path: path)..readOnly = true;
  return sqlfliteDatabaseFactory.openDatabase(options);
}

abstract class DatabaseFactory {
  Future<Database> openDatabase(OpenDatabaseOptions options);
}

class SqfliteOpenDatabaseOptions implements OpenDatabaseOptions {
  SqfliteOpenDatabaseOptions({
    this.path,
    this.version,
    this.onConfigure,
    this.onCreate,
    this.onUpgrade,
    this.onDowngrade,
    this.onOpen,
    this.readOnly,
    this.singleInstance,
  });
  @override
  String path;
  @override
  int version;
  @override
  OnDatabaseConfigureFn onConfigure;
  @override
  OnDatabaseCreateFn onCreate;
  @override
  OnDatabaseVersionChangeFn onUpgrade;
  @override
  OnDatabaseVersionChangeFn onDowngrade;
  @override
  OnDatabaseOpenFn onOpen;
  @override
  bool readOnly;
  @override
  bool singleInstance;
}

class SqfliteDatabaseFactory implements DatabaseFactory {
  // for single instances only
  Map<String, SqfliteDatabaseOpenHelper> databaseOpenHelpers = {};
  SqfliteDatabaseOpenHelper nullDatabaseOpenHelper;

  // open lock mechanism
  var lock = new Lock();

  SqfliteDatabase newDatabase(
          SqfliteDatabaseOpenHelper openHelper, String path) =>
      new SqfliteDatabase(openHelper, path);

  // internal close
  void doCloseDatabase(SqfliteDatabase database) {
    if (database?.options?.singleInstance == true) {
      if (database.path == null) {
        nullDatabaseOpenHelper = null;
      } else {
        databaseOpenHelpers.remove(database.path);
      }
    }
  }

  @override
  Future<Database> openDatabase(OpenDatabaseOptions options) async {
    options ??= new SqfliteOpenDatabaseOptions();

    if (options?.singleInstance == true) {
      SqfliteDatabaseOpenHelper getExistingDatabaseOpenHelper(String path) {
        if (path != null) {
          return databaseOpenHelpers[path];
        } else {
          return nullDatabaseOpenHelper;
        }
      }

      setDatabaseOpenHelper(SqfliteDatabaseOpenHelper helper) {
        var path = helper.options.path;
        if (path == null) {
          nullDatabaseOpenHelper = helper;
        } else {
          if (helper == null) {
            databaseOpenHelpers.remove(path);
          } else {
            databaseOpenHelpers[path] = helper;
          }
        }
      }

      if (options.path != null) {
        options.path = absolute(normalize(options.path));
      }
      var databaseOpenHelper = getExistingDatabaseOpenHelper(options.path);
      if (databaseOpenHelper == null) {
        databaseOpenHelper = new SqfliteDatabaseOpenHelper(this, options);
        setDatabaseOpenHelper(databaseOpenHelper);
      }
      return await databaseOpenHelper.openDatabase();
    } else {
      var databaseOpenHelper = new SqfliteDatabaseOpenHelper(this, options);
      return await databaseOpenHelper.openDatabase();
    }
  }
}
