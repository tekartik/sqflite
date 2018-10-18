import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/utils.dart';
import 'package:synchronized/synchronized.dart';
import 'package:sqflite/src/sqflite_impl.dart' as impl;

SqfliteDatabaseFactory _databaseFactory;

DatabaseFactory get databaseFactory => sqlfliteDatabaseFactory;

SqfliteDatabaseFactory get sqlfliteDatabaseFactory =>
    _databaseFactory ??= SqfliteDatabaseFactory();

Future<Database> openReadOnlyDatabase(String path) async {
  final SqfliteOpenDatabaseOptions options =
      SqfliteOpenDatabaseOptions(readOnly: true);
  return sqlfliteDatabaseFactory.openDatabase(path, options: options);
}

/// Basic databases operations
abstract class DatabaseFactory {
  /// Open a database at [path] with the given [options]
  Future<Database> openDatabase(String path, {OpenDatabaseOptions options});

  /// Get the default databases location path
  Future<String> getDatabasesPath();

  /// Delete a database if it exists
  Future<void> deleteDatabase(String path);
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

  @override
  String toString() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (version != null) {
      map['version'] = version;
    }
    map['readOnly'] = readOnly;
    map['singleInstance'] = singleInstance;
    return map.toString();
  }
}

class SqfliteDatabaseFactory implements DatabaseFactory {
  // for single instances only
  Map<String, SqfliteDatabaseOpenHelper> databaseOpenHelpers =
      <String, SqfliteDatabaseOpenHelper>{};
  SqfliteDatabaseOpenHelper nullDatabaseOpenHelper;

  // to allow mock overriding
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      impl.invokeMethod(method, arguments);

  // open lock mechanism
  final Lock lock = Lock();

  SqfliteDatabase newDatabase(
          SqfliteDatabaseOpenHelper openHelper, String path) =>
      SqfliteDatabase(openHelper, path);

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
    options ??= SqfliteOpenDatabaseOptions();

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

      if (path != null) {
        path = await fixPath(path);
      }
      SqfliteDatabaseOpenHelper databaseOpenHelper =
          getExistingDatabaseOpenHelper(path);

      final bool firstOpen = databaseOpenHelper == null;
      if (firstOpen) {
        databaseOpenHelper = SqfliteDatabaseOpenHelper(this, path, options);
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
      final SqfliteDatabaseOpenHelper databaseOpenHelper =
          SqfliteDatabaseOpenHelper(this, path, options);
      return await databaseOpenHelper.openDatabase();
    }
  }

  @override
  Future<void> deleteDatabase(String path) async {
    try {
      await File(path).delete(recursive: true);
    } catch (_e) {
      // 0.8.4
      // print(e);
    }
  }

  String _databasesPath;

  @override
  Future<String> getDatabasesPath() async {
    if (_databasesPath == null) {
      final String path = await wrapDatabaseException<String>(() {
        return invokeMethod<String>(methodGetDatabasesPath);
      });
      if (path == null) {
        throw SqfliteDatabaseException("getDatabasesPath is null", null);
      }
      _databasesPath = path;
    }
    return _databasesPath;
  }

  Future<void> createParentDirectory(String path) async {
    // needed on iOS
    if (Platform.isIOS) {
      path = await fixPath(path);
      if (isPath(path)) {
        try {
          path = dirname(path);
          // devPrint('createParentDirectory: $path');
          await Directory(path).create(recursive: true);
        } catch (_) {}
      }
    }
  }

  Future<String> fixPath(String path) async {
    if (path == null) {
      path = await getDatabasesPath();
    } else if (path == inMemoryDatabasePath) {
      // nothing
    } else {
      if (isRelative(path)) {
        path = join(await getDatabasesPath(), path);
      }
      path = absolute(normalize(path));
    }
    return path;
  }

  bool isPath(String path) {
    return (path != null) && (path != inMemoryDatabasePath);
  }
}
