import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/compat.dart';
import 'package:sqflite_common/src/mixin/constant.dart';
import 'package:sqflite_common/src/mixin/factory.dart';

/// Dev extension
extension SqfliteDatabaseFactoryDev on DatabaseFactory {
  /// Turns on debug mode if you want to see the SQL query
  /// executed natively.
  ///
  /// Deprecated for temp usage only
  @deprecated
  Future<void> setLogLevel(int logLevel) async {
    await setOptions(SqfliteOptions(logLevel: logLevel ?? sqfliteLogLevelNone));
  }

  /// Testing only.
  ///
  /// deprecated on purpose to remove from code.
  @deprecated
  Future<void> setOptions(SqfliteOptions options) async {
    await (this as SqfliteInvokeHandler)
        .invokeMethod<dynamic>(methodOptions, options.toMap());
  }
}
