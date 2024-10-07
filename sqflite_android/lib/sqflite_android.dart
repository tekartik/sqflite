import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

/// sqflite_darwin plugin
class SqfliteAndroid extends SqflitePlatform {
  /// Main entry point called by the Flutter platform.
  ///
  /// Registers this plugin as the default database factory (if not already set).
  static void registerWith() {
    SqflitePlatform.initWithDatabaseFactoryMethodChannel();
  }
}
