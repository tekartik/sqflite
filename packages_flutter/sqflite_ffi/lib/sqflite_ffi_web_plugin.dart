import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryOrNull;

import 'src/sqflite_ffi_web.dart';

/// sqflite_ffi web plugin registration.
class SqfliteFfiWeb {
  /// Main entry point called by the flutter web platform.
  ///
  /// Registers [sqfliteDatabaseFactoryFfi] (the default sqflite_common_ffi
  /// web factory) as the default database factory (if not already set).
  static void registerWith(Registrar registrar) {
    databaseFactoryOrNull ??= sqfliteDatabaseFactoryFfi;
  }
}
