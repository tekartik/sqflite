import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common/sqflite.dart' as impl;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_platform_interface/src/factory_platform.dart' as impl;

/// sqflite platform interface
class SqflitePlatform extends PlatformInterface {
  /// Constructs a SqflitePlatform.
  SqflitePlatform() : super(token: _token);
  static final _token = Object();

  /// Main entry point called by the Flutter platform.
  /// Should be called by iOS/MacOS/Android registerWith method.
  static void initWithDatabaseFactoryMethodChannel() {
    impl.databaseFactoryOrNull ??= SqflitePlatform.databaseFactoryMethodChannel;
  }

  /// Method channel database factory.
  /// Set this factory during register for sqflite_android and sqflite_darwin
  static DatabaseFactory get databaseFactoryMethodChannel =>
      impl.sqfliteDatabaseFactoryDefault;

  /// Get the database factory
  DatabaseFactory get databaseFactory => impl.databaseFactory;

  /// Platform specific plugins should set this with their own platform-specific
  set databaseFactory(DatabaseFactory databaseFactory) {
    impl.databaseFactory = databaseFactory;
  }
}
