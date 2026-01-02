import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/src/sw/constants.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite.dart';

import 'import.dart';

export 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';

/// Extension methods for [DatabaseFactory] to get and set web options.
extension DatabaseFactoryFfiWebExtension on DatabaseFactory {
  SqfliteDatabaseFactoryMixin get _this => this as SqfliteDatabaseFactoryMixin;

  /// Get the web options.
  Future<SqfliteFfiWebOptions> getWebOptions() async {
    var result = await _this.invokeMethod<Map>(methodGetWebOptions);
    return sqfliteFfiWebOptionsFromMap(result);
  }

  /// Set the web options.
  Future<void> setWebOptions(SqfliteFfiWebOptions options) async {
    await _this.invokeMethod<void>(methodSetWebOptions, options.toMap());
  }
}
