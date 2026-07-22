import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

/// Test runner context
class SqfliteRunnerTestContext extends SqfliteLocalTestContext {
  /// Test runner context
  SqfliteRunnerTestContext()
    : super(databaseFactory: sqfliteDatabaseFactoryFfi);

  @override
  bool get isPlugin {
    return false;
  }

  @override
  bool get supportsRecoveredInTransaction => true;

  /// Only tested on ffi linux for now.
  @override
  bool get supportsUri => true;
}

/// Test runner context
var testContext = SqfliteRunnerTestContext();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var testContext = SqfliteRunnerTestContext();
  var supportDir = await getApplicationSupportDirectory();
  await testContext.databaseFactory.setDatabasesPath(
    join(supportDir.path, 'databases'),
  );
  all.run(testContext);
}
