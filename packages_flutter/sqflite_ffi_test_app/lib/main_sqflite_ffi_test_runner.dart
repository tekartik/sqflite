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

/// The databases go in the application support directory, call before the
/// tests run (also used by integration_test/sqflite_ffi_test.dart).
Future<void> initTestContext() async {
  await testContext.databaseFactory.setDatabasesPath(await appDatabasesPath());
}

/// Runs sqflite_common_test on ffi, results in the console:
///
/// `flutter run -t lib/main_sqflite_ffi_test_runner.dart -d <device id>`
///
/// (tool/run_test_runner.dart picks the device).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initTestContext();
  all.run(testContext);
}
