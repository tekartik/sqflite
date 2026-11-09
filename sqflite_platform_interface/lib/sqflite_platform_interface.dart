/// Platform interface of the sqflite Flutter plugin, for the platform
/// implementations (sqflite_android, sqflite_darwin...), not for apps (they
/// use `package:sqflite`).
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common/sqflite.dart' as impl;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_platform_interface/src/factory_platform.dart' as impl;

/// sqflite platform interface.
///
/// A platform implementation extends it and, in its static `registerWith()`
/// (the `dartPluginClass` of its pubspec), calls
/// [initWithDatabaseFactoryMethodChannel] when its native side speaks the
/// sqflite method channel protocol:
///
/// ```dart
/// class SqfliteMyOs extends SqflitePlatform {
///   static void registerWith() {
///     SqflitePlatform.initWithDatabaseFactoryMethodChannel();
///   }
/// }
/// ```
class SqflitePlatform extends PlatformInterface {
  /// Constructs a SqflitePlatform.
  SqflitePlatform() : super(token: _token);
  static final _token = Object();

  /// Sets [databaseFactoryMethodChannel] as the global sqflite
  /// `databaseFactory`, unless a factory is already set.
  ///
  /// Called by the `registerWith()` of sqflite_android and sqflite_darwin.
  static void initWithDatabaseFactoryMethodChannel() {
    impl.databaseFactoryOrNull ??= SqflitePlatform.databaseFactoryMethodChannel;
  }

  /// The method channel database factory (channel `com.tekartik.sqflite`).
  ///
  /// The sqflite Dart logic runs in Dart, the SQL is sent to the native side.
  /// `readDatabaseBytes` and `writeDatabaseBytes` use the file system
  /// directly (`dart:io`).
  static DatabaseFactory get databaseFactoryMethodChannel =>
      impl.sqfliteDatabaseFactoryDefault;

  /// The global sqflite `databaseFactory` (throws a `StateError` if not set).
  DatabaseFactory get databaseFactory => impl.databaseFactory;

  /// Replaces the global sqflite `databaseFactory` (a warning is printed if
  /// one was set). It must be built with the sqflite_common helpers
  /// (`buildDatabaseFactory`), otherwise an `ArgumentError` is thrown.
  set databaseFactory(DatabaseFactory databaseFactory) {
    impl.databaseFactory = databaseFactory;
  }
}
