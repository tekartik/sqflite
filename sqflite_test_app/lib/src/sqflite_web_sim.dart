import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:sqflite/sqflite_dev.dart';

import 'database_factory_web.dart';

/// The Web plugin registration.
///
/// Define a default `DatabaseFactory`
class SqflitePluginWeb {
  /// Registers the default database factory.
  static void registerWith(Registrar registrar) {
    /// Set the default database factory to use.
    /// Currently calling an on-purpose deprecated helper.
    // ignore: invalid_use_of_visible_for_testing_member
    setMockDatabaseFactory(databaseFactoryWeb);
  }
}
