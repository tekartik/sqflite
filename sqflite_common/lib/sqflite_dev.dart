/// To be deprecated
library;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/mixin/import_mixin.dart';
// ignore: deprecated_member_use_from_same_package
export 'package:sqflite_common/src/mixin/import_mixin.dart' show SqfliteOptions;

/// Dev extension
///
/// Please prefer using SqfliteDatabaseFactoryDebug which is exported by default.
extension SqfliteDatabaseFactoryDev on DatabaseFactory {
  /// Change the log level if you want to see the SQL query
  /// executed natively.
  ///
  /// Deprecated for temp usage only
  @Deprecated('Dev only')
  Future<void> setLogLevel(int logLevel) async {
    await setOptions(SqfliteOptions(logLevel: logLevel));
  }

  /// Testing only.
  ///
  /// deprecated on purpose to remove from code.
  @Deprecated('Dev only')
  Future<void> setOptions(SqfliteOptions options) async {
    await (this as SqfliteInvokeHandler).invokeMethod<dynamic>(
      methodOptions,
      options.toMap(),
    );
  }
}
