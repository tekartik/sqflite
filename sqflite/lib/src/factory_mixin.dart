import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/database_mixin.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/factory.dart';
import 'package:sqflite/src/mixin/factory.dart';
import 'package:sqflite/src/open_options.dart';
import 'package:synchronized/synchronized.dart';

/// Base factory implementation
abstract class SqfliteDatabaseFactoryBase with SqfliteDatabaseFactoryMixin {}

/// Common factory mixin
mixin SqfliteDatabaseFactoryMixin
    implements SqfliteDatabaseFactory, SqfliteInvokeHandler {
  /// To override to wrap wanted exception
  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) => action();

  Future<T> safeInvokeMethod<T>(String method, [dynamic arguments]) =>
      wrapDatabaseException(() => invokeMethod(method, arguments));

  /// Open helpers for single instances only.
  Map<String, SqfliteDatabaseOpenHelper> databaseOpenHelpers =
      <String, SqfliteDatabaseOpenHelper>{};

  /// Helper for null path database.
  SqfliteDatabaseOpenHelper nullDatabaseOpenHelper;

  // open lock mechanism
  @override
  final Lock lock = Lock(reentrant: true);

  @override
  @override
  SqfliteDatabase newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path) {
    return SqfliteDatabaseBase(openHelper, path);
  }

  @override
  void removeDatabaseOpenHelper(String path) {
    if (path == null) {
      nullDatabaseOpenHelper = null;
    } else {
      databaseOpenHelpers.remove(path);
    }
  }

  // Close an instance of the database
  @override
  Future<void> closeDatabase(SqfliteDatabase database) {
    // Global factory lock during close
    return lock.synchronized(() async {
      await (database as SqfliteDatabaseMixin)
          .openHelper
          .closeDatabase(database);
      if (database?.options?.singleInstance != false) {
        removeDatabaseOpenHelper(database.path);
      }
    });
  }

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions options}) {
    // Global factory lock during open
    return lock.synchronized(() async {
      path = await fixPath(path);
      options ??= SqfliteOpenDatabaseOptions();

      if (options?.singleInstance != false) {
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
    });
  }

  @override
  Future<void> deleteDatabase(String path) async {
    return lock.synchronized(() async {
      path = await fixPath(path);
      // Handle already single instance open database
      removeDatabaseOpenHelper(path);
      return safeInvokeMethod<void>(
          methodDeleteDatabase, <String, dynamic>{paramPath: path});
    });
  }

  @override
  Future<bool> databaseExists(String path) async {
    path = await fixPath(path);
    return safeInvokeMethod<bool>(
        methodDatabaseExists, <String, dynamic>{paramPath: path});
  }

  String _databasesPath;

  @override
  Future<String> getDatabasesPath() async {
    if (_databasesPath == null) {
      final String path =
          await safeInvokeMethod<String>(methodGetDatabasesPath);

      if (path == null) {
        throw SqfliteDatabaseException('getDatabasesPath is null', null);
      }
      _databasesPath = path;
    }
    return _databasesPath;
  }

  /// path must be non null
  Future<String> fixPath(String path) async {
    assert(path != null, 'path cannot be null');
    if (path == inMemoryDatabasePath) {
      // nothing
    } else {
      if (isRelative(path)) {
        path = join(await getDatabasesPath(), path);
      }
      path = absolute(normalize(path));
    }
    return path;
  }

  /// True if it is a real path
  bool isPath(String path) {
    return (path != null) && (path != inMemoryDatabasePath);
  }

  Future<SqfliteDebugInfo> getDebugInfo() async {
    final SqfliteDebugInfo info = SqfliteDebugInfo();
    final dynamic map =
        await safeInvokeMethod(methodDebug, <String, dynamic>{'cmd': 'get'});
    final dynamic databasesMap = map[paramDatabases];
    if (databasesMap is Map) {
      info.databases = databasesMap.map((dynamic id, dynamic info) {
        final SqfliteDatabaseDebugInfo dbInfo = SqfliteDatabaseDebugInfo();
        final String databaseId = id?.toString();

        if (info is Map) {
          dbInfo?.fromMap(info);
        }
        return MapEntry<String, SqfliteDatabaseDebugInfo>(databaseId, dbInfo);
      });
    }
    info.logLevel = map[paramLogLevel] as int;
    return info;
  }
}

// When opening the database (bool)
/// Native parameter (int)
const String paramLogLevel = 'logLevel';

/// Native parameter
const String paramDatabases = 'databases';

/// Debug information
class SqfliteDatabaseDebugInfo {
  /// Database path
  String path;

  /// Whether the database was open as a single instance
  bool singleInstance;

  /// Log level
  int logLevel;

  /// Deserializer
  void fromMap(Map<dynamic, dynamic> map) {
    path = map[paramPath]?.toString();
    singleInstance = map[paramSingleInstance] as bool;
    logLevel = map[paramLogLevel] as int;
  }

  /// Debug formatting helper
  Map<String, dynamic> toDebugMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      paramPath: path,
      paramSingleInstance: singleInstance
    };
    if ((logLevel ?? sqfliteLogLevelNone) > sqfliteLogLevelNone) {
      map[paramLogLevel] = logLevel;
    }
    return map;
  }

  @override
  String toString() => toDebugMap().toString();
}

/// Internal debug info
class SqfliteDebugInfo {
  /// List of databases
  Map<String, SqfliteDatabaseDebugInfo> databases;

  /// global log level (set for new opened databases)
  int logLevel;

  /// Debug formatting helper
  Map<String, dynamic> toDebugMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (databases != null) {
      map[paramDatabases] = databases.map(
          (String key, SqfliteDatabaseDebugInfo dbInfo) =>
              MapEntry<String, Map<String, dynamic>>(key, dbInfo.toDebugMap()));
    }
    if ((logLevel ?? sqfliteLogLevelNone) > sqfliteLogLevelNone) {
      map[paramLogLevel] = logLevel;
    }
    return map;
  }

  @override
  String toString() => toDebugMap().toString();
}
