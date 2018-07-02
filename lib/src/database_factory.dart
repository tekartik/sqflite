import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/exception.dart';
import 'package:synchronized/synchronized.dart';
import 'sqflite_impl.dart' as impl;

SqfliteDatabaseFactory _databaseFactory;

DatabaseFactory get databaseFactory => sqlfliteDatabaseFactory;

SqfliteDatabaseFactory get sqlfliteDatabaseFactory =>
    _databaseFactory ??= new SqfliteDatabaseFactory();

Future<Database> openReadOnlyDatabase(String path) async {
  var options = new SqfliteOpenDatabaseOptions(readOnly: true);
  return sqlfliteDatabaseFactory.openDatabase(path, options: options);
}

abstract class DatabaseFactory {
  Future<Database> openDatabase(String path, {OpenDatabaseOptions options});
  Future<String> getDatabasesPath();
  Future deleteDatabase(String path);
}

///
/// Options to open a database
/// See [openDatabase] for details
///
class SqfliteOpenDatabaseOptions implements OpenDatabaseOptions {
  SqfliteOpenDatabaseOptions({
    this.version,
    this.onConfigure,
    this.onCreate,
    this.onUpgrade,
    this.onDowngrade,
    this.onOpen,
    this.readOnly = false,
    this.singleInstance = true,
  }) {
    readOnly ??= false;
    singleInstance ??= true;
  }
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

  // to allow mock overriding
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      impl.invokeMethod(method, arguments);

  // open lock mechanism
  var lock = new Lock();

  SqfliteDatabase newDatabase(
          SqfliteDatabaseOpenHelper openHelper, String path) =>
      new SqfliteDatabase(openHelper, path);

  // internal close
  void doCloseDatabase(SqfliteDatabase database) {
    if (database?.options?.singleInstance == true) {
      _removeDatabaseOpenHelper(database.path);
    }
  }

  void _removeDatabaseOpenHelper(String path) {
    if (path == null) {
      nullDatabaseOpenHelper = null;
    } else {
      databaseOpenHelpers.remove(path);
    }
  }

  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions options}) async {
    options ??= new SqfliteOpenDatabaseOptions();

    if (options?.singleInstance == true) {
      SqfliteDatabaseOpenHelper getExistingDatabaseOpenHelper(String path) {
        if (path != null) {
          return databaseOpenHelpers[path];
        } else {
          return nullDatabaseOpenHelper;
        }
      }

      void setDatabaseOpenHelper(SqfliteDatabaseOpenHelper helper) {
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

      if (path != null && path != inMemoryDatabasePath) {
        path = absolute(normalize(path));
      }
      var databaseOpenHelper = getExistingDatabaseOpenHelper(path);

      bool firstOpen = databaseOpenHelper == null;
      if (firstOpen) {
        databaseOpenHelper = new SqfliteDatabaseOpenHelper(this, path, options);
        setDatabaseOpenHelper(databaseOpenHelper);
      }
      try {
        return await databaseOpenHelper.openDatabase();
      } catch (e) {
        // If first open fail remove the reference
        if (firstOpen) {
          _removeDatabaseOpenHelper(path);
        }
        rethrow;
      }
    } else {
      var databaseOpenHelper =
          new SqfliteDatabaseOpenHelper(this, path, options);
      return await databaseOpenHelper.openDatabase();
    }
  }

  @override
  Future deleteDatabase(String path) async {
    try {
      await new File(path).delete(recursive: true);
    } catch (_e) {
      // 0.8.4
      // print(e);
    }
  }

  @override
  Future<String> getDatabasesPath() async {
    var path = await wrapDatabaseException<String>(() {
      return invokeMethod<String>(methodGetDatabasesPath);
    });
    if (path == null) {
      throw new SqfliteDatabaseException("getDatabasesPath is null", null);
    }
    return path;
  }
}
