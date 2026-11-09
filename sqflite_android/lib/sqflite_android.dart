/// Android implementation of the sqflite plugin.
///
/// Apps do not use this library: they depend on `sqflite` (or on
/// `sqflite_common` plus this package) and call `openDatabase()`. Flutter
/// calls [SqfliteAndroid.registerWith] at startup, which sets the global
/// `databaseFactory` to the method channel factory of
/// `sqflite_platform_interface`.
library;

import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

/// sqflite_android plugin, registered by Flutter on Android.
class SqfliteAndroid extends SqflitePlatform {
  /// Main entry point called by the Flutter platform.
  ///
  /// Registers this plugin as the default database factory (if not already set).
  static void registerWith() {
    SqflitePlatform.initWithDatabaseFactoryMethodChannel();
  }
}
