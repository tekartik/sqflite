import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/exception_impl.dart' as impl;
import 'package:sqflite/src/factory.dart';
import 'package:sqflite/src/factory_mixin.dart';
import 'package:sqflite/src/sqflite_impl.dart' as impl;

export 'package:sqflite/src/open_options.dart';

SqfliteDatabaseFactory _databaseFactory;

/// Default factory
DatabaseFactory get databaseFactory => sqlfliteDatabaseFactory;

/// Default factory
SqfliteDatabaseFactory get sqlfliteDatabaseFactory =>
    _databaseFactory ??= SqfliteDatabaseFactoryImpl();

/// Factory implementation
class SqfliteDatabaseFactoryImpl with SqfliteDatabaseFactoryMixin {
  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) =>
      impl.wrapDatabaseException(action);

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      impl.invokeMethod(method, arguments);

  /*
  /// Old implementation which does not handle hot-restart and Android restart
  @override
  Future<void> deleteDatabase(String path) async {
    path = await fixPath(path);

      try {
        await File(path).delete(recursive: true);
      } catch (_) {
        // 0.8.4
        // print(_);
      }
  }
  */

  /// Optimized but could be removed
  @override
  Future<bool> databaseExists(String path) async {
    path = await fixPath(path);
    try {
      // avoid slow async method
      return File(path).existsSync();
    } catch (_) {}
    return false;
  }
}
