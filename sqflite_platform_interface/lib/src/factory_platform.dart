import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqflite.dart' as sqflite_common;
// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/platform.dart';

import 'platform_exception.dart' as impl;
import 'sqflite_import.dart';
import 'sqflite_method_channel.dart' as impl;

/// sqflite Default factory
SqfliteDatabaseFactory get sqfliteDatabaseFactory =>
    // ignore: invalid_use_of_visible_for_testing_member
    (sqflite_common.databaseFactoryOrNull ?? databaseFactorySqflitePlugin)
        as SqfliteDatabaseFactory;

final SqfliteDatabaseFactory _databaseFactorySqflitePlugin =
    SqfliteDatabaseFactoryImpl();

/// Default factory that uses the plugin.
sqflite_common.DatabaseFactory get databaseFactorySqflitePlugin =>
    _databaseFactorySqflitePlugin;

/// Default factory that uses the plugin.
final sqfliteDatabaseFactoryDefault = _databaseFactorySqflitePlugin;

/// Change the default factory. test only.
set sqfliteDatabaseFactory(SqfliteDatabaseFactory? databaseFactory) =>
    sqflite_common.databaseFactory = databaseFactory;

/// Factory implementation
class SqfliteDatabaseFactoryImpl with SqfliteDatabaseFactoryMixin {
  /// Only to set for extra debugging
  //static var _debugInternals = devWarning(true);
  static const _debugInternals = false;

  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) =>
      impl.wrapDatabaseException(action);

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) =>
      !_debugInternals
      ? impl.invokeMethod(method, arguments)
      : _invokeMethodWithLog(method, arguments);

  Future<T> _invokeMethodWithLog<T>(String method, [Object? arguments]) async {
    // ignore: avoid_print
    print('-> $method $arguments');
    final result = await impl.invokeMethod<T>(method, arguments);
    // ignore: avoid_print
    print('<- $result');
    return result;
  }

  @override
  Future<Uint8List> readDatabaseBytes(String path) async {
    return await platform.databaseFileSystem.readDatabaseBytes(path);
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async {
    await platform.databaseFileSystem.writeDatabaseBytes(path, bytes);
  }
}
