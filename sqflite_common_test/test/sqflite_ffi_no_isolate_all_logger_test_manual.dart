import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';

var _factory = SqfliteDatabaseFactoryLogger(
  createDatabaseFactoryFfi(noIsolate: true),
  options: SqfliteLoggerOptions(type: SqfliteDatabaseFactoryLoggerType.all),
);

class SqfliteFfiNoIsolateTestContext extends SqfliteLocalTestContext {
  SqfliteFfiNoIsolateTestContext() : super(databaseFactory: _factory);
}

var ffiTestContext = SqfliteFfiNoIsolateTestContext();

Future<void> main() async {
  /// Initialize ffi loader
  sqfliteFfiInit();
  // Add _no_isolate suffix to the path
  var dbsPath = await _factory.getDatabasesPath();
  await _factory.setDatabasesPath('${dbsPath}_all_logger_no_isolate');

  all.run(ffiTestContext);
}
