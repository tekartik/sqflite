import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/database_mixin.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/factory.dart';
import 'package:sqflite/src/open_options.dart';
import 'package:synchronized/synchronized.dart';

abstract class SqfliteDatabaseFactoryBase with SqfliteDatabaseFactoryMixin {}

mixin SqfliteDatabaseFactoryMixin implements SqfliteDatabaseFactory {
  /// To override to wrap wanted exception
  @override
  Future<T> wrapDatabaseException<T>(Future<T> action()) => action();

  Future<T> safeInvokeMethod<T>(String method, [dynamic arguments]) =>
      wrapDatabaseException(() => invokeMethod(method, arguments));

  // for single instances only
  Map<String, SqfliteDatabaseOpenHelper> databaseOpenHelpers =
      <String, SqfliteDatabaseOpenHelper>{};
  SqfliteDatabaseOpenHelper nullDatabaseOpenHelper;

  // open lock mechanism
  @override
  final Lock lock = Lock();

  @override
  @override
  SqfliteDatabase newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path) {
    return SqfliteDatabaseBase(openHelper, path);
  }

  // internal close
  @override
  void doCloseDatabase(SqfliteDatabase database) {
    if (database?.options?.singleInstance == true) {
      removeDatabaseOpenHelper(database.path);
    }
  }

  @override
  void removeDatabaseOpenHelper(String path) {
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
          removeDatabaseOpenHelper(path);
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
    return safeInvokeMethod<bool>(methodDeleteDatabase);
  }

  @override
  Future<bool> databaseExists(String path) async {
    return safeInvokeMethod<bool>(methodDatabaseExists);
  }

  String _databasesPath;

  @override
  Future<String> getDatabasesPath() async {
    if (_databasesPath == null) {
      final String path =
          await safeInvokeMethod<String>(methodGetDatabasesPath);

      if (path == null) {
        throw SqfliteDatabaseException("getDatabasesPath is null", null);
      }
      _databasesPath = path;
    }
    return _databasesPath;
  }

  @override
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
