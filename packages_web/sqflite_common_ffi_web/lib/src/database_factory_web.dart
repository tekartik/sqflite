import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart';

import 'import.dart';

/// The Ffi database factory.
var databaseFactoryFfiWebNoWebWorkerImpl = () {
  sqfliteFfiHandler = SqfliteFfiHandlerWeb();
  return createDatabaseFactoryFfiImpl(noIsolate: true);
}();
