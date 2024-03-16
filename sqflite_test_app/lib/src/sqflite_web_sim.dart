import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:sqflite/sqflite_dev.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// The Web plugin registration.
///
/// Define a default `DatabaseFactory`
class SqflitePluginWeb {
  /// Registers the default database factory.
  static void registerWith(Registrar registrar) {
    /// Set the default database factory to use.
    /// Currently calling an on-purpose deprecated helper.
    // ignore: invalid_use_of_visible_for_testing_member
    setMockDatabaseFactory(databaseFactoryFfiWeb);
  }
}
