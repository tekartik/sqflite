import 'package:sqflite_darwin/src/sqflite_darwin_factory.dart';

import 'sqflite_darwin_method_channel.dart';

import 'package:sqflite_common/sqflite.dart';

/// sqflite Plugin registration.
class SqfliteDarwinPlugin {
  /// Registers this plugin as the default database factory (if not already set).
  static void registerWith() {
    databaseFactoryOrNull ??= databaseFactorySqfliteDarwinPlugin;
  }
}

/// Invoke a native method
Future<T> invokeMethod<T>(String method, [Object? arguments]) async =>
    await sqfliteDarwinMethodChannel.invokeMethod<T>(method, arguments) as T;

void initSqfliteDarwinPlugin() {
  databaseFactoryOrNull = databaseFactorySqfliteDarwinPlugin;
}
