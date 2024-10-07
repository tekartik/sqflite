import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common/sqflite.dart' as impl;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_platform_interface/src/factory_platform.dart' as impl;

/// sqflite platform interface
class SqflitePlatform extends PlatformInterface {
  /// Constructs a SqflitePlatform.
  SqflitePlatform() : super(token: _token);
  static final _token = Object();

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

  /// Get the database factory or null if not set
  @protected
  static DatabaseFactory? get databaseFactoryOrNull =>
      // ignore: invalid_use_of_visible_for_testing_member
      impl.databaseFactoryOrNull;

  /// Platform specific plugins should set this with their own platform-specific
  @protected
  static set databaseFactoryOrNull(DatabaseFactory? databaseFactory) {
    impl.databaseFactory = databaseFactory;
  }
}
