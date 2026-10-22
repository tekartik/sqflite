import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';
import 'package:sqflite_ffi_test_app/databases_path.dart';

/// Test runner context
class SqfliteRunnerTestContext extends SqfliteLocalTestContext {
  /// Test runner context
  SqfliteRunnerTestContext()
    : super(databaseFactory: sqfliteDatabaseFactoryFfi);

  @override
  bool get isPlugin {
    return false;
  }

  /// Only tested on ffi linux for now.
  @override
  bool get supportsUri => true;
}

/// Test runner context
var testContext = SqfliteRunnerTestContext();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var testContext = SqfliteRunnerTestContext();
  await testContext.databaseFactory.setDatabasesPath(await appDatabasesPath());
  all.run(testContext);
}
